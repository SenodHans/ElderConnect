-- Migration 011: Clean test data reset — Sri Lankan users
--
-- Run this on your Supabase instance via the SQL editor or supabase db push.
-- ⚠️  This DELETES all existing test data first. Do NOT run on production.
--
-- Test accounts created:
-- ── Caretakers ────────────────────────────────────────────
--   Anusha Perera     anusha.perera@gmail.com       Anusha@2024
--   Dilan Fernando    dilan.fernando@gmail.com       Dilan@2024
--   Rashmi Silva      rashmi.silva@gmail.com         Rashmi@2024
--
-- ── Elders (PIN login — enter on the PIN screen) ──────────
--   Pawan Perera      PIN: 1234
--   Nimal Silva       PIN: 2345
--   Sunil Fernando    PIN: 3456
--   Kamal Jayasinghe  PIN: 4567
--   Somawathi Perera  PIN: 5678
--   Kusum Wijeratne   PIN: 6789
--
-- Caretaker links:
--   Anusha → Pawan Perera, Nimal Silva
--   Dilan  → Sunil Fernando, Kamal Jayasinghe
--   Rashmi → Somawathi Perera, Kusum Wijeratne

-- ── Extensions (ensure available) ────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Step 1: Remove existing test data (by known emails) ──────────────────────
-- Delete in reverse FK order to avoid constraint violations.

DO $$
DECLARE
  test_emails TEXT[] := ARRAY[
    'anusha.perera@gmail.com',
    'dilan.fernando@gmail.com',
    'rashmi.silva@gmail.com',
    'elder_0771234567@elderconnect.internal',
    'elder_0772345678@elderconnect.internal',
    'elder_0773456789@elderconnect.internal',
    'elder_0774567890@elderconnect.internal',
    'elder_0775678901@elderconnect.internal',
    'elder_0776789012@elderconnect.internal'
  ];
  uid UUID;
BEGIN
  FOREACH uid IN ARRAY (
    SELECT ARRAY(SELECT id FROM auth.users WHERE email = ANY(test_emails))
  )
  LOOP
    -- cascade deletes handle child rows in mood_logs, posts, etc.
    DELETE FROM auth.users WHERE id = uid;
  END LOOP;
END $$;

-- ── Step 2: Define fixed UUIDs for deterministic seeding ─────────────────────

DO $$
DECLARE
  -- Caretaker UUIDs
  uid_anusha    UUID := 'a1000000-0000-0000-0000-000000000001';
  uid_dilan     UUID := 'a1000000-0000-0000-0000-000000000002';
  uid_rashmi    UUID := 'a1000000-0000-0000-0000-000000000003';

  -- Elder UUIDs
  uid_pawan     UUID := 'e1000000-0000-0000-0000-000000000001';
  uid_nimal     UUID := 'e1000000-0000-0000-0000-000000000002';
  uid_sunil     UUID := 'e1000000-0000-0000-0000-000000000003';
  uid_kamal     UUID := 'e1000000-0000-0000-0000-000000000004';
  uid_soma      UUID := 'e1000000-0000-0000-0000-000000000005';
  uid_kusum     UUID := 'e1000000-0000-0000-0000-000000000006';

  -- Elder system passwords (used by Supabase signInWithPassword).
  -- Must match encrypted_password inserted into auth.users below.
  pw_pawan      TEXT := 'elder-pawan-sys-001';
  pw_nimal      TEXT := 'elder-nimal-sys-002';
  pw_sunil      TEXT := 'elder-sunil-sys-003';
  pw_kamal      TEXT := 'elder-kamal-sys-004';
  pw_soma       TEXT := 'elder-soma-sys-005';
  pw_kusum      TEXT := 'elder-kusum-sys-006';

  -- Caretaker login passwords
  pw_anusha     TEXT := 'Anusha@2024';
  pw_dilan      TEXT := 'Dilan@2024';
  pw_rashmi     TEXT := 'Rashmi@2024';

  -- Link UUIDs
  link_anusha_pawan   UUID := 'c0000000-0000-0000-0000-000000000001';
  link_anusha_nimal   UUID := 'c0000000-0000-0000-0000-000000000002';
  link_dilan_sunil    UUID := 'c0000000-0000-0000-0000-000000000003';
  link_dilan_kamal    UUID := 'c0000000-0000-0000-0000-000000000004';
  link_rashmi_soma    UUID := 'c0000000-0000-0000-0000-000000000005';
  link_rashmi_kusum   UUID := 'c0000000-0000-0000-0000-000000000006';

  now_ts   TIMESTAMPTZ := NOW();

BEGIN

  -- ── Step 3: Create auth.users entries ────────────────────────────────────

  -- Caretakers
  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_user_meta_data,
    created_at, updated_at, is_sso_user, is_anonymous
  ) VALUES
  (
    uid_anusha, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'anusha.perera@gmail.com',
    crypt(pw_anusha, gen_salt('bf', 10)),
    now_ts,
    '{"role":"caretaker","full_name":"Anusha Perera"}'::jsonb,
    now_ts, now_ts, false, false
  ),
  (
    uid_dilan, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'dilan.fernando@gmail.com',
    crypt(pw_dilan, gen_salt('bf', 10)),
    now_ts,
    '{"role":"caretaker","full_name":"Dilan Fernando"}'::jsonb,
    now_ts, now_ts, false, false
  ),
  (
    uid_rashmi, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'rashmi.silva@gmail.com',
    crypt(pw_rashmi, gen_salt('bf', 10)),
    now_ts,
    '{"role":"caretaker","full_name":"Rashmi Silva"}'::jsonb,
    now_ts, now_ts, false, false
  ),
  -- Elders (email format matches create-elder-account Edge Function convention)
  (
    uid_pawan, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'elder_0771234567@elderconnect.internal',
    crypt(pw_pawan, gen_salt('bf', 10)),
    now_ts,
    '{"role":"elderly","full_name":"Pawan Perera"}'::jsonb,
    now_ts, now_ts, false, false
  ),
  (
    uid_nimal, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'elder_0772345678@elderconnect.internal',
    crypt(pw_nimal, gen_salt('bf', 10)),
    now_ts,
    '{"role":"elderly","full_name":"Nimal Silva"}'::jsonb,
    now_ts, now_ts, false, false
  ),
  (
    uid_sunil, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'elder_0773456789@elderconnect.internal',
    crypt(pw_sunil, gen_salt('bf', 10)),
    now_ts,
    '{"role":"elderly","full_name":"Sunil Fernando"}'::jsonb,
    now_ts, now_ts, false, false
  ),
  (
    uid_kamal, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'elder_0774567890@elderconnect.internal',
    crypt(pw_kamal, gen_salt('bf', 10)),
    now_ts,
    '{"role":"elderly","full_name":"Kamal Jayasinghe"}'::jsonb,
    now_ts, now_ts, false, false
  ),
  (
    uid_soma, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'elder_0775678901@elderconnect.internal',
    crypt(pw_soma, gen_salt('bf', 10)),
    now_ts,
    '{"role":"elderly","full_name":"Somawathi Perera"}'::jsonb,
    now_ts, now_ts, false, false
  ),
  (
    uid_kusum, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'elder_0776789012@elderconnect.internal',
    crypt(pw_kusum, gen_salt('bf', 10)),
    now_ts,
    '{"role":"elderly","full_name":"Kusum Wijeratne"}'::jsonb,
    now_ts, now_ts, false, false
  );

  -- ── Step 4: Create users table profiles ──────────────────────────────────

  -- Caretakers
  INSERT INTO users (id, email, role, full_name, phone, created_at)
  VALUES
  (
    uid_anusha, 'anusha.perera@gmail.com', 'caretaker',
    'Anusha Perera', '0771100001', now_ts
  ),
  (
    uid_dilan, 'dilan.fernando@gmail.com', 'caretaker',
    'Dilan Fernando', '0771100002', now_ts
  ),
  (
    uid_rashmi, 'rashmi.silva@gmail.com', 'caretaker',
    'Rashmi Silva', '0771100003', now_ts
  );

  -- Elders — include pin_plain, pin_hash, system_password, consent, interests
  INSERT INTO users (
    id, email, role, full_name, phone, date_of_birth,
    interests, tts_enabled, mood_sharing_consent,
    pin_plain, pin_hash, system_password, created_at
  )
  VALUES
  (
    uid_pawan,
    'elder_0771234567@elderconnect.internal',
    'elderly', 'Pawan Perera', '0771234567',
    '1950-03-15',
    ARRAY['health','sports','local'],
    true, true,
    '1234',
    crypt('1234', gen_salt('bf', 10)),
    pw_pawan,
    now_ts
  ),
  (
    uid_nimal,
    'elder_0772345678@elderconnect.internal',
    'elderly', 'Nimal Silva', '0772345678',
    '1948-07-22',
    ARRAY['health','technology'],
    false, true,
    '2345',
    crypt('2345', gen_salt('bf', 10)),
    pw_nimal,
    now_ts
  ),
  (
    uid_sunil,
    'elder_0773456789@elderconnect.internal',
    'elderly', 'Sunil Fernando', '0773456789',
    '1952-11-05',
    ARRAY['health','local','entertainment'],
    true, true,
    '3456',
    crypt('3456', gen_salt('bf', 10)),
    pw_sunil,
    now_ts
  ),
  (
    uid_kamal,
    'elder_0774567890@elderconnect.internal',
    'elderly', 'Kamal Jayasinghe', '0774567890',
    '1945-01-30',
    ARRAY['sports','local'],
    false, true,
    '4567',
    crypt('4567', gen_salt('bf', 10)),
    pw_kamal,
    now_ts
  ),
  (
    uid_soma,
    'elder_0775678901@elderconnect.internal',
    'elderly', 'Somawathi Perera', '0775678901',
    '1949-06-18',
    ARRAY['health','entertainment'],
    true, true,
    '5678',
    crypt('5678', gen_salt('bf', 10)),
    pw_soma,
    now_ts
  ),
  (
    uid_kusum,
    'elder_0776789012@elderconnect.internal',
    'elderly', 'Kusum Wijeratne', '0776789012',
    '1953-09-12',
    ARRAY['health','local','sports'],
    true, true,
    '6789',
    crypt('6789', gen_salt('bf', 10)),
    pw_kusum,
    now_ts
  );

  -- ── Step 5: Create caretaker links (all accepted) ─────────────────────────

  INSERT INTO caretaker_links (id, caretaker_id, elderly_user_id, status, requested_by, created_at)
  VALUES
  (link_anusha_pawan, uid_anusha, uid_pawan,  'accepted', uid_anusha, now_ts),
  (link_anusha_nimal, uid_anusha, uid_nimal,  'accepted', uid_anusha, now_ts),
  (link_dilan_sunil,  uid_dilan,  uid_sunil,  'accepted', uid_dilan,  now_ts),
  (link_dilan_kamal,  uid_dilan,  uid_kamal,  'accepted', uid_dilan,  now_ts),
  (link_rashmi_soma,  uid_rashmi, uid_soma,   'accepted', uid_rashmi, now_ts),
  (link_rashmi_kusum, uid_rashmi, uid_kusum,  'accepted', uid_rashmi, now_ts);

  -- ── Step 6: Seed mood_logs for Pawan (14 days, varied — for chart testing) ──

  INSERT INTO mood_logs (id, user_id, label, score, created_at)
  VALUES
  -- Day -13 (stable)
  (gen_random_uuid(), uid_pawan, 'POSITIVE', 0.82, now_ts - INTERVAL '13 days'),
  -- Day -12 (stable)
  (gen_random_uuid(), uid_pawan, 'POSITIVE', 0.74, now_ts - INTERVAL '12 days'),
  -- Day -11 (neutral)
  (gen_random_uuid(), uid_pawan, 'NEUTRAL',  0.55, now_ts - INTERVAL '11 days'),
  -- Day -10 (warning)
  (gen_random_uuid(), uid_pawan, 'NEGATIVE', 0.62, now_ts - INTERVAL '10 days'),
  -- Day -9 (warning)
  (gen_random_uuid(), uid_pawan, 'NEGATIVE', 0.68, now_ts - INTERVAL '9 days'),
  -- Day -8 (stable)
  (gen_random_uuid(), uid_pawan, 'POSITIVE', 0.71, now_ts - INTERVAL '8 days'),
  -- Day -7 (stable)
  (gen_random_uuid(), uid_pawan, 'POSITIVE', 0.79, now_ts - INTERVAL '7 days'),
  -- Day -6 → shows in 7-day chart (stable)
  (gen_random_uuid(), uid_pawan, 'POSITIVE', 0.83, now_ts - INTERVAL '6 days'),
  -- Day -5 (neutral)
  (gen_random_uuid(), uid_pawan, 'NEUTRAL',  0.52, now_ts - INTERVAL '5 days'),
  -- Day -4 (warning)
  (gen_random_uuid(), uid_pawan, 'NEGATIVE', 0.63, now_ts - INTERVAL '4 days'),
  -- Day -3 (urgent)
  (gen_random_uuid(), uid_pawan, 'NEGATIVE', 0.88, now_ts - INTERVAL '3 days'),
  -- Day -2 (warning)
  (gen_random_uuid(), uid_pawan, 'NEGATIVE', 0.65, now_ts - INTERVAL '2 days'),
  -- Day -1 (neutral recovering)
  (gen_random_uuid(), uid_pawan, 'NEUTRAL',  0.48, now_ts - INTERVAL '1 day'),
  -- Today (stable)
  (gen_random_uuid(), uid_pawan, 'POSITIVE', 0.76, now_ts);

  -- Mood logs for Nimal (7 days, mostly stable with one warning)
  INSERT INTO mood_logs (id, user_id, label, score, created_at)
  VALUES
  (gen_random_uuid(), uid_nimal, 'POSITIVE', 0.78, now_ts - INTERVAL '6 days'),
  (gen_random_uuid(), uid_nimal, 'POSITIVE', 0.81, now_ts - INTERVAL '5 days'),
  (gen_random_uuid(), uid_nimal, 'NEUTRAL',  0.57, now_ts - INTERVAL '4 days'),
  (gen_random_uuid(), uid_nimal, 'NEGATIVE', 0.61, now_ts - INTERVAL '3 days'),
  (gen_random_uuid(), uid_nimal, 'POSITIVE', 0.72, now_ts - INTERVAL '2 days'),
  (gen_random_uuid(), uid_nimal, 'POSITIVE', 0.85, now_ts - INTERVAL '1 day'),
  (gen_random_uuid(), uid_nimal, 'POSITIVE', 0.91, now_ts);

  -- Mood logs for Sunil (7 days, declining trend → urgent)
  INSERT INTO mood_logs (id, user_id, label, score, created_at)
  VALUES
  (gen_random_uuid(), uid_sunil, 'POSITIVE', 0.75, now_ts - INTERVAL '6 days'),
  (gen_random_uuid(), uid_sunil, 'NEUTRAL',  0.53, now_ts - INTERVAL '5 days'),
  (gen_random_uuid(), uid_sunil, 'NEGATIVE', 0.58, now_ts - INTERVAL '4 days'),
  (gen_random_uuid(), uid_sunil, 'NEGATIVE', 0.69, now_ts - INTERVAL '3 days'),
  (gen_random_uuid(), uid_sunil, 'NEGATIVE', 0.77, now_ts - INTERVAL '2 days'),
  (gen_random_uuid(), uid_sunil, 'NEGATIVE', 0.84, now_ts - INTERVAL '1 day'),
  (gen_random_uuid(), uid_sunil, 'NEGATIVE', 0.91, now_ts);

  -- Mood logs for Kamal (7 days, stable throughout)
  INSERT INTO mood_logs (id, user_id, label, score, created_at)
  VALUES
  (gen_random_uuid(), uid_kamal, 'POSITIVE', 0.88, now_ts - INTERVAL '6 days'),
  (gen_random_uuid(), uid_kamal, 'POSITIVE', 0.85, now_ts - INTERVAL '5 days'),
  (gen_random_uuid(), uid_kamal, 'POSITIVE', 0.79, now_ts - INTERVAL '4 days'),
  (gen_random_uuid(), uid_kamal, 'POSITIVE', 0.92, now_ts - INTERVAL '3 days'),
  (gen_random_uuid(), uid_kamal, 'NEUTRAL',  0.55, now_ts - INTERVAL '2 days'),
  (gen_random_uuid(), uid_kamal, 'POSITIVE', 0.81, now_ts - INTERVAL '1 day'),
  (gen_random_uuid(), uid_kamal, 'POSITIVE', 0.87, now_ts);

  -- Mood logs for Somawathi (7 days, mixed)
  INSERT INTO mood_logs (id, user_id, label, score, created_at)
  VALUES
  (gen_random_uuid(), uid_soma, 'NEUTRAL',  0.54, now_ts - INTERVAL '6 days'),
  (gen_random_uuid(), uid_soma, 'POSITIVE', 0.71, now_ts - INTERVAL '5 days'),
  (gen_random_uuid(), uid_soma, 'NEGATIVE', 0.64, now_ts - INTERVAL '4 days'),
  (gen_random_uuid(), uid_soma, 'NEGATIVE', 0.72, now_ts - INTERVAL '3 days'),
  (gen_random_uuid(), uid_soma, 'POSITIVE', 0.68, now_ts - INTERVAL '2 days'),
  (gen_random_uuid(), uid_soma, 'NEUTRAL',  0.51, now_ts - INTERVAL '1 day'),
  (gen_random_uuid(), uid_soma, 'POSITIVE', 0.74, now_ts);

  -- Mood logs for Kusum (7 days, stable and happy)
  INSERT INTO mood_logs (id, user_id, label, score, created_at)
  VALUES
  (gen_random_uuid(), uid_kusum, 'POSITIVE', 0.90, now_ts - INTERVAL '6 days'),
  (gen_random_uuid(), uid_kusum, 'POSITIVE', 0.87, now_ts - INTERVAL '5 days'),
  (gen_random_uuid(), uid_kusum, 'POSITIVE', 0.83, now_ts - INTERVAL '4 days'),
  (gen_random_uuid(), uid_kusum, 'POSITIVE', 0.89, now_ts - INTERVAL '3 days'),
  (gen_random_uuid(), uid_kusum, 'POSITIVE', 0.92, now_ts - INTERVAL '2 days'),
  (gen_random_uuid(), uid_kusum, 'POSITIVE', 0.86, now_ts - INTERVAL '1 day'),
  (gen_random_uuid(), uid_kusum, 'POSITIVE', 0.94, now_ts);

  -- ── Step 7: Seed alert_states for chart-ready display ────────────────────

  INSERT INTO alert_states (
    id, elderly_user_id, status,
    activity_count, routine_adherence, sentiment_slope,
    computed_at
  )
  VALUES
  (gen_random_uuid(), uid_pawan,  'warning', 8, 0.85, -0.18, now_ts),
  (gen_random_uuid(), uid_nimal,  'stable',  5, 0.95, 0.12,  now_ts),
  (gen_random_uuid(), uid_sunil,  'urgent',  3, 0.60, -0.42, now_ts),
  (gen_random_uuid(), uid_kamal,  'stable',  7, 1.00, 0.25,  now_ts),
  (gen_random_uuid(), uid_soma,   'warning', 4, 0.78, -0.15, now_ts),
  (gen_random_uuid(), uid_kusum,  'stable',  9, 1.00, 0.31,  now_ts)
  ON CONFLICT (elderly_user_id) DO UPDATE
    SET status           = EXCLUDED.status,
        activity_count   = EXCLUDED.activity_count,
        routine_adherence= EXCLUDED.routine_adherence,
        sentiment_slope  = EXCLUDED.sentiment_slope,
        computed_at      = EXCLUDED.computed_at;

  -- ── Step 8: Seed posts for Pawan (for PDF export + feed testing) ──────────

  INSERT INTO posts (id, user_id, content, created_at)
  VALUES
  (
    gen_random_uuid(), uid_pawan,
    'Went for a morning walk today at Viharamahadevi Park. The air was fresh and I felt wonderful!',
    now_ts - INTERVAL '5 days'
  ),
  (
    gen_random_uuid(), uid_pawan,
    'Had a good lunch with the family — rice and curry made by my daughter. Feeling grateful today.',
    now_ts - INTERVAL '3 days'
  ),
  (
    gen_random_uuid(), uid_pawan,
    'Feeling a little tired today. The legs are aching. Hope tomorrow is better.',
    now_ts - INTERVAL '1 day'
  );

  -- Posts for Nimal
  INSERT INTO posts (id, user_id, content, created_at)
  VALUES
  (
    gen_random_uuid(), uid_nimal,
    'Watched the cricket match today. Sri Lanka played well!',
    now_ts - INTERVAL '4 days'
  ),
  (
    gen_random_uuid(), uid_nimal,
    'Took my evening medication on time. Feeling steady.',
    now_ts - INTERVAL '2 days'
  );

  -- Posts for Sunil
  INSERT INTO posts (id, user_id, content, created_at)
  VALUES
  (
    gen_random_uuid(), uid_sunil,
    'Not feeling my best this week. Missing having someone to talk to.',
    now_ts - INTERVAL '3 days'
  ),
  (
    gen_random_uuid(), uid_sunil,
    'Rain all day. Stayed inside. Could not sleep well last night.',
    now_ts - INTERVAL '1 day'
  );

  -- ── Step 9: Seed wellness_logs (games played) ─────────────────────────────

  INSERT INTO wellness_logs (id, user_id, game_name, score, created_at)
  VALUES
  (gen_random_uuid(), uid_pawan,  'Memory Match',   420, now_ts - INTERVAL '5 days'),
  (gen_random_uuid(), uid_pawan,  'Word Scramble',  310, now_ts - INTERVAL '3 days'),
  (gen_random_uuid(), uid_pawan,  'Trivia Quiz',    280, now_ts - INTERVAL '1 day'),
  (gen_random_uuid(), uid_nimal,  'Memory Match',   380, now_ts - INTERVAL '4 days'),
  (gen_random_uuid(), uid_sunil,  'Trivia Quiz',    200, now_ts - INTERVAL '2 days'),
  (gen_random_uuid(), uid_kamal,  'Memory Match',   460, now_ts - INTERVAL '3 days'),
  (gen_random_uuid(), uid_kamal,  'Word Scramble',  330, now_ts - INTERVAL '1 day'),
  (gen_random_uuid(), uid_soma,   'Memory Match',   290, now_ts - INTERVAL '5 days'),
  (gen_random_uuid(), uid_kusum,  'Trivia Quiz',    410, now_ts - INTERVAL '2 days');

  -- ── Step 10: Seed medications for each elder ──────────────────────────────

  INSERT INTO medications (
    id, elderly_user_id, created_by_caretaker_id,
    pill_name, pill_colour, dosage, reminder_times, is_active, created_at
  )
  VALUES
  -- Pawan's medications (Anusha's elder)
  (
    gen_random_uuid(), uid_pawan, uid_anusha,
    'Metformin', 'white', '500mg — 1 tablet',
    ARRAY['08:00', '20:00']::time[], true, now_ts
  ),
  (
    gen_random_uuid(), uid_pawan, uid_anusha,
    'Atorvastatin', 'pink', '20mg — 1 tablet',
    ARRAY['21:00']::time[], true, now_ts
  ),
  -- Nimal's medications
  (
    gen_random_uuid(), uid_nimal, uid_anusha,
    'Amlodipine', 'yellow', '5mg — 1 tablet',
    ARRAY['07:30', '19:30']::time[], true, now_ts
  ),
  -- Sunil's medications (Dilan's elder)
  (
    gen_random_uuid(), uid_sunil, uid_dilan,
    'Lisinopril', 'orange', '10mg — 1 tablet',
    ARRAY['09:00']::time[], true, now_ts
  ),
  -- Kamal's medications
  (
    gen_random_uuid(), uid_kamal, uid_dilan,
    'Aspirin', 'white', '75mg — 1 tablet',
    ARRAY['08:00']::time[], true, now_ts
  ),
  -- Somawathi's medications (Rashmi's elder)
  (
    gen_random_uuid(), uid_soma, uid_rashmi,
    'Metoprolol', 'blue', '25mg — 1 tablet',
    ARRAY['08:30', '20:30']::time[], true, now_ts
  ),
  -- Kusum's medications
  (
    gen_random_uuid(), uid_kusum, uid_rashmi,
    'Omeprazole', 'purple', '20mg — 1 capsule',
    ARRAY['07:00']::time[], true, now_ts
  );

END $$;

-- ── Verification queries (run separately after migration to confirm) ─────────
-- SELECT role, full_name, email FROM users ORDER BY role, full_name;
-- SELECT c.full_name AS caretaker, e.full_name AS elder, cl.status
--   FROM caretaker_links cl
--   JOIN users c ON c.id = cl.caretaker_id
--   JOIN users e ON e.id = cl.elderly_user_id
--   ORDER BY c.full_name;
-- SELECT u.full_name, ml.label, ml.score, ml.created_at::date
--   FROM mood_logs ml JOIN users u ON u.id = ml.user_id ORDER BY ml.created_at DESC LIMIT 20;
