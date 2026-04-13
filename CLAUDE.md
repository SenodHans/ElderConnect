# ElderConnect — Project Briefing for Claude Code

## Project Identity
- **Title:** ElderConnect: Developing a Social Engagement and Wellness Platform Using Artificial Intelligence for Elderly People
- **Student:** Senod Hansindu Weerathunga (ID: 2433323)
- **Degree:** BSc (Hons) Computer Science — University of Bedfordshire (delivered via SLIIT City University, Colombo, Sri Lanka)
- **Module:** Undergraduate Project (CIS017-3)
- **Supervisor:** Ms. Dilushinie Fernando
- **Deadline:** April 2026
- **Type:** Final year undergraduate project + IEEE conference paper

---

## Personal Motivation
This project was inspired by the student's grandmother, who was excluded from the digital world due to poor app design. The app is built from genuine lived experience of the accessibility gap — not a theoretical exercise.

---

## What This App Is

ElderConnect is a cross-platform mobile application targeting elderly users aged 60 and above. It provides an all-in-one platform combining social connection, AI-powered mood detection, personalised news, health management, and a caretaker monitoring dashboard — all within a single app with an elderly-first accessible design.

The core problem it solves: no existing app combines social interaction + emotional AI monitoring + health management in a design genuinely built for elderly users. Facebook/WhatsApp are too complex. GrandPad requires proprietary hardware. Medisafe handles only medication. Connect2Affect handles only social isolation. ElderConnect addresses all of these together.

### Competitive Analysis (from research)
| App | Social | AI Mood | Health/Meds | Elderly-first UI | Cost |
|---|---|---|---|---|---|
| Facebook | Yes | No | No | No | Free |
| WhatsApp | Partial | No | No | No | Free |
| GrandPad | Yes | No | No | Yes | Proprietary hardware |
| Connect2Affect | Yes | No | No | Partial | Free |
| Medisafe | No | No | Yes | No | Free |
| **ElderConnect** | **Yes** | **Yes** | **Yes** | **Yes** | **Free** |

---

## Primary Research — Survey Data (validates design decisions)

### Elderly Respondents (n=52, printed questionnaires — 46.2% needed assistance completing the form)
- 73.1% face small text difficulties
- 63.5% struggle with typing
- ~70% have limited smartphone confidence
- 73.1% experience loneliness at least sometimes
- 82.7% see value in mood detection
- 71.2% want medication reminders
- 84.6% want big buttons and clear text

### Caretaker Respondents (n=13, online questionnaires)
- 84.6% concerned about emergency situations
- 84.6% find monitoring difficult (yes + sometimes combined)
- 92.3% find a digital dashboard helpful

**Critical design implication:** 46.2% of elderly respondents needed help completing a paper form. This means the app must be designed assuming zero digital literacy — every interaction must be self-explanatory with zero learning curve.

---

## Two Portals — One App

The app has two role-based portals selected at registration. This is NOT two separate apps — it is one Flutter codebase with role-based routing.
```dart
// In app.dart router
if (user.role == 'elderly') → ElderlyShell()
if (user.role == 'caretaker') → CaretakerShell()
```

### Elderly User Portal
- Simplified, colour-coded registration with voice guidance
- Interest selection at signup (news, hobbies, sports) — feeds content personalisation
- Social feed — share posts, photos, greetings with friends/family
- AI Mood Detection — text from posts analysed via Hugging Face API; result logged with consent
- Personalised News Feed — content filtered by interest tags + mood result combined
- Text-to-Speech — for visually impaired users; reads feed content aloud
- Talk Button — send voice messages (audio stored only; NOT processed by mood detection AI)
- Wellness Section — memory games, breathing exercises, relaxation activities
- Medication Reminders — visual + voice notifications triggered server-side
- Emergency Contact Button — prominent, always-visible; one-tap to contact caretaker/family

### Caretaker Portal
- Medication Management — set pill name, colour, dosage, timing schedules
- Mood Monitoring — view mood history chart from AI analysis results (with elderly user's consent)
- Activity Summary — general app usage and engagement tracking
- Receive alerts for missed medication or detected negative mood patterns

---

## Tech Stack

| Component | Technology | Reason |
|---|---|---|
| Frontend | Flutter (Dart) | Cross-platform Android + iOS from one codebase |
| Database | Supabase (PostgreSQL) | Relational model fits caretaker↔user relationship; RLS enforced at DB level |
| Authentication | Supabase Auth (JWT) | Built into Supabase; role-based access |
| Realtime | Supabase Realtime (pub/sub) | Caretaker dashboard live updates |
| Server-side logic | Supabase Edge Functions (Deno/TypeScript) | Cron-triggered medication reminders; API key proxy |
| Mood Detection AI | Hugging Face Inference API | Pre-trained sentiment model; HTTP POST; no custom training |
| Push Notifications | Firebase Cloud Messaging (FCM) | Medication reminders delivered to device |
| News/Content | NewsAPI.org (or similar) | External news feed filtered by interest tags |
| State Management | Riverpod 2.x | Preferred over Provider/Bloc for this project |
| UI Design Reference | Figma | Wireframes and high-fidelity prototypes |
| Version Control | GitHub | |
| IDE | VS Code + Android Studio | |

**IMPORTANT — MongoDB vs Supabase:** The Contextual Report (submitted academic document) references MongoDB — that was the original plan documented before implementation began. The actual implementation uses **Supabase (PostgreSQL)**. Always use Supabase in code. Never suggest MongoDB.

---

## Approved Packages (do not use anything outside this list without flagging first)
```yaml
flutter_riverpod: ^2.x        # State management
google_fonts: ^6.x            # Poppins font
flutter_tts: ^4.x             # Text-to-speech
speech_to_text: ^6.x          # Talk Button voice input
cached_network_image: ^3.x    # Feed images
supabase_flutter: ^2.x        # Backend
firebase_messaging: ^16.x    # FCM push notifications
fl_chart: ^0.x                # Caretaker mood history chart
intl: ^0.x                    # Date formatting
go_router: ^13.x              # Navigation/routing
```

## Installed Skills
- ~/.claude/skills/ui-ux-pro-max/ — 67 UI styles, 161 colour palettes, 
  57 font pairings. Read this before building any screen for visual 
  design decisions. Always map output to ElderColors.* tokens.

## Active Plugins (auto-loaded by Claude Code)
- frontend-design — production-grade UI patterns. Applied automatically.
- code-simplifier — keeps code clean and concise. Applied automatically.
- context7 — fetches live Flutter/Riverpod/Supabase docs. Use before 
  any package-specific API calls.
- superpowers — planning and writing tools.
- figma — Figma file access for design reference.

## Active MCPs (auto-loaded)
- magic — UI component generation. Post-process output to use 
  ElderColors.* and ElderSpacing.* tokens. Never accept raw output.
- stitch — Flutter UI generation. Same rules as magic.
- supabase — live database access. Confirm before any schema changes.
- context7 — live documentation lookup.
- github — version control.


## MCP Tools — When to Use (Non-Negotiable)

### BEFORE any package-specific code → context7
Trigger: Any time you write code using Flutter widgets,
Riverpod, Supabase Flutter SDK, GoRouter, or any 
approved package.
Action: Call context7 FIRST to fetch current docs.
Never rely on training knowledge for package APIs.

Examples that MUST trigger context7:
- Writing a ConsumerWidget or AsyncNotifier
- Using Supabase client methods
- Setting up GoRouter routes
- Using flutter_tts, speech_to_text, fl_chart

### BEFORE building any screen or widget → elderconnect-ui skill
Trigger: Any screen, widget, or component build task.
Action: Read ~/.claude/skills/user/elderconnect-ui/SKILL.md
before writing a single line of UI code.
This contains the design system, colour tokens, 
accessibility rules, and component patterns.
Never build UI without reading this first.

### BEFORE modifying any existing symbol → gitnexus
Trigger: Any edit to an existing function, class, 
widget, or method.
Action: Run gitnexus_impact({target: "symbolName", 
direction: "upstream"}) first.
Report blast radius to user before proceeding.
NEVER edit without running this.

### FOR database operations → supabase MCP
Trigger: Any schema change, migration, or Edge Function
deployment.
Action: Always confirm with user before executing 
against live database. Schema must match CLAUDE.md 
table definitions exactly.

### FOR UI component generation → magic / stitch
Trigger: Only when explicitly asked to use these tools.
Action: Never accept raw output. Always post-process:
1. Replace hardcoded colours with ElderColors.* tokens
2. Replace hardcoded padding with ElderSpacing.* constants
3. Verify font sizes meet 16sp minimum
4. Run accessibility audit before presenting code

### BEFORE committing → gitnexus
Trigger: Every git commit.
Action: Run gitnexus_detect_changes() to verify only
expected symbols changed. Never commit without this.

### FOR version control → github MCP
Trigger: After completing any screen or feature.
Action: Commit with descriptive message referencing
the feature (e.g. "feat: elder home screen UI complete")

---

## UI & Design System

→ Full design tokens, typography, colours, elevation, 
  component rules and accessibility standards are in 
  design.md (project root). Read that file before 
  building any screen.

> For the full colour palette, typography, spacing, shape, elevation, and animation
> rules see **[DESIGN.md](DESIGN.md)**.

### Core Rules
| Rule | Requirement |
|---|---|
| Minimum tap target | 48x48 logical pixels |
| Minimum font size | 16sp — never go below this anywhere |
| Body text | 18sp default |
| Heading text | 24sp minimum |
| Button label text | 20sp bold |
| Colour contrast | WCAG 2.1 AA — 4.5:1 normal text, 3:1 large text |
| Theme | Light mode only — no dark mode |
| Platform priority | iOS-first — SafeArea everywhere, respect MediaQuery padding |

### Elderly Portal Navigation
**Pattern: Icon Grid Home Screen — NOT a bottom navigation bar.**

Home screen shows 5 large icon tiles in a 2+2+1 grid:
1. Social (`ElderColors.primaryFixed`) — top left
2. News (`ElderColors.tertiaryFixed`) — top right
3. Wellness (`ElderColors.primaryFixed`) — middle left
4. Health/Meds (`ElderColors.secondaryFixed`) — middle right
5. Emergency — full width at bottom, always visible (see Emergency Colour Mapping below)

Each tile: minimum 140x140px, icon 48px, label 18sp bold below icon.
Navigation uses `Navigator.push()` with fade/slide transition (250ms). No drawer. No tabs.

### Emergency Colour Mapping (Non-Negotiable)
The old `emergencyRed` token no longer exists. Use these tokens:
- **Emergency Dial button** → `ElderColors.secondaryContainer` (`#FDA54F`) — warm amber signals safety, not alarm
- **SOS button** → `ElderColors.error` (`#BA1A1A`) — reserved for the hard emergency action only

Never use `ElderColors.error` for the general emergency tile background — amber only. `error` is SOS-only.

### Caretaker Portal Navigation
**Pattern: Bottom navigation bar — 4 tabs:**
1. Dashboard
2. Medications
3. Mood History
4. Settings

Accent colour: `ElderColors.tertiary` throughout.

### Reusable Components (never reinvent these)
- `ElderButton` — primary CTA button, full width, 20sp bold, 56px min height, 12px radius
- `ElderCard` — card container, 16px radius, cardWhite bg, soft shadow
- `ElderInput` — text field with visible label above (not just placeholder), 18sp, 48px min height
- `ElderSectionTile` — 140x140px home tile, icon 48px, label 18sp bold, coloured bg
- `ElderAvatar` — circular avatar, 64px default, fallback to initials
- `MoodIndicator` — displays mood label + colour
- `CaretakerStatCard` — caretaker dashboard stat widget

Location: `lib/shared/widgets/`

### Accessibility Audit (append to every generated widget)
// ── ACCESSIBILITY AUDIT ─────────────────────────────
// ✅ or ❌ Tap targets ≥ 48x48px
// ✅ or ❌ Font sizes ≥ 16sp
// ✅ or ❌ Colour contrast WCAG AA
// ✅ or ❌ Semantic labels on icons and images
// ✅ or ❌ No colour as sole differentiator
// ✅ or ❌ Touch targets separated by ≥ 8px spacing
If any item is ❌, fix it before presenting the code.

---

## Code Generation Rules

1. Always use `const` constructors where possible
2. Always name widgets — no anonymous inline widgets for reusable components
3. Always add `Semantics` wrappers on icon buttons and images
4. Always use `ElderColors.*` tokens — never hardcode hex
5. Always use `ElderSpacing.*` constants — never hardcode padding
6. Always use `SafeArea` on all top-level screen widgets
7. Always use `SingleChildScrollView` on screens with more than 3 vertical elements
8. Always use Riverpod — `ConsumerWidget` / `ConsumerStatefulWidget` only
9. Separate UI from logic — screens call providers, providers call services
10. Always write clean, well-commented code (this is graded academic work)

---

## Supabase Architecture

### Database Tables
users

id (uuid, PK)
email
role (enum: 'elderly' | 'caretaker')
full_name
date_of_birth
interests (text[] — e.g. ['news', 'sports', 'hobbies'])
tts_enabled (bool)
mood_sharing_consent (bool)
created_at
pin_hash (text, nullable) — bcrypt hashed 4-digit PIN, set by caretaker. Null until caretaker sets it.

caretaker_links

id (uuid, PK)
caretaker_id (uuid, FK → users)
elderly_user_id (uuid, FK → users)
created_at

posts

id (uuid, PK)
user_id (uuid, FK → users)
content (text)
photo_url (text, nullable)
created_at

mood_logs

id (uuid, PK)
user_id (uuid, FK → users)
label (text — 'POSITIVE' | 'NEGATIVE' | 'NEUTRAL')
score (float)
source_post_id (uuid, FK → posts, nullable)
created_at

medications

id (uuid, PK)
elderly_user_id (uuid, FK → users)
created_by_caretaker_id (uuid, FK → users)
pill_name (text)
pill_colour (text)
dosage (text)
reminder_times (time[])
is_active (bool)
created_at

medication_logs

id (uuid, PK)
medication_id (uuid, FK → medications)
user_id (uuid, FK → users)
scheduled_time (timestamptz)
taken_at (timestamptz, nullable)
status (enum: 'pending' | 'taken' | 'missed')

voice_messages

id (uuid, PK)
sender_id (uuid, FK → users)
audio_url (text)
created_at
-- NOTE: Voice messages are NOT processed by mood detection AI


### Row Level Security Rules
- Users can only read/write their own data
- Caretakers can only read data for elderly users they are linked to (via caretaker_links)
- Mood logs visible to caretaker only if mood_sharing_consent = true on elderly user profile
- Medication table: caretaker can insert/update; elderly user can only read their own

### Edge Functions
- `send-medication-reminder` — cron job; checks medication_logs for pending reminders; triggers FCM
- `mood-detection-proxy` — proxies Hugging Face API call so API key never lives in Flutter client

---

## Authentication Flow (Non-Negotiable)

### Elder Auth
- Registration: name only → stored in Supabase users table
- Phone number entered by caretaker, OTP confirmed on caretaker's device — elder never sees OTP
- PIN (4-digit) set by caretaker in Elder tab
- PIN stored as bcrypt hash in users table (never plain text)
- Session persists indefinitely on elder's device
- PIN login screen is fallback only — app deletion or session expiry. Not daily use.
- If PIN forgotten → caretaker resets from Elder tab

### Caretaker Auth
- Registration: full name, email, phone, password
- Login: email + password via Supabase Auth
- Standard Supabase JWT session

### Never Do
- Never prompt elder for OTP
- Never prompt elder for email or password
- Never store PIN as plain text — always bcrypt hash
- Never expire elder session automatically

---

## AI Components

### 1. Mood Detection (Hugging Face)
- **Model:** `distilbert-base-uncased-finetuned-sst-2-english`
- **Trigger:** When elderly user submits a post (NOT on voice messages, NOT on keystrokes)
- **Flow:** Flutter → Supabase Edge Function (proxy) → Hugging Face API → response stored in mood_logs
- **Response format:**
```json
[[{"label": "POSITIVE", "score": 0.9876}, {"label": "NEGATIVE", "score": 0.0124}]]
```
- **Cold start:** Handle 503 with retry after 20 seconds + loading spinner
- **API key:** NEVER hardcode in Flutter — always route through Supabase Edge Function
- **Low confidence:** Default to NEUTRAL rather than forcing a classification
- **This is AI integration, not ML development** — no custom model training

### 2. Content Personalisation
- Fetch news from NewsAPI using interest tags on user profile
- Interest tag filter applied first
- Mood result applied as secondary filter — NEGATIVE mood → prioritise uplifting content

### 3. Ethical Consent for Mood Data (non-negotiable)
- Mood analysis ONLY runs if mood_sharing_consent = true
- Consent collected explicitly at registration with plain language explanation
- Caretaker access to mood logs gated by same consent flag (RLS enforced at DB level)

---

## Sprint Status (as of March 2026)

| Sprint | Focus | Status |
|---|---|---|
| Sprint 1 | Flutter setup, Supabase integration, voice-guided registration + login | COMPLETED |
| Sprint 2 | Social feed, post creation, photo upload, Talk Button | COMPLETED |
| Sprint 3 | Hugging Face API integration, mood detection, mood log storage | IN PROGRESS / DEBUGGING |
| Sprint 4 | Medication reminders (FCM + Edge Functions), wellness games, emergency contact | COMPLETED |
| Sprint 5 | Caretaker portal — dashboard, medication management, mood history chart | IN PROGRESS |
| Sprint 6 | Accessibility pass (running concurrently across all sprints) | ONGOING |

**Accessibility is NOT a final phase — apply WCAG 2.1 AA on every screen as it is built.**

### Confirmed Implemented Screens
- Social Feed (elderly portal)
- Dashboard Selector (role selection screen at login)
- Emergency Contact screen
- Add Medication screen (caretaker portal)
- Caretaker Home Page

### Screen Build Priority for Remaining Work
1. Auth: Splash, Role Selection, Registration (elderly), Registration (caretaker), Login
2. Elderly Home: Icon grid screen
3. Social Feed polish
4. News Feed
5. Mood Detection UI: loading state, result display
6. Wellness: memory game, breathing exercise
7. Medications (elderly): reminder list view
8. Emergency Contact polish
9. Caretaker Dashboard
10. Caretaker Medications management
11. Caretaker Mood History chart
12. Settings / Profile

---

## Folder Structure (Flutter)
lib/
main.dart
app.dart
core/
    constants/
      elder_colors.dart
      elder_spacing.dart
    theme/
      app_theme.dart
    utils/
utils/
features/
auth/
screens/
widgets/
providers/
services/
social/
news/
mood/
wellness/
medications/
emergency/
caretaker/
shared/
widgets/      ← reusable ElderButton, ElderCard, ElderInput etc
models/
services/
supabase/
functions/
send-medication-reminder/
mood-detection-proxy/
migrations/

---

## Out of Scope (do not implement)
- Voice-based sentiment analysis (voice messages are audio storage only)
- Integration with medical devices or wearables
- Real-time video calling
- Multi-language support (English only)
- Integration with external healthcare systems or EHR
- Custom ML model training

---

## Testing Strategy
- **Unit tests:** Login, post creation, medication reminders, mood detection function
- **Integration tests:** Supabase connection, Hugging Face API call, FCM delivery, caretaker data sync
- **System tests:** Full app flow end-to-end
- **UAT:** Actual elderly users — accessibility and navigation without assistance

---

## Project Deliverables
1. Project Proposal — submitted
2. Monthly Progress Reports — submitted
3. Contextual Report — submitted (references MongoDB as original tech choice — ignore, Supabase is correct)
4. Reflective Report — submitted
5. Thesis Report — pending
6. Working app (Flutter, Supabase, FCM, Hugging Face integrated)
7. IEEE conference paper — second author: Ms. Dilushinie Fernando

---

## Key Decisions Already Made (do not reverse)
1. **Supabase over MongoDB** — do not suggest MongoDB
2. **Hugging Face over Google Cloud NLP** — already justified in documents
3. **Single app dual portal** — role-based routing, not separate apps
4. **No custom ML training** — API integration only
5. **Riverpod** — not Provider, not Bloc
6. **API keys via Edge Function proxy** — never hardcoded in Flutter
7. **Accessibility is continuous** — not a final phase

---

## Project Ownership Boundaries

| Area | Owner |
|---|---|
| Flutter UI architecture and screens | Senod (primary ownership) |
| Supabase schema, RLS rules, Edge Functions | Senod (primary ownership) |
| Hugging Face API integration (Dart service layer) | Can be delegated |
| Firebase FCM setup | Can be delegated |
| Caretaker dashboard UI | Can be delegated |

---

## Academic Context
Final year BSc project assessed for grade and viva defence. Code quality, comments, and design decisions matter. Always write clean, well-commented code.

IEEE conference paper in parallel — second author Ms. Dilushinie Fernando. Six-layer system architecture documented in the paper. Code and architecture decisions must be consistent with that documented design.

Literature review spans five areas: Ageing Population & Social Isolation, Elderly Technology Adoption, Accessible Interface Design, AI in Healthcare, Sentiment Analysis. Reference these when explaining design decisions where relevant.

## Code Style
- Keep code simple and readable — prefer clarity over cleverness
- No unnecessary abstractions or over-engineering
- Split files when a single file is doing more than one logical job, not based on line count
- Comments should be meaningful and helpful but no doc comments (///) on every parameter — only on the class itself and non-obvious parameters for code review and viva defence.
- No boilerplate padding — every line should earn its place

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **UG Project - ElderConnect** (539 symbols, 809 relationships, 6 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## When Debugging

1. `gitnexus_query({query: "<error or symptom>"})` — find execution flows related to the issue
2. `gitnexus_context({name: "<suspect function>"})` — see all callers, callees, and process participation
3. `READ gitnexus://repo/UG Project - ElderConnect/process/{processName}` — trace the full execution flow step by step
4. For regressions: `gitnexus_detect_changes({scope: "compare", base_ref: "main"})` — see what your branch changed

## When Refactoring

- **Renaming**: MUST use `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` first. Review the preview — graph edits are safe, text_search edits need manual review. Then run with `dry_run: false`.
- **Extracting/Splitting**: MUST run `gitnexus_context({name: "target"})` to see all incoming/outgoing refs, then `gitnexus_impact({target: "target", direction: "upstream"})` to find all external callers before moving code.
- After any refactor: run `gitnexus_detect_changes({scope: "all"})` to verify only expected files changed.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Tools Quick Reference

| Tool | When to use | Command |
|------|-------------|---------|
| `query` | Find code by concept | `gitnexus_query({query: "auth validation"})` |
| `context` | 360-degree view of one symbol | `gitnexus_context({name: "validateUser"})` |
| `impact` | Blast radius before editing | `gitnexus_impact({target: "X", direction: "upstream"})` |
| `detect_changes` | Pre-commit scope check | `gitnexus_detect_changes({scope: "staged"})` |
| `rename` | Safe multi-file rename | `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` |
| `cypher` | Custom graph queries | `gitnexus_cypher({query: "MATCH ..."})` |

## Impact Risk Levels

| Depth | Meaning | Action |
|-------|---------|--------|
| d=1 | WILL BREAK — direct callers/importers | MUST update these |
| d=2 | LIKELY AFFECTED — indirect deps | Should test |
| d=3 | MAY NEED TESTING — transitive | Test if critical path |

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/UG Project - ElderConnect/context` | Codebase overview, check index freshness |
| `gitnexus://repo/UG Project - ElderConnect/clusters` | All functional areas |
| `gitnexus://repo/UG Project - ElderConnect/processes` | All execution flows |
| `gitnexus://repo/UG Project - ElderConnect/process/{name}` | Step-by-step execution trace |

## Self-Check Before Finishing

Before completing any code modification task, verify:
1. `gitnexus_impact` was run for all modified symbols
2. No HIGH/CRITICAL risk warnings were ignored
3. `gitnexus_detect_changes()` confirms changes match expected scope
4. All d=1 (WILL BREAK) dependents were updated

## Keeping the Index Fresh

After committing code changes, the GitNexus index becomes stale. Re-run analyze to update it:

```bash
npx gitnexus analyze
```

If the index previously included embeddings, preserve them by adding `--embeddings`:

```bash
npx gitnexus analyze --embeddings
```

To check whether embeddings exist, inspect `.gitnexus/meta.json` — the `stats.embeddings` field shows the count (0 means no embeddings). **Running analyze without `--embeddings` will delete any previously generated embeddings.**

> Claude Code users: A PostToolUse hook handles this automatically after `git commit` and `git merge`.

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
