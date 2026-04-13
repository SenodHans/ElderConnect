# Design System Specification: Editorial Accessibility

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Serene Curator."** 

We are moving away from the "medical/utility" aesthetic often forced upon elderly users. Instead, we are adopting a high-end, editorial approach that treats accessibility not as a constraint, but as a premium design choice. This system breaks the "template" look by using intentional white space as a structural element, rather than a void. By utilizing sophisticated tonal layering and authoritative, large-scale typography, we create an environment that feels prestigious, calm, and effortlessly navigable.

The goal is to provide a sense of "Quiet Confidence"—where the interface recedes to let the content shine, reducing cognitive load through a harmonious, non-linear layout that guides the eye with soft transitions rather than rigid grids.

---

## 2. Colors: The Tonal Landscape
Our palette is a sophisticated blend of deep teals (`primary`), sun-drenched ambers (`secondary`), and crisp, clean surfaces. 

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section off content. Traditional "boxes" feel clinical and restrictive. Boundaries must be defined solely through background color shifts. For example, a `surface-container-low` section sitting on a `surface` background provides all the definition needed without the visual "noise" of a line.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine, heavy-weight paper.
*   **Base:** `surface` (#faf9fa)
*   **Subtle Recess:** `surface-container-low` (#f4f3f4) for secondary content areas.
*   **Elevated Focus:** `surface-container-lowest` (#ffffff) for primary interactive cards.
*   **Deep Context:** `surface-container-high` (#e8e8e9) for navigation bars or persistent footers.

### The "Glass & Gradient" Rule
To elevate the experience, use **Glassmorphism** for floating elements (like top bars or sticky actions). Apply a `surface` color at 80% opacity with a 20px backdrop-blur. 
**Signature Textures:** Use subtle linear gradients for primary CTAs, transitioning from `primary` (#005050) to `primary_container` (#006a6a). This adds a "soul" to the button that flat color cannot achieve, making it feel tactile and premium.

---

## 3. Typography: Authoritative Clarity
We pair **Plus Jakarta Sans** (Display/Headlines) with **Lexend** (Body/Labels) to balance editorial sophistication with maximum legibility.

*   **Display (Plus Jakarta Sans):** Large, bold, and intentional. `display-lg` (3.5rem) should be used for hero moments, welcoming the user with warmth.
*   **Headlines (Plus Jakarta Sans):** Used to anchor sections. `headline-lg` (2rem) ensures even those with visual impairments can orient themselves instantly.
*   **Body & Titles (Lexend):** Chosen for its hyper-legible, hyper-modern character shapes. `body-lg` (1rem) is our standard for reading, with a generous `1.6` line-height to prevent "line-skipping" during reading.
*   **Hierarchy as Identity:** The massive contrast between a `display-md` headline and a `body-lg` paragraph creates an editorial rhythm that feels like a premium magazine, not a medical app.

---

## 4. Elevation & Depth: Tonal Layering
We convey importance through depth and light, not lines.

*   **The Layering Principle:** Depth is achieved by "stacking" surface tiers. Place a `surface-container-lowest` card on a `surface-container-low` section to create a soft, natural lift.
*   **Ambient Shadows:** If a floating effect is required (e.g., for a "Call Caretaker" FAB), use an extra-diffused shadow: `blur: 32px`, `opacity: 6%`, colored with `on-surface` (#1a1c1d). This mimics natural light rather than a harsh digital drop shadow.
*   **The "Ghost Border" Fallback:** If accessibility testing requires a container boundary, use a "Ghost Border": the `outline_variant` (#bec9c8) at **15% opacity**. Never use 100% opaque borders.
*   **Glassmorphism:** Use semi-transparent layers for modals. This allows the `primary_fixed` or `secondary_fixed` background colors to bleed through, making the layout feel integrated and "airy" rather than heavy.

---

## 5. Components: Tactile & Generous
All components must honor a **minimum tap target of 56x56dp** (surpassing the 48dp standard) to accommodate users with reduced dexterity.

*   **Buttons:** 
    *   *Primary:* `primary` background with `on_primary` text. Uses `xl` (1.5rem) corner radius.
    *   *Secondary:* `secondary_container` with `on_secondary_container` text. Highly visible, warm amber.
*   **Cards & Lists:** **Strictly forbid divider lines.** Separate list items using `16px` of vertical white space or by alternating background colors between `surface` and `surface-container-low`.
*   **Input Fields:** Use `surface_container_highest` for the field background to create a "well" effect. The active state should use a 2px `primary` bottom-bar rather than a full-box stroke.
*   **Care-Specific Components:**
    *   *The "Big Action" Tile:* A large, `xl` rounded card using `primary_fixed` background for high-frequency actions (e.g., "Medication Log").
    *   *Status Rings:* Use thick-stroke (4px+) circular indicators using `tertiary` (#004b74) to show daily progress.

---

## 6. Do's and Don'ts

### Do:
*   **Do** use `secondary` (Amber) for critical "Human" elements—buttons to call family or caretakers—as it triggers feelings of warmth and safety.
*   **Do** embrace asymmetry. An image offset to the right with a large `headline-lg` on the left creates an editorial feel that reduces "banner blindness."
*   **Do** use `9999px` (full) rounding for chips and small status indicators to make them feel friendly and "pebble-like."

### Don't:
*   **Don't** use "Grey on Grey." Ensure all text on surfaces meets WCAG AAA standards (minimum 7:1 ratio for body text).
*   **Don't** use "Shake" or "Jitter" animations for errors. Use slow, fading transitions to `error_container` (#ffdad6) to avoid startling the user.
*   **Don't** cram multiple actions into one row. One primary action per "screen-fold" is the standard for avoiding cognitive overload.