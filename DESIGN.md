# ElderConnect — Design System

**Source:** Stitch project "ElderConnect - Design Finalised" (`projects/8009688606630486881`)
**Last updated:** 12 April 2026
**Mode:** Light only | **Roundness:** 8px base | **Spacing scale:** 3

---

## Creative North Star — "The Serene Curator"

The guiding philosophy moves away from the clinical "medical utility" aesthetic. Instead, ElderConnect adopts a **high-end, editorial approach** where accessibility is a premium design choice — not a constraint. The goal is **Quiet Confidence**: the interface recedes so the content can breathe, reducing cognitive load through tonal layering, generous whitespace, and authoritative typography.

---

## 1. Colour Palette

### Brand Overrides (seed colours)
| Role | Hex |
|------|-----|
| Primary | `#006A6A` — Deep Teal |
| Secondary | `#A05900` — Warm Amber |
| Tertiary | `#005F91` — Ocean Blue |
| Neutral | `#5D5E5F` |

### Full Token Set (Material You / Fidelity variant)

#### Primary — Deep Teal
| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#005050` | Main CTAs, key interactive elements |
| `primary_container` | `#006A6A` | CTA gradient end, tinted containers |
| `primary_fixed` | `#A0F0F0` | "Big Action" tile backgrounds |
| `primary_fixed_dim` | `#84D4D3` | Dimmed fixed primary surfaces |
| `on_primary` | `#FFFFFF` | Text/icons on primary |
| `on_primary_container` | `#97E7E6` | Text/icons on primary_container |
| `on_primary_fixed` | `#002020` | Text on primary_fixed |
| `on_primary_fixed_variant` | `#004F4F` | Secondary text on primary_fixed |
| `inverse_primary` | `#84D4D3` | Primary colour on dark surfaces |

#### Secondary — Warm Amber (Human / Connection)
| Token | Hex | Usage |
|-------|-----|-------|
| `secondary` | `#8E4E00` | Human-connection elements (call family, caretaker) |
| `secondary_container` | `#FDA54F` | Secondary buttons — warm, visible |
| `secondary_fixed` | `#FFDCC1` | Fixed secondary surfaces |
| `secondary_fixed_dim` | `#FFB778` | Dimmed secondary surfaces |
| `on_secondary` | `#FFFFFF` | Text/icons on secondary |
| `on_secondary_container` | `#6F3C00` | Text/icons on secondary_container |
| `on_secondary_fixed` | `#2E1500` | Text on secondary_fixed |
| `on_secondary_fixed_variant` | `#6C3A00` | Variant text on secondary_fixed |

#### Tertiary — Ocean Blue (Progress / Status)
| Token | Hex | Usage |
|-------|-----|-------|
| `tertiary` | `#004B74` | Status rings, daily progress indicators |
| `tertiary_container` | `#0E6496` | Tertiary tinted containers |
| `tertiary_fixed` | `#CCE5FF` | Fixed tertiary surfaces |
| `tertiary_fixed_dim` | `#93CCFF` | Dimmed tertiary surfaces |
| `on_tertiary` | `#FFFFFF` | Text/icons on tertiary |
| `on_tertiary_container` | `#BBDDFF` | Text/icons on tertiary_container |
| `on_tertiary_fixed` | `#001D31` | Text on tertiary_fixed |
| `on_tertiary_fixed_variant` | `#004B73` | Variant text on tertiary_fixed |

#### Surface Hierarchy (layered like stacked fine paper)
| Token | Hex | Layer meaning |
|-------|-----|---------------|
| `surface_container_lowest` | `#FFFFFF` | Elevated focus — primary interactive cards |
| `surface_container_low` | `#F4F3F4` | Subtle recess — secondary content areas |
| `surface` / `surface_bright` | `#FAF9FA` | Base layer — app background |
| `background` | `#FAF9FA` | Page background |
| `surface_container` | `#EEEEEE` | Mid-level containers |
| `surface_container_high` | `#E8E8E9` | Deep context — nav bars, persistent footers |
| `surface_container_highest` | `#E3E2E3` | Input field "well" backgrounds |
| `surface_dim` | `#DADADB` | Dimmed/disabled surfaces |
| `surface_variant` | `#E3E2E3` | Alternative surface |
| `surface_tint` | `#006A6A` | Tint overlay |

#### Text & Icons
| Token | Hex | Usage |
|-------|-----|-------|
| `on_surface` / `on_background` | `#1A1C1D` | Primary text — all body copy |
| `on_surface_variant` | `#3E4948` | Secondary text, captions |
| `outline` | `#6E7979` | Subtle dividers (use sparingly — see No-Line Rule) |
| `outline_variant` | `#BEC9C8` | Ghost borders at 15% opacity only |
| `inverse_surface` | `#2F3131` | Dark surface (snackbars, toasts) |
| `inverse_on_surface` | `#F1F0F1` | Text on dark surfaces |

#### Error States
| Token | Hex | Usage |
|-------|-----|-------|
| `error` | `#BA1A1A` | Error text, icons |
| `error_container` | `#FFDAD6` | Error background — fade IN slowly, never shake |
| `on_error` | `#FFFFFF` | Text on error |
| `on_error_container` | `#93000A` | Text on error_container |

---

## 2. Typography

### Font Pairing
| Role | Font | Rationale |
|------|------|-----------|
| Display / Headlines | **Plus Jakarta Sans** | Authoritative, editorial, anchors sections |
| Body / Titles / Labels | **Lexend** | Hyper-legible character shapes, chosen for reading ease |

### Type Scale
| Token | Font | Size | Weight | Line height | Usage |
|-------|------|------|--------|-------------|-------|
| `display-lg` | Plus Jakarta Sans | 3.5rem (56sp) | Bold | 1.1 | Hero moments, welcome screens |
| `display-md` | Plus Jakarta Sans | 2.8rem (45sp) | Bold | 1.15 | Large section headers |
| `headline-lg` | Plus Jakarta Sans | 2rem (32sp) | SemiBold | 1.25 | Section anchors — instant orientation |
| `headline-md` | Plus Jakarta Sans | 1.75rem (28sp) | SemiBold | 1.3 | Screen titles |
| `title-lg` | Lexend | 1.375rem (22sp) | Medium | 1.4 | Card titles, prominent labels |
| `title-md` | Lexend | 1.125rem (18sp) | Medium | 1.45 | Sub-labels, secondary card titles |
| `body-lg` | Lexend | 1rem (16sp) | Regular | 1.6 | Standard reading body — generous line-height prevents line-skipping |
| `body-md` | Lexend | 0.875rem (14sp) | Regular | 1.5 | Supporting body text |
| `label-lg` | Lexend | 0.875rem (14sp) | Medium | 1.4 | Button labels, chips |
| `label-md` | Lexend | 0.75rem (12sp) | Medium | 1.3 | Micro-labels, badges |

> **Minimum enforced:** 16sp everywhere. Body text targets 18sp. Headings minimum 24sp.

### Hierarchy as Identity
The editorial rhythm is created by the **massive contrast** between a `display-md` headline and a `body-lg` paragraph — this feels like a premium magazine, not a medical form.

---

## 3. Elevation & Depth

Depth is conveyed through **tonal layering**, not shadows or borders.

### Layering Principle
Stack surface tiers: place a `surface_container_lowest` card on a `surface_container_low` section. The colour shift alone creates visible lift.

### Shadow (use only for floating elements)
- **FABs / sticky CTAs:** `blur: 32px`, `opacity: 6%`, colour: `on_surface` (`#1A1C1D`)
- Mimics natural ambient light — never harsh digital drop shadows

### Glassmorphism (modals / top bars)
- Surface colour at **80% opacity** + **20px backdrop-blur**
- Allows `primary_fixed` or `secondary_fixed` to bleed through for an "airy" integrated look

### Ghost Border (accessibility fallback only)
- Use `outline_variant` (`#BEC9C8`) at **15% opacity**
- Only when accessibility testing requires a visible container boundary
- Never use 100% opaque borders

---

## 4. Shape & Spacing

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| Default cards/containers | `8px` | Standard radius |
| Buttons (primary) | `1.5rem (24px)` — `xl` | Large rounded CTAs |
| Chips / status indicators | `9999px` — full pill | Friendly, "pebble-like" feel |
| Section tiles | `16px` | Home screen action tiles |

### Spacing Scale (scale: 3)
| Token | Value |
|-------|-------|
| xs | 4dp |
| sm | 8dp |
| md | 16dp |
| lg | 24dp |
| xl | 32dp |
| xxl | 48dp |

### Tap Targets
**Minimum: 56×56dp** (surpasses WCAG 48dp standard — accommodates reduced dexterity)

---

## 5. Component Rules

### Buttons
| Type | Background | Text colour | Style |
|------|-----------|-------------|-------|
| Primary CTA | Gradient `primary` → `primary_container` | `on_primary` (`#FFF`) | `xl` radius, gradient gives tactile "soul" |
| Secondary | `secondary_container` (`#FDA54F`) | `on_secondary_container` (`#6F3C00`) | Warm amber — human/connection actions |

### Cards & Lists
- **No divider lines.** Ever.
- Separate list items with **16dp vertical whitespace** OR alternating `surface` / `surface_container_low` backgrounds
- Card background: `surface_container_lowest` (`#FFFFFF`) on `surface_container_low` base

### Input Fields
- Background: `surface_container_highest` (`#E3E2E3`) — creates a "well" effect
- Active state: **2px `primary` bottom bar** (not a full-box stroke)
- Always pair a visible label above the field — never placeholder text alone

### Care-Specific Components
| Component | Style |
|-----------|-------|
| "Big Action" Tile | Large `xl`-radius card, `primary_fixed` (`#A0F0F0`) background, used for high-frequency actions (Medication Log, Social Feed) |
| Status Rings | Thick stroke (4dp+), `tertiary` (`#004B74`) colour, circular daily progress indicators |
| Emergency Button | `secondary` amber — signals warmth/safety, not clinical red |

---

## 6. The No-Line Rule

**Explicit prohibition:** 1px solid borders to section content are forbidden. They feel clinical and restrictive. Content boundaries are defined solely through **background colour shifts**. Example: a `surface_container_low` section on a `surface` background — the tonal shift is all the boundary needed.

---

## 7. Animation & Motion

| Rule | Spec |
|------|------|
| Max duration | 300ms |
| Style | Subtle fade + slide — slow, calm transitions |
| Error feedback | Fade slowly into `error_container` — never shake or jitter (startling) |
| Entry animations | Staggered fade + 20dp upward slide, Curves.easeOut |
| Glassmorphism | Instant on scroll — no animation delay |

---

## 8. Accessibility Standards

| Requirement | Standard |
|-------------|----------|
| Contrast (body text) | WCAG AAA minimum — 7:1 ratio |
| Contrast (large text / graphics) | WCAG AA — 3:1 minimum |
| Tap targets | 56×56dp minimum |
| Font sizes | 16sp minimum everywhere; 18sp body default |
| No colour as sole differentiator | Always pair colour with icon + text label |
| Error indication | Colour + text message (never colour alone) |
| "Grey on Grey" | Prohibited — all text on surfaces must meet WCAG AAA |

---

## 9. Do's and Don'ts

### Do
- Use **amber (`secondary`)** for human-connection elements — calls to family/caretaker — it triggers warmth and safety
- Embrace **asymmetry** — offset images with large headlines create editorial feel, reduce banner blindness
- Use **full pill rounding (`9999px`)** for chips and small status indicators — friendly and "pebble-like"
- Stack surface layers to create depth without shadows or borders
- One primary action per screen-fold — avoids cognitive overload

### Don't
- Use `Colors.blue`, raw hex values, or system colours — always use the token names above
- Place "Grey on Grey" — ensure WCAG AAA on all text
- Use shake/jitter animations for errors — slow fade to `error_container` only
- Cram multiple actions in one row
- Use 1px borders to separate content sections
- Use dark mode (light mode only)
- Go below 16sp font size anywhere

---

## 10. Mapping to ElderConnect Code

When implementing this design in Flutter, the existing `ElderColors` and `ElderSpacing` tokens in `lib/core/constants/` should be updated to align with this palette. Key mappings:

| DESIGN.md token | Flutter constant to update |
|----------------|---------------------------|
| `primary` `#005050` | `ElderColors.socialBlue` → rename or supplement |
| `secondary_container` `#FDA54F` | New token — warm amber for human actions |
| `tertiary` `#004B74` | New token — status rings |
| `surface` `#FAF9FA` | `ElderColors.backgroundWarm` — close match |
| `surface_container_lowest` `#FFFFFF` | `ElderColors.cardWhite` — exact match |
| `on_surface` `#1A1C1D` | `ElderColors.textPrimary` — close match |
| `on_surface_variant` `#3E4948` | `ElderColors.textSecondary` — update hex |
| `error_container` `#FFDAD6` | New token — error backgrounds |
| `outline_variant` `#BEC9C8` | `ElderColors.divider` — update hex |
| Plus Jakarta Sans | Add to `google_fonts` calls alongside Lexend |
| Lexend | Already `bodyFont` — confirm `google_fonts` package includes it |

---

## Elder PIN Login Screen (Fallback Only)

Purpose: Rare fallback when session expires or app is reinstalled. Not a daily interaction.

### Layout
- App logo + name, top centre
- Heading: "Welcome back!" (display-md, Plus Jakarta Sans)
- Subtitle: "Enter your PIN to continue. Need help? Ask your caretaker." (body-lg, Lexend)
- 4 PIN dot indicators — large, centred, fill on digit entry (`primary` colour filled, `outline_variant` empty)
- Custom numpad — 3×4 grid
  - Digits 1–9, backspace, 0, confirm
  - Each button: minimum 72×72dp
  - Style: `surface_container_lowest` background, `on_surface` text, 16px radius
  - Confirm button: primary CTA style
- "Need help?" text link at bottom — `secondary` colour, body-md
- No keyboard, no email, no password field

### Caretaker-Side Additions (Elder Tab)
- "Set PIN" field when registering elder — 4-digit input, numeric only
- "Reset PIN" button in elder management — generates new PIN, caretaker communicates to elder directly
