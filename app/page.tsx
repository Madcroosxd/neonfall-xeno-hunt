"use client";

import { FormEvent, useCallback, useEffect, useRef, useState } from "react";

type LeaderboardEntry = { username: string; score: number; wave: number; kills: number; updatedAt: number };
type RunSession = { runId: string; runSecret: string; username: string };
const formatScore = (score: number) => new Intl.NumberFormat("tr-TR").format(score || 0);
const createClientToken = () => {
  if (typeof window.crypto.randomUUID === "function") return window.crypto.randomUUID();
  const bytes = new Uint8Array(16);
  window.crypto.getRandomValues(bytes);
  return Array.from(bytes, (value) => value.toString(16).padStart(2, "0")).join("");
};

export default function Home() {
  const [username, setUsername] = useState("");
  const [deviceId, setDeviceId] = useState("");
  const [entries, setEntries] = useState<LeaderboardEntry[]>([]);
  const [run, setRun] = useState<RunSession | null>(null);
  const [phase, setPhase] = useState<"gate" | "loading" | "playing">("gate");
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState("");
  const [scoreboardOpen, setScoreboardOpen] = useState(true);
  const iframeRef = useRef<HTMLIFrameElement>(null);

  const refreshLeaderboard = useCallback(async () => {
    try {
      const response = await fetch("/api/leaderboard", { cache: "no-store" });
      const data = await response.json() as { entries?: LeaderboardEntry[] };
      if (response.ok) setEntries(data.entries || []);
    } catch {
      // A temporary leaderboard outage must not prevent local gameplay.
    }
  }, []);

  useEffect(() => {
    const initializeTimer = window.setTimeout(() => {
      const storedName = localStorage.getItem("neonfall.username") || "";
      let storedDevice = localStorage.getItem("neonfall.device");
      if (!storedDevice) {
        storedDevice = `${createClientToken()}.${createClientToken()}`;
        localStorage.setItem("neonfall.device", storedDevice);
      }
      setUsername(storedName);
      setDeviceId(storedDevice);
    }, 0);
    const refreshTimer = window.setTimeout(refreshLeaderboard, 0);
    const timer = window.setInterval(refreshLeaderboard, 10_000);
    return () => {
      window.clearTimeout(initializeTimer);
      window.clearTimeout(refreshTimer);
      window.clearInterval(timer);
    };
  }, [refreshLeaderboard]);

  const beginRun = useCallback(async (requestedUsername: string) => {
    setError("");
    if (!/^[A-Za-z0-9_]{3,16}$/.test(requestedUsername.trim())) {
      setError("3-16 karakter kullan; yalnızca harf, sayı ve _ kullanabilirsin.");
      return;
    }
    try {
      const response = await fetch("/api/run/start", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username: requestedUsername.trim(), deviceId }),
      });
      const data = await response.json() as RunSession & { error?: string };
      if (!response.ok) throw new Error(data.error || "Koşu başlatılamadı.");
      localStorage.setItem("neonfall.username", data.username);
      setUsername(data.username);
      setRun(data);
      setProgress(1);
      setPhase("loading");
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Bağlantı kurulamadı.");
    }
  }, [deviceId]);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      if (event.origin !== window.location.origin || !event.data) return;
      if (event.data.type === "neonfall-progress") setProgress(Math.max(0, Math.min(100, Number(event.data.progress) || 0)));
      if (event.data.type === "neonfall-ready") {
        setProgress(100);
        window.setTimeout(() => setPhase("playing"), 350);
      }
      if (event.data.type === "neonfall-score-verified") {
        refreshLeaderboard();
        setScoreboardOpen(true);
      }
      if (event.data.type === "neonfall-score-rejected") setError("Koşu skoru güvenlik doğrulamasından geçmedi.");
      if (event.data.type === "neonfall-restart") void beginRun(username);
    };
    window.addEventListener("message", onMessage);
    return () => window.removeEventListener("message", onMessage);
  }, [beginRun, refreshLeaderboard, username]);

  const sendSessionToGame = () => {
    if (!run || !iframeRef.current?.contentWindow) return;
    iframeRef.current.contentWindow.postMessage({ type: "neonfall-session", ...run }, window.location.origin);
  };

  const startGame = async (event: FormEvent) => {
    event.preventDefault();
    await beginRun(username);
  };

  return (
    <main className="game-shell">
      <div className="space-field" aria-hidden="true"><i /><i /><i /></div>
      {run && <iframe key={run.runId} ref={iframeRef} className={`game-frame ${phase === "playing" ? "is-visible" : ""}`} src="/godot/index.html" title="NEONFALL: XENO HUNT" allow="fullscreen; autoplay; gamepad" onLoad={sendSessionToGame} />}

      {phase === "gate" && (
        <section className="entry-screen">
          <div className="entry-copy">
            <div className="brand-lockup"><span className="brand-mark">N</span><span>NEONFALL</span></div>
            <p className="eyebrow">MADCROOS // DEEP-SPACE SURVIVAL NETWORK</p>
            <h1>Boşluğa bir isimle gir.</h1>
            <p className="intro">Çağrı adını kaydet, doğrulanmış bir koşu başlat ve filodaki yerini canlı sıralamada al.</p>
            <form onSubmit={startGame} className="pilot-form">
              <label htmlFor="username">PİLOT ÇAĞRI ADI</label>
              <div className="input-row">
                <input id="username" value={username} onChange={(event) => setUsername(event.target.value.replace(/[^A-Za-z0-9_]/g, "").slice(0, 16))} placeholder="MADCROOS" minLength={3} maxLength={16} autoComplete="nickname" spellCheck={false} />
                <button type="submit" disabled={!deviceId}>SİNYALE BAĞLAN <span>→</span></button>
              </div>
              {error && <p className="form-error" role="alert">{error}</p>}
              <p className="security-note"><span>◆</span> Sunucu doğrulamalı skor protokolü aktif</p>
            </form>
          </div>
          <Leaderboard entries={entries} featured />
        </section>
      )}

      {phase === "loading" && (
        <section className="loading-screen" aria-live="polite">
          <div className="orbit-loader"><span className="planet" /><span className="orbit one"><b /></span><span className="orbit two"><b /></span></div>
          <p className="eyebrow">SEKTÖR 07 // SİNYAL KİLİTLENİYOR</p>
          <h2>NEONFALL</h2>
          <p className="loading-copy">{username}, savaş sistemleri ve uzaylı telemetrisi hazırlanıyor.</p>
          <div className="load-track"><span style={{ width: `${Math.max(4, progress)}%` }} /></div>
          <div className="load-meta"><span>GODOT 4.7 WEB CORE</span><strong>%{Math.round(progress)}</strong></div>
        </section>
      )}

      {phase === "playing" && (
        <>
          <div className="pilot-chip"><span className="online-dot" /><small>PİLOT</small><strong>{username}</strong></div>
          <button className="scoreboard-toggle" onClick={() => setScoreboardOpen((open) => !open)} aria-expanded={scoreboardOpen}>⌁ SIRALAMA</button>
          {scoreboardOpen && <Leaderboard entries={entries} onClose={() => setScoreboardOpen(false)} />}
          {error && <button className="game-alert" onClick={() => setError("")}>{error} ×</button>}
        </>
      )}
    </main>
  );
}

function Leaderboard({ entries, featured = false, onClose }: { entries: LeaderboardEntry[]; featured?: boolean; onClose?: () => void }) {
  return (
    <aside className={`leaderboard ${featured ? "featured" : "floating"}`}>
      <header><div><p>CANLI AĞ</p><h2>FİLO SIRALAMASI</h2></div>{onClose && <button onClick={onClose} aria-label="Sıralamayı kapat">×</button>}</header>
      <div className="board-head"><span>#</span><span>PİLOT</span><span>DALGA</span><span>SKOR</span></div>
      <ol>
        {entries.length === 0 && <li className="empty-board">İlk doğrulanmış koşuyu sen tamamla.</li>}
        {entries.slice(0, featured ? 10 : 8).map((entry, index) => (
          <li key={entry.username} className={index < 3 ? `rank-${index + 1}` : ""}><span className="rank">{String(index + 1).padStart(2, "0")}</span><strong>{entry.username}</strong><span>W{entry.wave}</span><b>{formatScore(entry.score)}</b></li>
        ))}
      </ol>
      <footer><span>● 10 sn canlı yenileme</span><span>Sunucu doğrulamalı</span></footer>
    </aside>
  );
}
