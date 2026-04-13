# Design System Document: The Empathetic Architect

## 1. Overview & Creative North Star
**Creative North Star: "The Clinical Sanctuary"**

This design system moves away from the sterile, rigid grids of traditional medical software and instead adopts the philosophy of "The Clinical Sanctuary." For a caretaker, information is heavy; the interface should feel light. We achieve this through **Editorial Precision**—using high-contrast typographic scales and intentional white space to guide the eye, rather than boxes and lines.

The system breaks the "template" look by utilizing **Tonal Depth** and **Asymmetric Balance**. By shifting from a flat, bordered layout to a layered, tonal environment, we create a portal that feels professional and authoritative yet remains human and calm.

---

## 2. Colors & Surface Philosophy
The palette is rooted in deep, professional indigos (`primary`) and muted slate tones (`secondary`), designed to instill a sense of calm reliability.

### The "No-Line" Rule
**Strict Mandate:** Designers are prohibited from using 1px solid borders to define sections or containers. 
Structure must be achieved through:
- **Tonal Shifts:** Placing a `surface_container_low` card against a `surface` background.
- **Negative Space:** Using the spacing scale to create clear mental groupings.
- **Soft Shadows:** Using ambient light rather than structural lines.

### Surface Hierarchy & Nesting
Treat the UI as a physical desk of organized, high-quality stationery.
- **Base Layer:** `surface` (#f8fafb) – The foundational canvas.
- **Sectional Layer:** `surface_container_low` (#f2f4f5) – To group related modules.
- **Active Layer:** `surface_container_lowest` (#ffffff) – For interactive cards or primary content focal points.

### The "Glass & Gradient" Rule
To elevate the "clinical" feel into something "premium," use subtle glassmorphism for floating elements (like top navigation or status badges).
- Use `surface` at 80% opacity with a `24px` backdrop-blur.
- **Signature Texture:** For primary CTAs or critical summary headers, apply a subtle linear gradient from `primary` (#00364c) to `primary_container` (#1a4d66) at a 135-degree angle. This adds "soul" and depth to otherwise flat interactive elements.

---

## 3. Typography: Editorial Authority
We utilize **Plus Jakarta Sans** for its geometric clarity and modern warmth. The hierarchy is designed to be scanned quickly under high-stress conditions.

*   **Display & Headlines:** Use `headline-sm` (1.5rem) for main page titles. The tight tracking and generous leading convey a sophisticated, editorial tone.
*   **The "Contextual Title":** Use `title-sm` (1rem) in `secondary` (#4a626d) for metadata or section headers to keep the interface from feeling "loud."
*   **Body Copy:** `body-md` (0.875rem) is the workhorse. It provides a high information density without sacrificing legibility for the caretaker.
*   **Labeling:** `label-md` (0.75rem) should always be in `on_surface_variant` (#41484d) to ensure a clear distinction between "data" and "label."

---

## 4. Elevation & Depth: Tonal Layering
Traditional shadows and borders create visual noise. This system uses **Tonal Layering** to communicate hierarchy.

*   **The Layering Principle:** To lift a component, don't reach for a shadow; reach for a lighter surface token. A white `surface_container_lowest` card sitting on a `surface_container_low` background creates a natural, soft lift.
*   **Ambient Shadows:** When an element must float (e.g., a modal or a floating action menu), use a shadow tinted with the `on_surface` color: 
    *   *Blur:* 32px | *Spread:* -4px | *Opacity:* 6% | *Color:* #191c1d.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility (e.g., in high-contrast modes), use the `outline_variant` (#c1c7cd) at **15% opacity**. Never use a 100% opaque border.
*   **Glassmorphism:** Use for persistent overlays. It allows the rich `surface` colors to bleed through, making the portal feel like one integrated ecosystem rather than disconnected parts.

---

## 5. Components

### Buttons: The Subtle Trigger
- **Primary:** Gradient fill (`primary` to `primary_container`), white text, `md` (0.375rem) roundedness. No shadow.
- **Secondary:** `surface_container_high` fill with `on_surface` text.
- **Tertiary:** Pure text with `on_primary_fixed_variant` color. 

### Cards & Lists: The No-Divider Rule
- **Forbid dividers.** To separate patient records or logs, use a `16px` vertical gap and a subtle background shift to `surface_container_low` on hover.
- **Information Density:** Use `body-sm` for secondary details to keep the primary data prominent.

### Input Fields: Soft Focus
- **Default State:** `surface_container_highest` background, no border, `sm` (0.125rem) roundedness.
- **Active State:** A "Ghost Border" of `primary` at 40% opacity and a 2px inner glow.

### The "Pulse" Badge (Custom Component)
- For real-time updates or critical patient status, use a small chip with a `tertiary_container` background and `on_tertiary_container` text. Apply a `full` (9999px) roundedness to signify "organic" status.

---

## 6. Do's and Don'ts

### Do:
- **Do** use `surface_container` tiers to create a "nesting doll" effect for complex medical data.
- **Do** lean into `Plus Jakarta Sans` medium weights for labels to ensure they are readable at small sizes.
- **Do** use `tertiary` (#003932) for "Success" or "Stable" states to maintain the calm, indigo-adjacent palette.

### Don't:
- **Don't** use pure black (#000000). Use `on_surface` (#191c1d) for all "black" text.
- **Don't** use 1px dividers to separate list items; use white space or tonal shifts.
- **Don't** use "Alert Red" for anything other than critical errors. Use `secondary` for neutral warnings to keep the caretaker's stress levels low.
- **Don't** use oversized "consumer-web" buttons. Keep button padding tight (12px 20px) to reflect a professional tool.