import { env } from "cloudflare:workers";
import {
  ApiError,
  ensureLeaderboardSchema,
  errorResponse,
  normalizeUsername,
  parseDeviceId,
  requestIpHash,
  sha256,
} from "../../_lib/leaderboard";

type PlayerRow = { id: string; username: string; device_hash: string };

export async function POST(request: Request) {
  try {
    await ensureLeaderboardSchema();
    const body = await request.json() as Record<string, unknown>;
    const { username, usernameKey } = normalizeUsername(body.username);
    const deviceId = parseDeviceId(body.deviceId);
    const deviceHash = await sha256(`neonfall-device-v1:${deviceId}`);
    const ipHash = await requestIpHash(request);
    const now = Math.floor(Date.now() / 1000);

    const recent = await env.DB.prepare("SELECT COUNT(*) AS count FROM runs WHERE ip_hash = ? AND created_at > ?")
      .bind(ipHash, now - 60).first<{ count: number }>();
    if ((recent?.count || 0) >= 5) throw new ApiError(429, "Çok fazla yeni koşu başlatıldı. Bir dakika bekle.");

    let player = await env.DB.prepare("SELECT id, username, device_hash FROM players WHERE username_key = ?")
      .bind(usernameKey).first<PlayerRow>();
    if (player && player.device_hash !== deviceHash) throw new ApiError(409, "Bu kullanıcı adı başka bir oyuncuya ait.");

    if (!player) {
      const playerId = crypto.randomUUID();
      await env.DB.prepare(`INSERT INTO players
        (id, username, username_key, device_hash, best_score, best_wave, best_kills, created_at, updated_at)
        VALUES (?, ?, ?, ?, 0, 0, 0, ?, ?)`)
        .bind(playerId, username, usernameKey, deviceHash, now, now).run();
      player = { id: playerId, username, device_hash: deviceHash };
    }

    const runId = crypto.randomUUID();
    const runSecret = `${crypto.randomUUID()}.${crypto.randomUUID()}`;
    await env.DB.prepare(`INSERT INTO runs
      (id, secret_hash, player_id, ip_hash, created_at, last_seen_at, verified_score, verified_wave, verified_kills, rejected_events)
      VALUES (?, ?, ?, ?, ?, ?, 0, 1, 0, 0)`)
      .bind(runId, await sha256(runSecret), player.id, ipHash, now, now).run();

    return Response.json({ runId, runSecret, username: player.username });
  } catch (error) {
    return errorResponse(error);
  }
}
