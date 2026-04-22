-- 003_mosaic_columns.sql
--
-- MOSAIC sprint: adds four new columns to mood_logs for multi-signal tracking,
-- and creates daily_prompt_questions with a seed bank of 8 warm questions.

-- ── mood_logs: four new MOSAIC columns ───────────────────────────────────────

ALTER TABLE mood_logs
  ADD COLUMN IF NOT EXISTS source             TEXT    NOT NULL DEFAULT 'post'
    CHECK (source IN ('post', 'daily_prompt', 'nightly_composite')),
  ADD COLUMN IF NOT EXISTS emoji_self_report  TEXT,            -- nullable: '😄'|'🙂'|'😐'|'😔'|'😢'
  ADD COLUMN IF NOT EXISTS discrepancy_flagged BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS composite_score    FLOAT;           -- nullable; populated by nightly Edge Function

COMMENT ON COLUMN mood_logs.source IS
  'Origin of this mood log: social post, daily journal prompt, or nightly composite summary';
COMMENT ON COLUMN mood_logs.emoji_self_report IS
  'Emoji tapped by elder in daily journal prompt — used for discrepancy detection only';
COMMENT ON COLUMN mood_logs.discrepancy_flagged IS
  'True when emoji self-report and HuggingFace inference disagree (masking indicator)';
COMMENT ON COLUMN mood_logs.composite_score IS
  'Weighted daily composite: 0.40×sentiment + 0.20×discrepancy + 0.20×social + 0.20×adherence';

-- ── daily_prompt_questions table ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS daily_prompt_questions (
  id       SERIAL PRIMARY KEY,
  question TEXT NOT NULL UNIQUE
);

ALTER TABLE daily_prompt_questions ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read questions (elder reads them in the journal screen).
CREATE POLICY "Authenticated users can read prompt questions"
  ON daily_prompt_questions FOR SELECT
  TO authenticated
  USING (TRUE);

-- ── Seed data: 8 warm, accessible daily questions ────────────────────────────
INSERT INTO daily_prompt_questions (question) VALUES
  ('What is one thing that made you smile today?'),
  ('Who is someone you are thinking about today?'),
  ('What did you enjoy doing this morning?'),
  ('Is there something small that made today feel good?'),
  ('What is one thing you are looking forward to this week?'),
  ('How has your energy been feeling today?'),
  ('What is a happy memory that came to mind recently?'),
  ('Is there anything on your mind you would like to share today?')
ON CONFLICT (question) DO NOTHING;

-- ── Index: mood_logs user lookup ─────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS mood_logs_user_id_idx ON mood_logs (user_id);
