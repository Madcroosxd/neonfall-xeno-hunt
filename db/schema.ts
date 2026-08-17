import { index, integer, sqliteTable, text, uniqueIndex } from "drizzle-orm/sqlite-core";

export const players = sqliteTable(
  "players",
  {
    id: text("id").primaryKey(),
    username: text("username").notNull(),
    usernameKey: text("username_key").notNull(),
    deviceHash: text("device_hash").notNull(),
    bestScore: integer("best_score").notNull().default(0),
    bestWave: integer("best_wave").notNull().default(0),
    bestKills: integer("best_kills").notNull().default(0),
    createdAt: integer("created_at").notNull(),
    updatedAt: integer("updated_at").notNull(),
  },
  (table) => [
    uniqueIndex("players_username_key_idx").on(table.usernameKey),
    index("players_best_score_idx").on(table.bestScore),
  ],
);

export const runs = sqliteTable(
  "runs",
  {
    id: text("id").primaryKey(),
    secretHash: text("secret_hash").notNull(),
    playerId: text("player_id").notNull(),
    ipHash: text("ip_hash").notNull(),
    createdAt: integer("created_at").notNull(),
    lastSeenAt: integer("last_seen_at").notNull(),
    finishedAt: integer("finished_at"),
    verifiedScore: integer("verified_score").notNull().default(0),
    verifiedWave: integer("verified_wave").notNull().default(1),
    verifiedKills: integer("verified_kills").notNull().default(0),
    rejectedEvents: integer("rejected_events").notNull().default(0),
  },
  (table) => [
    index("runs_player_idx").on(table.playerId),
    index("runs_ip_created_idx").on(table.ipHash, table.createdAt),
  ],
);
