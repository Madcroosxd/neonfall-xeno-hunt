import { ensureLeaderboardSchema, errorResponse, parseProgressPayload, recordProgress } from "../../_lib/leaderboard";

export async function POST(request: Request) {
  try {
    await ensureLeaderboardSchema();
    const body = await request.json() as Record<string, unknown>;
    return Response.json(await recordProgress(parseProgressPayload(body), false));
  } catch (error) {
    return errorResponse(error);
  }
}
