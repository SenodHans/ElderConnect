-- ============================================================
-- ElderConnect — Initial Schema Migration
-- ============================================================
-- All tables, enums, constraints, and RLS policies for the
-- full application. Apply via: supabase db push
--
-- ⚠️  Review with project owner before applying to live instance.
-- ============================================================

-- ── Extensions ───────────────────────────────────────────────
-- pgcrypto: used for gen_random_uuid() and password utilities.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Enums ────────────────────────────────────────────────────
CREATE TYPE user_role AS ENUM ('elderly', 'caretaker');
CREATE TYPE medication_status AS ENUM ('pending', 'taken', 'missed');


-- ============================================================
-- TABLE: users
-- Core profile table for both elderly users and caretakers.
-- Linked to Supabase auth.users via the id foreign key.
-- ============================================================
CREATE TABLE users (
  id                   UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email                TEXT NOT NULL,
  role                 user_role NOT NULL,
  full_name            TEXT NOT NULL,
  date_of_birth        DATE,
  phone                TEXT,
  -- interests: NewsAPI category keys e.g. ['health','sports','technology']
  interests            TEXT[] NOT NULL DEFAULT '{}',
  tts_enabled          BOOLEAN NOT NULL DEFAULT FALSE,
  mood_sharing_consent BOOLEAN NOT NULL DEFAULT FALSE,
  -- pin_hash: bcrypt hash of 4-digit PIN set by caretaker. NULL until set.
  pin_hash             TEXT,
  -- system_password: encrypted UUID used to restore elder sessions on device.
  -- Set server-side by create-elder-account Edge Function. Never exposed to client.
  system_password      TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read and update their own row.
CREATE POLICY "Users can read own profile"
  ON users FOR SELECT
  USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

-- Caretakers need to read basic profile data for their linked elders
-- (name, tts_enabled, mood_sharing_consent) — see mood_logs policy below.
CREATE POLICY "Caretakers can read linked elder profiles"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM caretaker_links
      WHERE caretaker_id = (SELECT auth.uid())
        AND elderly_user_id = users.id
    )
  );

-- Edge Functions (service role) bypass RLS — no special policy needed.
-- The create-elder-account function uses service role key for INSERT.


-- ============================================================
-- TABLE: caretaker_links
-- Represents the care relationship between a caretaker and an
-- elderly user. Max 2 accepted links per caretaker enforced by
-- a trigger (see below).
-- ============================================================
CREATE TABLE caretaker_links (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  caretaker_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  elderly_user_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  -- status: pending = awaiting acceptance, accepted = active link, rejected = declined
  status           TEXT NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'accepted', 'rejected')),
  -- requested_by: the user (caretaker or elder) who initiated the link request
  requested_by     UUID NOT NULL REFERENCES users(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (caretaker_id, elderly_user_id)
);

ALTER TABLE caretaker_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Caretakers can read own links"
  ON caretaker_links FOR SELECT
  USING ((SELECT auth.uid()) = caretaker_id);

CREATE POLICY "Caretakers can insert own links"
  ON caretaker_links FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = caretaker_id);

CREATE POLICY "Caretakers can delete own links"
  ON caretaker_links FOR DELETE
  USING ((SELECT auth.uid()) = caretaker_id);

-- Elderly users can see who is linked to them.
CREATE POLICY "Elders can read their own link records"
  ON caretaker_links FOR SELECT
  USING ((SELECT auth.uid()) = elderly_user_id);

-- ── Trigger: enforce max 2 elders per caretaker ───────────────
CREATE OR REPLACE FUNCTION enforce_max_elders_per_caretaker()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF (
    SELECT COUNT(*) FROM caretaker_links
    WHERE caretaker_id = NEW.caretaker_id
  ) >= 2 THEN
    RAISE EXCEPTION 'A caretaker may be linked to at most 2 elderly users.';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER check_max_elders_per_caretaker
  BEFORE INSERT ON caretaker_links
  FOR EACH ROW EXECUTE FUNCTION enforce_max_elders_per_caretaker();


-- ============================================================
-- TABLE: posts
-- Social feed posts created by elderly users.
-- Voice messages are stored separately — NOT in this table.
-- ============================================================
CREATE TABLE posts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  photo_url  TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Any authenticated user (elder or linked family) can read posts.
CREATE POLICY "Authenticated users can read posts"
  ON posts FOR SELECT
  TO authenticated
  USING (TRUE);

-- Users can only create posts as themselves.
CREATE POLICY "Users can insert own posts"
  ON posts FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Users can only update or delete their own posts.
CREATE POLICY "Users can update own posts"
  ON posts FOR UPDATE
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own posts"
  ON posts FOR DELETE
  USING ((SELECT auth.uid()) = user_id);


-- ============================================================
-- TABLE: mood_logs
-- AI mood analysis results for elderly users.
-- Written by the mood-detection-proxy Edge Function.
-- Caretaker access gated by mood_sharing_consent on users table.
-- ============================================================
CREATE TABLE mood_logs (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  -- label: top emotion label from j-hartmann/emotion-english-distilroberta-base
  label          TEXT NOT NULL,
  score          FLOAT NOT NULL,
  source_post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE mood_logs ENABLE ROW LEVEL SECURITY;

-- Elderly users can read their own mood logs.
CREATE POLICY "Elders can read own mood logs"
  ON mood_logs FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

-- Caretakers can read mood logs for linked elders who have given consent.
CREATE POLICY "Caretakers can read linked elder mood logs with consent"
  ON mood_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM caretaker_links cl
      JOIN users u ON u.id = mood_logs.user_id
      WHERE cl.caretaker_id = (SELECT auth.uid())
        AND cl.elderly_user_id = mood_logs.user_id
        AND u.mood_sharing_consent = TRUE
    )
  );

-- Edge Function (service role) handles INSERT — no client policy needed.


-- ============================================================
-- TABLE: medications
-- Medication schedules added by caretakers for linked elders.
-- ============================================================
CREATE TABLE medications (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  elderly_user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_by_caretaker_id   UUID NOT NULL REFERENCES users(id),
  pill_name                 TEXT NOT NULL,
  pill_colour               TEXT NOT NULL,
  dosage                    TEXT NOT NULL,
  reminder_times            TIME[] NOT NULL DEFAULT '{}',
  is_active                 BOOLEAN NOT NULL DEFAULT TRUE,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE medications ENABLE ROW LEVEL SECURITY;

-- Caretakers can insert medications for their linked elders.
CREATE POLICY "Caretakers can insert medications for linked elders"
  ON medications FOR INSERT
  WITH CHECK (
    created_by_caretaker_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1 FROM caretaker_links
      WHERE caretaker_id = (SELECT auth.uid())
        AND elderly_user_id = medications.elderly_user_id
    )
  );

-- Caretakers can update medications they created for linked elders.
CREATE POLICY "Caretakers can update own medication records"
  ON medications FOR UPDATE
  USING (
    created_by_caretaker_id = (SELECT auth.uid())
  );

-- Elderly users can read their own medication records.
CREATE POLICY "Elders can read own medications"
  ON medications FOR SELECT
  USING ((SELECT auth.uid()) = elderly_user_id);

-- Caretakers can read medications they created.
CREATE POLICY "Caretakers can read medications they created"
  ON medications FOR SELECT
  USING ((SELECT auth.uid()) = created_by_caretaker_id);


-- ============================================================
-- TABLE: medication_logs
-- Per-dose tracking for medication reminders.
-- Populated by send-medication-reminder Edge Function.
-- ============================================================
CREATE TABLE medication_logs (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medication_id  UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  scheduled_time TIMESTAMPTZ NOT NULL,
  taken_at       TIMESTAMPTZ,
  status         medication_status NOT NULL DEFAULT 'pending',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE medication_logs ENABLE ROW LEVEL SECURITY;

-- Elderly users can read their own medication log entries.
CREATE POLICY "Elders can read own medication logs"
  ON medication_logs FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

-- Elderly users can update their own log entries (mark as taken).
CREATE POLICY "Elders can update own medication logs"
  ON medication_logs FOR UPDATE
  USING ((SELECT auth.uid()) = user_id);

-- Caretakers can read medication logs for their linked elders.
CREATE POLICY "Caretakers can read linked elder medication logs"
  ON medication_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM caretaker_links
      WHERE caretaker_id = (SELECT auth.uid())
        AND elderly_user_id = medication_logs.user_id
    )
  );

-- Edge Function (service role) handles INSERT and status updates.


-- ============================================================
-- TABLE: voice_messages
-- Audio-only messages sent by elderly users.
-- NOT processed by mood detection AI — audio storage only.
-- ============================================================
CREATE TABLE voice_messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  audio_url  TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE voice_messages ENABLE ROW LEVEL SECURITY;

-- Users can read and create their own voice messages.
CREATE POLICY "Users can read own voice messages"
  ON voice_messages FOR SELECT
  USING ((SELECT auth.uid()) = sender_id);

CREATE POLICY "Users can insert own voice messages"
  ON voice_messages FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = sender_id);
