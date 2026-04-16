# ElderConnect — Backend Action Plan

## What This File Is
Active working document for the backend wiring sprint.
Read this at the start of every Claude Code session to resume exactly
where we left off. Tick checkboxes as each task is confirmed complete.

---

## Open Decisions (must resolve before the relevant step)

| Decision | Status |
|----------|--------|
| Elder auth: OTP confirmed on caretaker device, PIN set by caretaker | ✅ Confirmed |
| Elder Supabase account created via Edge Function (service role key) | ✅ Confirmed |
| Elder session persists via flutter_secure_storage — PIN is fallback only | ✅ Confirmed |
| Connection requests: both elders and caretakers can initiate | ✅ Confirmed | 
| Max elders per caretaker: 2 | ✅ Confirmed |

---

## Missing Packages (add at start of Step 2)

- [x] flutter_local_notifications: ^17.2.2
- [x] image_picker: ^1.1.2
- [x] flutter_secure_storage: ^9.2.2
- [x] firebase_core: ^4.6.0  ← NOTE: must be ^4.6.0, NOT ^3.x — firebase_messaging 16.x requires it
- [x] bcrypt: ^1.1.3
- [x] speech_to_text upgraded ^6.6.2 → ^7.0.0 to resolve JS version conflict with flutter_secure_storage

---

## Step 1 — Supabase Schema + Credentials ⚠️ BLOCKS EVERYTHING

- [x] Write supabase/migrations/001_initial_schema.sql
      Tables required:
      - users (id, email, role, full_name, date_of_birth, phone,
        interests text[], tts_enabled, mood_sharing_consent,
        pin_hash, system_password, created_at)
      - caretaker_links (id, caretaker_id, elderly_user_id,
            status CHECK('pending','accepted','rejected'),
            requested_by uuid FK → users,
            created_at)
            + trigger enforcing max 2 accepted links per caretaker
      - posts (id, user_id, content, photo_url, created_at)
      - mood_logs (id, user_id, label, score, source_post_id, created_at)
      - medications (id, elderly_user_id, created_by_caretaker_id,
        pill_name, pill_colour, dosage, reminder_times time[],
        is_active, created_at)
      - medication_logs (id, medication_id, user_id, scheduled_time,
        taken_at, status)
      - voice_messages (id, sender_id, audio_url, created_at)
      Include all RLS policies per CLAUDE.md rules
- [x] Confirm migration SQL with user before executing — do not apply live
      without explicit approval
- [ ] Apply migration to live Supabase instance  ← PENDING explicit user approval
- [x] Create .vscode/launch.json with run configuration:
      --dart-define=SUPABASE_URL=<url>
      --dart-define=SUPABASE_ANON_KEY=<key>

---

## Step 1b — create-elder-account Edge Function ⚠️ BLOCKS ELDER AUTH

Must be deployed before any elder registration flow can be wired.

- [x] Write supabase/functions/create-elder-account/index.ts
      Input: { phone: string, full_name: string, caretaker_id: string }
      Logic:
        1. Generate email: elder_{phone}@elderconnect.internal
        2. Generate UUID password
        3. Call supabase.auth.admin.createUser() with generated credentials
        4. Insert row into users table with role='elderly'
        5. Store system_password (encrypted) in users table
        6. Return: { elder_id, email } — never return password to client
      Auth: service role key only — never anon key
- [ ] Deploy function to Supabase  ← PENDING user runs: supabase functions deploy create-elder-account
- [ ] Confirm function is callable from caretaker's authenticated session

---

## Step 2 — Auth Service + Provider (blocks all navigation)

- [x] Add missing packages to pubspec.yaml, run flutter pub get
- [x] Create lib/features/auth/services/auth_service.dart
      Methods:
      - signUpCaretaker(name, email, phone, password)
      - signInCaretaker(email, password)
      - signOut()
      - createElderAccount(phone, fullName) — calls Edge Function
      - verifyElderPin(elderId, pin) — bcrypt compare against pin_hash
      - setElderPin(elderId, pin) — bcrypt hash + store in users.pin_hash
      - persistElderSession(session) — write to flutter_secure_storage
      - restoreElderSession() — read from flutter_secure_storage
      - verifyPinLocal(pin, storedHash) — offline BCrypt compare (no DB query)
- [x] Create lib/features/auth/providers/auth_provider.dart
      authServiceProvider (Provider) + authStateProvider (StreamProvider)
- [x] Wire caretaker_registration_screen.dart submit → signUpCaretaker()
- [x] Wire caretaker_login_screen.dart submit → signInCaretaker()
- [x] Wire elder PIN login screen → verifyPinLocal() → restoreElderSession()
- [x] Wire elder session restore on app start → flutter_secure_storage
      (elder_login_fallback_screen.dart wired: phone check → restoreElderSession)
- [ ] flutter analyze clean — run and verify before Step 3

---

## Step 3 — GoRouter Auth Guard (blocks correct app flow)

- [x] Add redirect: callback to GoRouter in app.dart
      Logic:
        no session + protected route → /role-selection
        session + login-only route → /home/elder or /home/caretaker
      Role read from auth.currentUser.userMetadata['role'] (synchronous, no DB query)
      Role stored in user_metadata during signUpCaretaker + createUser Edge Function
- [x] Add refreshListenable wired to supabase.auth.onAuthStateChange
      _AuthRefreshNotifier(ChangeNotifier) wraps the auth stream in app.dart
- [x] Fix splash_screen.dart — check session state before navigating,
      role-based redirect if session exists; /role-selection if not
- [x] flutter analyze clean — 0 issues after Step 3

---

## Step 4 — User Profile Provider (blocks all personalised screens)

- [x] Create lib/shared/models/user_model.dart
      Maps Supabase users row → UserModel with firstName convenience getter
- [x] Create lib/features/auth/providers/user_provider.dart
      StreamProvider backed by Supabase Realtime stream on users table
- [x] Wire interest selection screen to persist to users.interests on Supabase
      _saveAndNavigate(): update users SET interests WHERE id=uid, then go('/home/elder')
- [x] Replace hardcoded name in elder_profile_screen.dart
      _IdentitySection → ConsumerWidget, reads userProvider, placeholder shimmer while loading
- [x] Replace hardcoded name in elder_home_screen.dart greeting
      _GreetingSection → ConsumerWidget, time-of-day greeting + user.firstName
- [ ] tts_enabled wiring deferred — profile screen has no TTS toggle UI yet (Step 8 scope)
- [x] flutter analyze clean — 0 issues after Step 4

---

## Step 5 — Firebase Setup (blocks push notifications)

- [x] Run: flutterfire configure in project root
- [x] Commit generated lib/firebase_options.dart
- [x] Implement Firebase.initializeApp() in main.dart

---

## Step 6 — Social Feed Provider (blocks live feed)

- [x] Create lib/features/social/providers/posts_provider.dart
      Query: posts joined with users, ordered by created_at desc
- [x] Replace two hardcoded _SocialPostCard widgets in
      elder_feed_screen.dart with provider-driven ListView
- [x] Add Supabase realtime subscription for live updates

---

## Step 7 — Medications Provider (blocks medication screens)

- [x] Create lib/features/medications/providers/medications_provider.dart
      Query: medications + medication_logs for current elder user
- [x] Wire _hasMedication flag in elder_home_screen.dart
- [x] Wire _hasMedication flag in elder_feed_screen.dart
- [x] Populate elder_medication_list_screen.dart with real data

---

## Step 8 — Edge Functions + MOSAIC (blocks mood detection + alerts)

- [ ] Write supabase/functions/mood-detection-proxy/index.ts
      Model: j-hartmann/emotion-english-distilroberta-base
      Trigger: called when elder submits a post (not on voice messages)
      Stores result in mood_logs
      Handle 503 cold start: retry after 20s + return loading state
- [ ] Write MOSAIC alert computation in Edge Function
      Four signals: HuggingFace sentiment score, self-report emoji
      discrepancy delta, social activity count, routine adherence
      Rolling 7-day window, slope threshold → stable/warning/urgent
      Output written to alert_states table, FCM triggered on escalation
- [ ] Write supabase/functions/send-medication-reminder/index.ts
      Cron job: checks medication_logs for pending reminders,
      sends FCM via Firebase Admin SDK
- [ ] Create lib/features/mood/services/mood_service.dart
      Dart service layer that calls mood-detection-proxy Edge Function

---

## How to Resume After /clear or /compact

1. Open Claude Code in the project directory
2. Say: "Read CLAUDE.md and ACTION.md and continue backend wiring
   from where we left off"
3. Claude reads both files and picks up from the first unchecked item

---

## Resume Point (updated 2026-04-15)

Steps 1, 1b, 2, 3, 4 are complete. `flutter analyze` is clean (0 issues).

**Step 5 is next: Firebase Setup**
  1. User runs: `flutterfire configure` in project root (interactive — Claude cannot run this)
  2. Commit generated lib/firebase_options.dart
  3. Wire Firebase.initializeApp() in lib/main.dart

**Step 6 follows** — social feed provider + wire elder_feed_screen.dart
**Step 7 follows** — medications provider + wire portal screens

Resume instruction:
  "Read CLAUDE.md and ACTION.md and continue backend wiring from where we left off"

---

## Critical Notes
- flutter analyze must pass clean after every step
- Confirm schema DDL with user before any live Supabase operation
- HuggingFace model: j-hartmann/emotion-english-distilroberta-base
- Elder Supabase account created server-side via Edge Function only —
  never from Flutter client
- bcrypt used for PIN hash only — not for Supabase auth password
- Elder session persists via flutter_secure_storage — PIN screen is
  fallback only, not daily use
- Voice messages are NOT processed by mood detection — audio storage only
- Mood analysis only runs if users.mood_sharing_consent = true
