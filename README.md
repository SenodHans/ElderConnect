# ElderConnect

**Developing a Social Engagement and Wellness Platform Using Artificial Intelligence for Elderly People**

> Final Year Undergraduate Project — BSc (Hons) Computer Science  
> Student: Senod Hansindu Weerathunga (ID: 2433323)  
> University of Bedfordshire (delivered via SLIIT City University, Colombo, Sri Lanka)  
> Supervisor: Ms. Dilushinie Fernando | Deadline: April 2026

---

## Overview

ElderConnect is a cross-platform mobile application targeting elderly users aged 60 and above. It provides an all-in-one platform combining social connection, AI-powered mood detection, personalised news, health management, and a caretaker monitoring dashboard — all within a single app built with an elderly-first accessible design philosophy.

### Why ElderConnect?

No existing app combines social interaction + emotional AI monitoring + health management in a design genuinely built for elderly users. Inspired by the developer's grandmother, who was excluded from the digital world due to poor app design.

| App | Social | AI Mood | Health/Meds | Elderly-first UI |
|---|---|---|---|---|
| Facebook | ✅ | ❌ | ❌ | ❌ |
| WhatsApp | Partial | ❌ | ❌ | ❌ |
| GrandPad | ✅ | ❌ | ❌ | ✅ (proprietary hardware) |
| Medisafe | ❌ | ❌ | ✅ | ❌ |
| **ElderConnect** | **✅** | **✅** | **✅** | **✅** |

---

## Features

### Elderly User Portal
- **Simplified Registration** — colour-coded, voice-guided, caretaker-led setup
- **Interest Selection** — feeds personalised content (news, hobbies, sports)
- **Social Feed** — share posts, photos, and greetings with friends and family
- **AI Mood Detection (MOSAIC)** — post text analysed via Hugging Face API; mood logged with consent
- **Personalised News Feed** — filtered by interest tags and mood signal
- **Text-to-Speech** — reads feed content aloud for visually impaired users
- **Talk Button** — send and receive voice messages (audio only; not AI-processed)
- **Wellness Section** — memory games, breathing exercises, relaxation activities
- **Medication Reminders** — visual + voice notifications with YES/NO confirmation
- **Emergency Contact Button** — one-tap emergency dial, always accessible

### Caretaker Portal
- **Medication Management** — set pill name, colour, dosage, and reminder schedules
- **Mood Monitoring** — 7-day mood history chart (consent-gated)
- **Activity Dashboard** — app engagement, game scores, post counts
- **Alert System** — FCM push alerts for missed medication or declining mood trends

---

## AI — MOSAIC Mood Intelligence Engine

**Multi-signal Observation of Sentiment and Affect with Intelligent Caretaker alerts**

MOSAIC fuses four behavioural signals into a weighted daily composite score, then applies longitudinal trend analysis over a rolling 7-day window.

| Signal | Source | Weight |
|--------|--------|--------|
| Text Sentiment (HuggingFace) | Social posts | 40% |
| Self-Report Discrepancy | Emoji vs AI inference gap | 20% |
| Social Activity | Post and interaction count | 20% |
| Routine Adherence | Medication completion rate | 20% |

**Model:** `j-hartmann/emotion-english-distilroberta-base` (7-class emotion classification)  
**Trend detection:** Linear regression over 7-day rolling window  
**Alerts:** STABLE / WARNING (3+ days declining) / URGENT (5+ days or sharp crash)

---

## Tech Stack

| Component | Technology |
|---|---|
| Frontend | Flutter (Dart) — Android + iOS |
| Database | Supabase (PostgreSQL) with RLS |
| Authentication | Supabase Auth (JWT) |
| Realtime | Supabase Realtime (pub/sub) |
| Server-side Logic | Supabase Edge Functions (Deno/TypeScript) |
| Mood Detection AI | Hugging Face Inference API |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| News/Content | NewsAPI.org |
| State Management | Riverpod 2.x |

---

## Project Structure

```
lib/
├── main.dart
├── app.dart                        # GoRouter setup, auth guard, role-based routing
├── firebase_options.dart
├── core/
│   ├── constants/
│   │   ├── elder_colors.dart       # Design token colour palette
│   │   └── elder_spacing.dart      # Spacing constants
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── auth/                       # Login, PIN screen, registration
│   ├── elderly/                    # Elder home, profile screens
│   ├── social/                     # Feed, posts, reactions
│   ├── news/                       # Personalised news feed
│   ├── mood/                       # Mood detection, MOSAIC
│   ├── wellness/                   # Games, breathing exercises
│   ├── medications/                # Reminders, medication logs
│   ├── emergency/                  # Emergency contact screen
│   └── caretaker/                  # Caretaker dashboard, mood chart, medication mgmt
└── shared/
    ├── widgets/                    # Reusable: ElderButton, ElderCard, ElderInput, etc.
    ├── models/
    └── services/
supabase/
├── functions/                      # Edge Functions (Deno/TypeScript)
└── migrations/                     # SQL migration files
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart 3.x
- Android Studio or Xcode (for device targets)
- A Supabase project (see configuration below)
- Firebase project with FCM enabled

### Environment Variables

This project uses `--dart-define` flags. **Never hardcode keys in source.**

```bash
flutter run \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

Or configure in `.vscode/launch.json`:

```json
{
  "configurations": [
    {
      "name": "ElderConnect",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=SUPABASE_URL=...",
        "--dart-define=SUPABASE_ANON_KEY=..."
      ]
    }
  ]
}
```

### Build APK (Release)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### Install to Device (via ADB)

```bash
adb -s <device_id> install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## Supabase Schema

### Core Tables

| Table | Purpose |
|---|---|
| `users` | Unified user table (elderly + caretaker), role-based |
| `caretaker_links` | Many-to-many caretaker ↔ elder relationships |
| `posts` | Social feed posts |
| `mood_logs` | AI sentiment results, composite scores |
| `medications` | Medication schedules created by caretakers |
| `medication_logs` | Taken/missed records per reminder |
| `alert_states` | MOSAIC alert level per elder (stable/warning/urgent) |
| `wellness_logs` | Game scores and wellness activity records |
| `fcm_tokens` | Device tokens for push notification delivery |

### Edge Functions

| Function | Trigger | Purpose |
|---|---|---|
| `create-elder-account` | Caretaker action | Creates elder Supabase Auth account server-side using service role |
| `mood-detection-proxy` | Post submission | Proxies HuggingFace API call — keeps API key off client |
| `compute-mood-alert` | After mood log | Evaluates alert state and fires FCM if needed |
| `send-medication-reminder` | Cron (scheduled) | Checks pending reminders and triggers FCM |

---

## Authentication Architecture

### Elder Auth (PIN-only)
1. Caretaker registers elder during onboarding (elder is passive)
2. Edge Function creates Supabase Auth account with system-generated UUID password
3. OTP confirmed on caretaker's device
4. Caretaker sets a 4-digit PIN (bcrypt-hashed, stored in `users.pin_hash`)
5. Credentials stored in `flutter_secure_storage` on elder's device
6. Daily use: session auto-restored — elder never sees a login screen

### Caretaker Auth
- Standard email + password via Supabase Auth

---

## Accessibility Standards

| Requirement | Standard |
|---|---|
| Minimum tap target | 48 × 48 logical pixels |
| Minimum font size | 16sp |
| Body text | 18sp |
| Button label | 20sp bold |
| Colour contrast | WCAG 2.1 AA (4.5:1 normal, 3:1 large text) |
| Theme | Light mode only |
| TTS support | flutter_tts on all feed content |

---

## Testing

```bash
# Run all tests
flutter test

# Run integration tests (device required)
flutter test integration_test/app_test.dart -d <device_id>
```

**Test coverage:** 127/127 automated tests passing  
Unit tests · Widget tests · Integration tests · Accessibility audit

---

## Design System

See [DESIGN.md](DESIGN.md) for the full design token reference including:
- `ElderColors.*` colour palette
- `ElderSpacing.*` spacing constants
- Typography scale
- Component specs (`ElderButton`, `ElderCard`, `ElderInput`, etc.)
- Elevation and shadow rules
- Animation guidelines

---

## Research Foundation

Primary research conducted with:
- **52 elderly respondents** (46.2% needed assistance completing a printed questionnaire)
- **13 caretaker respondents** (online)

Key findings:
- 73.1% face difficulty with small text
- 84.6% want large buttons and clear text
- 82.7% see value in AI mood detection
- 92.3% of caretakers find a digital monitoring dashboard helpful

---

## Academic Context

This is a final year BSc Computer Science project submitted for academic assessment and viva defence. A parallel IEEE conference paper documents the six-layer system architecture with Ms. Dilushinie Fernando as second author.

> **Note:** The Contextual Report (submitted document) references MongoDB as the original planned technology. The actual implementation uses **Supabase (PostgreSQL)**. Supabase is the correct and current technology.

---

## Licence

This project is submitted as an academic work. All rights reserved by the author.  
© 2026 Senod Hansindu Weerathunga
