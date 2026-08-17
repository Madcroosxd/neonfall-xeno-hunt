import { env } from "cloudflare:workers";

const USERNAME_PATTERN = /^[A-Za-z0-9_]{3,16}$/;
const RUN_MAX_AGE_SECONDS = 4 * 60 * 60;

export class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export type ProgressPayload = {
  runId: string;
  runSecret: string;
  score: number;
  wave: number;
  kills: number;
  elapsed: number;
};

type RunRow = {
  id: string;
  secret_hash: string;
  player_id: string;
  created_at: number;
  last_seen_at: number;
  finished_at: number | null;
  verified_score: number;
  verified_wave: number;
  verified_kills: number;
};

function database() {
  if (!env.DB) throw new ApiError(503, "Skor servisi şu anda kullanılamıyor.");
  return env.DB;
}

export async function ensureLeaderboardSchema() {
  const db = database();
  await db.batch([
    db.prepare(`CREATE TABLE IF NOT EXISTS players (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      username_key TEXT NOT NULL UNIQUE,
      device_hash TEXT NOT NULL,
      best_score INTEGER NOT NULL DEFAULT 0,
      best_wave INTEGER NOT NULL DEFAULT 0,
      best_kills INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )`),
    db.prepare("CREATE INDEX IF NOT EXISTS players_best_score_idx ON players(best_score DESC)"),
    db.prepare(`CREATE TABLE IF NOT EXISTS runs (
      id TEXT PRIMARY KEY,
      secret_hash TEXT NOT NULL,
      player_id TEXT NOT NULL,
      ip_hash TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      last_seen_at INTEGER NOT NULL,
      finished_at INTEGER,
      verified_score INTEGER NOT NULL DEFAULT 0,
      verified_wave INTEGER NOT NULL DEFAULT 1,
      verified_kills INTEGER NOT NULL DEFAULT 0,
      rejected_events INTEGER NOT NULL DEFAULT 0
    )`),
    db.prepare("CREATE INDEX IF NOT EXISTS runs_player_idx ON runs(player_id)"),
    db.prepare("CREATE INDEX IF NOT EXISTS runs_ip_created_idx ON runs(ip_hash, created_at)"),
  ]);
}

export function normalizeUsername(value: unknown) {
  const username = typeof value === "string" ? value.trim() : "";
  if (!USERNAME_PATTERN.test(username)) {
    throw new ApiError(400, "Kullanıcı adı 3-16 karakter olmalı; yalnızca harf, sayı ve _ kullanılabilir.");
  }
  return { username, usernameKey: username.toLowerCase() };
}

export function parseDeviceId(value: unknown) {
  if (typeof value !== "string" || value.length < 16 || value.length > 100) {
    throw new ApiError(400, "Geçersiz oyuncu kimliği.");
  }
  return value;
}

export async function sha256(value: string) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

export async function requestIpHash(request: Request) {
  const forwarded = request.headers.get("cf-connecting-ip") || request.headers.get("x-forwarded-for") || "local-preview";
  return sha256(`neonfall-ip-v1:${forwarded.split(",")[0].trim()}`);
}

function safeInteger(value: unknown, max: number) {
  if (typeof value !== "number" || !Number.isFinite(value)) return -1;
  const integer = Math.floor(value);
  return integer >= 0 && integer <= max ? integer : -1;
}

export function parseProgressPayload(body: Record<string, unknown>): ProgressPayload {
  const runId = typeof body.runId === "string" ? body.runId : "";
  const runSecret = typeof body.runSecret === "string" ? body.runSecret : "";
  const score = safeInteger(body.score, 500_000_000);
  const wave = safeInteger(body.wave, 999);
  const kills = safeInteger(body.kills, 1_000_000);
  const elapsed = safeInteger(body.elapsed, RUN_MAX_AGE_SECONDS);
  if (!runId || runSecret.length < 32 || score < 0 || wave < 1 || kills < 0 || elapsed < 0) {
    throw new ApiError(400, "Geçersiz koşu verisi.");
  }
  return { runId, runSecret, score, wave, kills, elapsed };
}

export async function recordProgress(payload: ProgressPayload, finish: boolean) {
  const db = database();
  const run = await db.prepare(`SELECT id, secret_hash, player_id, created_at, last_seen_at, finished_at,
      verified_score, verified_wave, verified_kills FROM runs WHERE id = ?`)
    .bind(payload.runId).first<RunRow>();
  if (!run || (await sha256(payload.runSecret)) !== run.secret_hash) {
    throw new ApiError(404, "Koşu bulunamadı.");
  }
  if (run.finished_at) throw new ApiError(409, "Bu koşu daha önce tamamlandı.");

  const now = Math.floor(Date.now() / 1000);
  const serverElapsed = Math.max(0, now - run.created_at);
  if (serverElapsed > RUN_MAX_AGE_SECONDS) throw new ApiError(410, "Koşunun süresi doldu.");

  const maxKills = Math.floor(serverElapsed * 3) + 25;
  const maxWave = Math.floor(serverElapsed / 12) + 2;
  const maxScore = Math.floor(serverElapsed * (1500 + Math.min(serverElapsed, 1800) * 20)) + 75_000;
  const impossible = payload.kills > maxKills || payload.wave > maxWave || payload.score > maxScore || payload.elapsed > serverElapsed + 25;

  if (impossible) {
    await db.prepare("UPDATE runs SET rejected_events = rejected_events + 1, last_seen_at = ? WHERE id = ?")
      .bind(now, run.id).run();
    throw new ApiError(422, "Skor doğrulama kurallarını geçemedi.");
  }
  if (payload.score < run.verified_score || payload.wave < run.verified_wave || payload.kills < run.verified_kills) {
    throw new ApiError(409, "Koşu değerleri geriye gidemez.");
  }

  const secondsSinceSync = Math.max(1, now - run.last_seen_at);
  const maxScoreDelta = secondsSinceSync * (28_000 + payload.wave * 700) + 90_000;
  if (payload.score - run.verified_score > maxScoreDelta) {
    await db.prepare("UPDATE runs SET rejected_events = rejected_events + 1, last_seen_at = ? WHERE id = ?")
      .bind(now, run.id).run();
    throw new ApiError(422, "Olağan dışı skor artışı engellendi.");
  }

  await db.prepare(`UPDATE runs SET verified_score = ?, verified_wave = ?, verified_kills = ?,
      last_seen_at = ?, finished_at = ? WHERE id = ? AND finished_at IS NULL`)
    .bind(payload.score, payload.wave, payload.kills, now, finish ? now : null, run.id).run();

  if (finish) {
    await db.prepare(`UPDATE players SET
      best_score = MAX(best_score, ?),
      best_wave = MAX(best_wave, ?),
      best_kills = MAX(best_kills, ?),
      updated_at = ? WHERE id = ?`)
      .bind(payload.score, payload.wave, payload.kills, now, run.player_id).run();
  }

  return { verifiedScore: payload.score, verifiedWave: payload.wave, verifiedKills: payload.kills };
}

export function errorResponse(error: unknown) {
  if (error instanceof ApiError) return Response.json({ error: error.message }, { status: error.status });
  console.error(error);
  return Response.json({ error: "Skor servisi hatası." }, { status: 500 });
}
