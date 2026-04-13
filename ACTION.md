# ElderConnect — Stitch → Flutter Translation Action Plan

## What This File Is
Active working document for the screen-by-screen translation of Stitch HTML designs
into Flutter Dart files. Read this at the start of any session to resume exactly where
we left off. Update the status column after each screen is approved and written.

---

## Core Rules (apply to every screen, no exceptions)

| Rule | Requirement |
|------|-------------|
| Colours | `ElderColors.*` tokens only — no hardcoded hex |
| Spacing | `ElderSpacing.*` constants only — no hardcoded numbers |
| Font size | 16sp minimum everywhere — no exceptions without explicit comment |
| Border radius | `BoxShape.circle` / `BorderRadius.circular()` matching HTML `rounded-*` |
| Borders | No 1px content-section borders — tonal shift only |
| Animations | ≤ 300ms total |
| Logic/routing | Do NOT touch — visual changes only |
| Design priority | **Stitch HTML design takes priority over CLAUDE.md** for layout decisions. If they conflict, follow Stitch and flag CLAUDE.md for update. |
| Prototype chrome | Ignore top app bars and bottom navs that appear on ALL Stitch screens as preview frame — only include if that screen actually owns the nav |
| Accessibility | Append audit block to every file |
| Approval | Show diff + proposed code → wait for approval → then write |

---

## Workflow (same for every screen)

1. Read `stitch_elderconnect_design_finalised/<folder>/code.html`
2. View `stitch_elderconnect_design_finalised/<folder>/screen.png` as visual reference
3. Extract all visual properties from the HTML
4. Compare against existing Dart file (or plan the full translation if new)
5. List every visual difference clearly
6. Show proposed code — **wait for approval**
7. Write file(s) only after explicit approval
8. Update status in this file to ✅

---

## Key File Paths

| What | Path |
|------|------|
| Colour tokens | `lib/core/constants/elder_colors.dart` |
| Spacing tokens | `lib/core/constants/elder_spacing.dart` |
| Shared widgets | `lib/shared/widgets/` |
| Router / routes | `lib/app.dart` |
| Stitch designs | `stitch_elderconnect_design_finalised/<folder>/code.html + screen.png` |

---

## Shared Widget Changes Log
Track any changes made to shared widgets so their impact is visible.

| Widget | Change | Affected Screens |
|--------|--------|-----------------|
| `elder_input.dart` | Added `labelColor` param (default: `onSurface`) | elder_registration uses `primary` |

---

## Screen Status

### Batch 1 — Auth Flow

| # | Screen | Stitch Folder | Dart File | Status |
|---|--------|--------------|-----------|--------|
| 1 | Splash Screen | `splash_screen` | `auth/screens/splash_screen.dart` | ✅ Done |
| 2 | Role Selection | `role_selection` | `auth/screens/role_selection_screen.dart` | ✅ Done |
| 3 | Elder Registration | `elder_registration` | `auth/screens/elder_registration_screen.dart` | ✅ Done |
| 4 | Interest Selection | `updated_interest_selection` | `auth/screens/interest_selection_screen.dart` | ✅ Done |
| 5 | Post-Registration Options | `post_registration_options` | `auth/screens/post_registration_options_screen.dart` | ✅ Done |
| 6 | Caretaker Registration | `caretaker_registration` | `auth/screens/caretaker_registration_screen.dart` | ✅ Done |
| 7 | Caretaker Login | `caretaker_login` | `auth/screens/caretaker_login_screen.dart` | ✅ Done |
| 8 | Elder PIN Login | `elder_pin_login_high_visibility` | `auth/screens/elder_pin_login_screen.dart` | ✅ Done |

### Batch 2 — Elder Portal Core

| # | Screen | Stitch Folder | Dart File | Status |
|---|--------|--------------|-----------|--------|
| 9 | Elder Home | `elder_home_screen` | `elderly/screens/elder_home_screen.dart` | ⬜ Pending |
| 10 | Elder Feed | `elder_feed_screen` | `social/screens/elder_feed_screen.dart` | ⬜ Pending |
| 11 | Elder Medication (list) | `elder_medication_screen_1` | `medications/screens/elder_medication_list_screen.dart` | ⬜ Pending |
| 12 | Elder Medication (detail) | `elder_medication_screen_2` | `medications/screens/elder_medication_detail_screen.dart` | ⬜ Pending |
| 13 | Elder Games | `elder_games_screen` | `wellness/screens/elder_games_screen.dart` | ⬜ Pending |
| 14 | Elder Profile | `elder_profile` | `elderly/screens/elder_profile_screen.dart` | ⬜ Pending |

### Batch 3 — Caretaker Portal

| # | Screen | Stitch Folder | Dart File | Status |
|---|--------|--------------|-----------|--------|
| 15 | Caretaker Dashboard | `caretaker_dashboard` | `caretaker/screens/caretaker_dashboard_screen.dart` | ⬜ Pending |
| 16 | Elder Management | `elder_management` | `caretaker/screens/elder_management_screen.dart` | ⬜ Pending |
| 17 | Manage Links | `manage_links` | `caretaker/screens/manage_links_screen.dart` | ⬜ Pending |
| 18 | Search / Link Elder | `search_link_elder` | `caretaker/screens/search_link_elder_screen.dart` | ⬜ Pending |
| 19 | Mood Activity Logs | `mood_activity_logs` | `caretaker/screens/mood_activity_logs_screen.dart` | ⬜ Pending |

### Batch 4 — Remaining

| # | Screen | Stitch Folder | Dart File | Status |
|---|--------|--------------|-----------|--------|
| 20 | Post Game Score | `post_game_score` | `wellness/screens/post_game_score_screen.dart` | ⬜ Pending |
| 21 | Elder Login Fallback | `elder_login_fallback` | `auth/screens/elder_login_fallback_screen.dart` | ⬜ Pending |

---

## Known Design Decisions (overrides / clarifications)

| Decision | Detail |
|----------|--------|
| Elder home nav | Stitch design uses **bottom nav bar with 3 tabs (Home, Feed, Games)** — NOT the 5-tile icon grid in CLAUDE.md. CLAUDE.md must be updated before building this screen. |
| PIN login variant | Use `elder_pin_login_high_visibility` — most accessible for elderly users. |
| Interest selection | Use `updated_interest_selection` folder (newer version). |
| Prototype chrome | Top app bar + bottom nav visible in Stitch previews are the design tool's preview shell — only include if the screen actually owns that nav element. |
| ElderInput bg | DESIGN.md specifies `surfaceContainerHighest` (grey well). Some Stitch screens use white (`surfaceContainerLowest`). Follow Stitch per design priority rule. |

---

## Router Status (lib/app.dart)
New screen files need registering here. Confirm with user before touching routes.

| Route | Screen | Status |
|-------|--------|--------|
| `/` | SplashScreen | ✅ Registered |
| `/role-selection` | RoleSelectionScreen | ✅ Registered |
| `/register/elder` | ElderRegistrationScreen | ✅ Registered |
| `/interest-selection` | InterestSelectionScreen | ✅ Registered |
| `/register/caretaker` | CaretakerRegistrationScreen | ⬜ Placeholder — needs real screen |
| `/home/elder` | ElderHomeScreen | ⬜ Placeholder — needs real screen |
| (all others) | — | ⬜ Not yet added |

---

## How to Resume After /clear

1. Open Claude Code in the project directory
2. Say: **"Read ACTION.md, CLAUDE.md, and DESIGN.md then continue the Stitch translation from where we left off"**
3. Claude will pick up from the next ⬜ screen in Batch 1
