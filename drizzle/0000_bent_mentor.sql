CREATE TABLE `players` (
	`id` text PRIMARY KEY NOT NULL,
	`username` text NOT NULL,
	`username_key` text NOT NULL,
	`device_hash` text NOT NULL,
	`best_score` integer DEFAULT 0 NOT NULL,
	`best_wave` integer DEFAULT 0 NOT NULL,
	`best_kills` integer DEFAULT 0 NOT NULL,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `players_username_key_idx` ON `players` (`username_key`);--> statement-breakpoint
CREATE INDEX `players_best_score_idx` ON `players` (`best_score`);--> statement-breakpoint
CREATE TABLE `runs` (
	`id` text PRIMARY KEY NOT NULL,
	`secret_hash` text NOT NULL,
	`player_id` text NOT NULL,
	`ip_hash` text NOT NULL,
	`created_at` integer NOT NULL,
	`last_seen_at` integer NOT NULL,
	`finished_at` integer,
	`verified_score` integer DEFAULT 0 NOT NULL,
	`verified_wave` integer DEFAULT 1 NOT NULL,
	`verified_kills` integer DEFAULT 0 NOT NULL,
	`rejected_events` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE INDEX `runs_player_idx` ON `runs` (`player_id`);--> statement-breakpoint
CREATE INDEX `runs_ip_created_idx` ON `runs` (`ip_hash`,`created_at`);