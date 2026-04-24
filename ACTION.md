# ElderConnect — Action Plan

## How to Resume After /clear or Reopening Terminal

1. Open Claude Code in the project directory
2. Say: **"Read CLAUDE.md and ACTION.md and continue from where we left off"**
3. ADB path: `~/Library/Android/sdk/platform-tools/adb` — add to PATH if not found

---

## Current Status — 2026-04-24

**All sprints COMPLETE.** App is fully built and running on Samsung S24 Ultra (R5CWC0CWABR).

| Sprint | Status |
|--------|--------|
| UI Layer (21 screens) | ✅ COMPLETE |
| Backend (Supabase, auth, Edge Functions) | ✅ COMPLETE |
| Feature Wiring (all providers live) | ✅ COMPLETE |
| MOSAIC Sprint (nightly composite + regression) | ✅ COMPLETE |
| Auth Polish (session restore, forgot password, elder support) | ✅ COMPLETE |
| Profile + UX polish (avatar, high contrast, interests) | ✅ COMPLETE |

**Test suite:** 79/79 unit + widget tests passing  
**flutter analyze:** 0 errors, 0 warnings (42 style-only info hints)  
**Last APK build:** Clean debug APK ✅

---

## ACTIVE SPRINT — QA & Thesis Evidence Gathering

We were mid-session collecting three types of measurable evidence for the thesis evaluation chapter. **Resume here.**

### Track 1 — Integration Tests (write + run on device) ⬅ NOT STARTED

Write `integration_test/` directory with Flutter integration tests that run on the S24 Ultra.

**Add to pubspec.yaml dev_dependencies:**
```yaml
integration_test:
  sdk: flutter
```

**Files to create:**
- `integration_test/app_test.dart` — launch app, verify role-selection screen appears, test caretaker login form validation (no auth needed for form tests)
- `integration_test/accessibility_audit_test.dart` — run `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` on key screens

**Run command (device must be connected):**
```bash
~/Library/Android/sdk/platform-tools/adb devices
# confirm R5CWC0CWABR appears, then:
flutter test integration_test/ -d R5CWC0CWABR \
  --dart-define=SUPABASE_URL=https://etjgxxhvphitvpvxvafl.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0amd4eGh2cGhpdHZwdnh2YWZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0NDIxMjQsImV4cCI6MjA5MjAxODEyNH0.MPJo73VNQ7-afhtpsca8kytje4CyQ51IXjZZg2MTPSE
```

**What this produces for thesis:** Integration test count + WCAG compliance pass/fail with actual numbers.

---

### Track 2 — HuggingFace API Timing ⬅ NOT STARTED

**Step A — Update the Edge Function to log precise timing:**

Edit `supabase/functions/mood-detection-proxy/index.ts` — add timing around the HuggingFace call inside `queryHuggingFace()`:

```typescript
// Before the fetch call:
const hfStart = Date.now();

// After the successful response:
const hfLatencyMs = Date.now() - hfStart;
console.log(`[MOSAIC] HuggingFace latency: ${hfLatencyMs}ms | model: ${HF_MODEL} | cold_start: false`);

// After the 503 retry:
console.log(`[MOSAIC] HuggingFace cold-start detected. Retrying after 25s...`);
// then after retry:
console.log(`[MOSAIC] HuggingFace latency after cold-start: ${Date.now() - hfStart}ms`);
```

**Step B — Deploy updated function:**
```bash
cd "/Users/xenonhans/Documents/UG Project - ElderConnect"
npx supabase functions deploy mood-detection-proxy --project-ref etjgxxhvphitvpvxvafl
```

**Step C — Trigger a test post from the app** (elder account, text post with mood consent = true)

**Step D — Read logs from Supabase dashboard:**
- Go to Supabase dashboard → Functions → mood-detection-proxy → Logs
- OR via Supabase MCP: `mcp__supabase__get_logs` with `service: "edge-function"`, `project_id: "etjgxxhvphitvpvxvafl"`

**What this produces for thesis:** Measured HuggingFace response times in ms (warm vs cold start), logged server-side — more accurate than client-side measurement.

---

### Track 3 — Google Accessibility Scanner (on device) ⬅ NOT STARTED

**Step A — Install on device via ADB:**
```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
# Check if already installed:
adb -s R5CWC0CWABR shell pm list packages | grep accessibility
# Package name: com.google.android.apps.accessibility.auditor
```

If not installed, user needs to install from Play Store:
- Open Play Store on device → search "Accessibility Scanner" → install (Google LLC)

**Step B — Enable it:**
- Device Settings → Accessibility → Installed apps → Accessibility Scanner → Enable
- Blue floating button appears on screen

**Step C — Scan these screens (run app first):**
1. Role Selection screen
2. Caretaker Login screen
3. Elder PIN Login screen
4. Elder Home screen
5. Elder Feed screen
6. Caretaker Dashboard screen

**Step D — Export results:**
- Each scan saves a screenshot + report to device storage
- Pull from device: `adb -s R5CWC0CWABR pull /sdcard/Pictures/Accessibility\ Scanner/ ~/Desktop/accessibility_results/`

**What this produces for thesis:** Actual contrast ratio numbers, tap target size measurements, semantic label audit — all from a Google-published tool, directly citeable.

---

### Track 4 — Proxyman (API network timing from Mac side) ⬅ OPTIONAL

Proxyman not installed. User gave permission to download.

**Download:** proxyman.io → Download for macOS (free)  
**Install certificate on Android:** Proxyman has built-in Android setup guide  
**Note:** Requires modifying `android/app/src/main/res/xml/network_security_config.xml` to trust user certificates in debug builds.

This is OPTIONAL — Edge Function timing logs (Track 2) are sufficient for the thesis. Only proceed with Proxyman if you want client-side end-to-end timing (Flutter → Edge Function → HuggingFace) in addition to server-side timing.

---

## Pending Minor Items (not blocking)

- [ ] `NEWS_API_KEY` rotation — supervisor said keep as is for now. Rotate after submission.
- [ ] Support contact placeholders in `elder_support_sheet.dart` — update phone/email before go-live
- [ ] Elder management screen — show `pin_plain` display ✅ Already implemented (was stale note)

---

## Device Run Command

```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
cd "/Users/xenonhans/Documents/UG Project - ElderConnect"
flutter run -d R5CWC0CWABR \
  --dart-define=SUPABASE_URL=https://etjgxxhvphitvpvxvafl.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0amd4eGh2cGhpdHZwdnh2YWZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0NDIxMjQsImV4cCI6MjA5MjAxODEyNH0.MPJo73VNQ7-afhtpsca8kytje4CyQ51IXjZZg2MTPSE
```

---

## Supabase Project

- Project ID: `etjgxxhvphitvpvxvafl`
- Region: ap-southeast-2 (Sydney)
- Status: ACTIVE_HEALTHY
- All 8 Edge Functions: ACTIVE
- All migrations (001a → 007): Applied

---

## Critical Notes (never change these)

- `flutter analyze` must pass with 0 errors/warnings after every code change
- Never suggest MongoDB — Supabase (PostgreSQL) is the confirmed stack
- Elder PIN is bcrypt-hashed — never stored plain (except `pin_plain` for caretaker view, stored encrypted)
- API keys never in Flutter client — always proxied via Edge Functions
- Mood analysis only runs if `mood_sharing_consent = true`
- Voice messages are NOT processed by mood detection — audio storage only
- `url_launcher` always uses `LaunchMode.inAppBrowserView`, never `externalApplication`
- HuggingFace model: `j-hartmann/emotion-english-distilroberta-base`
- MOSAIC weights: sentiment 0.40, discrepancy 0.20, social 0.20, adherence 0.20
