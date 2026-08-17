import { ensureLeaderboardSchema, errorResponse } from "../_lib/leaderboard";
import { env } from "cloudflare:workers";

export async function GET() {
  try {
    await ensureLeaderboardSchema();
    const result = await env.DB.prepare(`SELECT username, best_score AS score, best_wave AS wave,
      best_kills AS kills, updated_at AS updatedAt FROM players
      WHERE best_score > 0 ORDER BY best_score DESC, best_wave DESC, updated_at ASC LIMIT 20`).all();
    return Response.json({ entries: result.results }, { headers: { "Cache-Control": "no-store" } });
  } catch (error) {
    return errorResponse(error);
  }
}
