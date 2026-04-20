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
- [x] Apply migration to live Supabase instance  ✅ Applied as 5 chunks: 001a–001d + 002
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
- [x] Deploy function to Supabase  ✅ Deployed via Supabase MCP — ACTIVE
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

- [x] Write supabase/functions/mood-detection-proxy/index.ts
      Model: j-hartmann/emotion-english-distilroberta-base
      Trigger: called when elder submits a post (not on voice messages)
      Stores result in mood_logs
      Handle 503 cold start: retry after 20s + return loading state
      Fire-and-forget call to compute-mood-alert after mood_logs insert
- [x] Write MOSAIC alert computation in Edge Function
      supabase/functions/compute-mood-alert/index.ts
      Four signals: sentiment slope, activity count, routine adherence,
      score variance (discrepancy_delta proxy)
      Rolling 7-day window, slope threshold → stable/warning/urgent
      Output upserted to alert_states table, FCM fired on escalation
      New tables: alert_states, fcm_tokens (migration 002_add_alert_states.sql)
- [x] Write supabase/functions/send-medication-reminder/index.ts
      Cron job: ±2.5-minute window query on medication_logs (pending),
      sends FCM to elder device via FCM_SERVER_KEY secret
      Cron setup instructions in function header comment
- [x] Create lib/features/mood/services/mood_service.dart
      Dart service layer that calls mood-detection-proxy Edge Function
      Handles ok / loading / consent_not_given response states
- [x] Create lib/features/mood/providers/mood_service_provider.dart

---

## How to Resume After /clear or /compact

1. Open Claude Code in the project directory
2. Say: "Read CLAUDE.md and ACTION.md and continue backend wiring
   from where we left off"
3. Claude reads both files and picks up from the first unchecked item

---

## Resume Point (updated 2026-04-20)

Steps 1–8 complete. All Edge Functions deployed. All migrations applied. launch.json configured.

**Flutter code — complete and analyze-clean (0 issues):**
- [x] PostSubmissionNotifier — inserts post, fires mood analysis fire-and-forget
- [x] _TextPostComposerSheet — text post compose UI wired to Text button in feed screen
- [x] FcmTokenService — upserts FCM token to Supabase on signedIn event
- [x] main.dart — auth state listener calls FcmTokenService.registerToken()
- [x] app_theme.dart — fixed 18 pre-existing token errors (backgroundWarm/socialBlue etc → current tokens)
- [x] flutter analyze clean — 0 issues

**Design audit — complete (2026-04-17):**
- [x] All 21 screens checked against Stitch designs — 20/21 matched
- [x] Caretaker portal accent colour fixed across 5 screens:
      ElderColors.primary → ElderColors.tertiary (navy blue per CLAUDE.md + Stitch spec)
      Files: caretaker_dashboard, elder_management, manage_links,
             search_link_elder, mood_activity_logs

**Backend deployed — complete (2026-04-17):**
- [x] Migrations: 001a_extensions_enums_users, 001b_caretaker_links,
      001c_posts_mood_logs, 001d_medications_voice, 002_add_alert_states
- [x] Edge Functions: create-elder-account, mood-detection-proxy,
      compute-mood-alert, send-medication-reminder (all ACTIVE)
- [x] launch.json: SUPABASE_URL + SUPABASE_ANON_KEY configured

**Completed (2026-04-17):**
- [x] Apply migration 001_initial_schema.sql ✅ (applied as chunks 001a–001d via Supabase MCP)
- [x] Apply migration 002_add_alert_states.sql ✅
- [x] Deploy Edge Functions ✅ (all 4 ACTIVE via Supabase MCP):
      create-elder-account      → ACTIVE, verify_jwt: true
      mood-detection-proxy      → ACTIVE, verify_jwt: true
      compute-mood-alert        → ACTIVE, verify_jwt: false
      send-medication-reminder  → ACTIVE, verify_jwt: false
- [x] Configure .vscode/launch.json with real SUPABASE_URL + SUPABASE_ANON_KEY ✅
- [x] HUGGINGFACE_API_KEY secret set 2026-04-17 ✅

**Pending user actions before device testing:**
- [ ] Set FCM_SERVER_KEY secret (run in terminal):
      supabase secrets set FCM_SERVER_KEY=<your-fcm-server-key>
- [ ] Set up pg_cron for send-medication-reminder (see function header comment)
- [ ] Verify HUGGINGFACE_API_KEY still active: supabase secrets list

**Device testing — IN PROGRESS (2026-04-20):**
  Samsung S23 Ultra (R5CWC0CWABR, Android 16 API 36) — authorized and running ✅

  Always run with dart-defines (launch.json only works from VS Code):
  ```
  flutter run -d R5CWC0CWABR \
    --dart-define=SUPABASE_URL=https://etjgxxhvphitvpvxvafl.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0amd4eGh2cGhpdHZwdnh2YWZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0NDIxMjQsImV4cCI6MjA5MjAxODEyNH0.MPJo73VNQ7-afhtpsca8kytje4CyQ51IXjZZg2MTPSE
  ```

  Confirmed working:
  - [x] Caretaker registration (needed INSERT RLS policy + email confirmation disabled)
  - [x] Bottom nav wiring on all 4 caretaker screens (was TODO stubs, now context.go())

  Known bugs to fix next session:
  - [ ] elder_management_screen.dart — _buildElderToggle() overflows right ("Arthur Thompson"/"Eleanor Riggs" pill)
  - [ ] Second screen overflow (user mentioned 2 screens — second screenshot not yet shared)
  - NOTE: All fix attempts were reverted. Start fresh — get screenshots of BOTH screens first, then fix all overflows in one pass.

Resume instruction:
  "Read CLAUDE.md and ACTION.md and continue from where we left off"

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
