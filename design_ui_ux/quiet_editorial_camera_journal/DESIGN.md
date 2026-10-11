---
name: Quiet Editorial Camera & Journal
colors:
  surface: '#f9f9f6'
  surface-dim: '#dadad7'
  surface-bright: '#f9f9f6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f4f1'
  surface-container: '#eeeeeb'
  surface-container-high: '#e8e8e5'
  surface-container-highest: '#e2e3e0'
  on-surface: '#1a1c1b'
  on-surface-variant: '#464741'
  inverse-surface: '#2f312f'
  inverse-on-surface: '#f1f1ee'
  outline: '#777771'
  outline-variant: '#c7c7bf'
  surface-tint: '#5f5e5c'
  primary: '#020302'
  on-primary: '#ffffff'
  primary-container: '#1d1d1b'
  on-primary-container: '#868582'
  inverse-primary: '#c8c6c3'
  secondary: '#6e5a4b'
  on-secondary: '#ffffff'
  secondary-container: '#f9ddca'
  on-secondary-container: '#756051'
  tertiary: '#040301'
  on-tertiary: '#ffffff'
  tertiary-container: '#1f1d19'
  on-tertiary-container: '#89847e'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5e2de'
  primary-fixed-dim: '#c8c6c3'
  on-primary-fixed: '#1c1c1a'
  on-primary-fixed-variant: '#474744'
  secondary-fixed: '#f9ddca'
  secondary-fixed-dim: '#dcc2af'
  on-secondary-fixed: '#27190d'
  on-secondary-fixed-variant: '#554335'
  tertiary-fixed: '#e8e2da'
  tertiary-fixed-dim: '#cbc6bf'
  on-tertiary-fixed: '#1d1b17'
  on-tertiary-fixed-variant: '#494641'
  background: '#f9f9f6'
  on-background: '#1a1c1b'
  surface-variant: '#e2e3e0'
typography:
  display-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 40px
    fontWeight: '500'
    lineHeight: 48px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Be Vietnam Pro
    fontSize: 30px
    fontWeight: '500'
    lineHeight: 38px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Be Vietnam Pro
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.005em
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
    letterSpacing: 0em
  body-md:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.04em
  label-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.06em
  technical-data:
    fontFamily: Be Vietnam Pro
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.08em
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  gutter-desktop: 2.5rem
  margin: 1.25rem
  margin-tablet: 2.5rem
  margin-desktop: 4rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
  space-xxl: 4rem
---

## Brand & Style

The design system embodies quiet, modern editorial restraint. Designed for discerning visual diarists, artists, and photographers, the interface steps backward so the captured image commands total presence. The emotional resonance is still, contemplative, tactile yet contemporary—reminiscent of high-end photobooks, architectural monographs, and fine-art gallery monographs.

### Style Archetype
- **Pure Warm Minimalism**: Extreme whitespace, whisper-thin hairline partitions, unboxed typography, and deliberate typographic rhythm.
- **Invisible Utility**: Controls and affordances fade into the background during capture and viewing. Elements appear on demand with gentle, precise transitions.
- **Subtle Print Materiality**: Instead of kitschy scrapbook embellishments (no faux tape, no playful stickers, no skeuomorphic paper tears), the tactile metaphor is strictly photographic: clean-cut borders, fine deckle or micro-perforated edges on export, and generous print-like mats.
- **Anti-Dashboard**: Avoid metric-driven badges, vibrant gamification streaks, loud stat cards, or cluttered navigation pills. Content floats directly upon the quiet linen ground.

## Colors

The palette is deliberate, monastic, and warm. It eschews pure cold digital blacks (#000000) and stark blued whites (#FFFFFF) in favor of museum-grade archival pigments.

- **Canvas & Base Ground (`#FAFAF7`)**: A soft linen warm white that prevents eye fatigue and mimics untreated cotton paper stock.
- **Secondary Canvas (`#F8F7F3`)**: An imperceptibly deeper ground for modal layers or recessed photo wells.
- **Primary Ink (`#1D1D1B`)**: Near-black charcoal used for primary headlines, focal typographic accents, and primary action iconography.
- **Muted Ink (`#77736D`)**: Warm slate-gray calibrated for metadata, time stamps, camera exposure readings (ISO, shutter, aperture), and secondary captions.
- **Accent Stone (`#6E5A4B`)**: An earthy, muted charcoal-brown reserved exclusively for focal active state indicators, subtle focus locks, or selected photo tags. It is used with extreme discipline.
- **Separators & Hairlines (`rgba(29, 29, 27, 0.08)`)**: Pure structural hairlines (0.5px to 1px) that delineate regions without creating heavy visual boundaries.

## Typography

The typography relies entirely on **Be Vietnam Pro**. Its geometry is crisp and contemporary, yet possesses subtle humanist nuances and flawless handling of complex diacritics.

### Hierarchy & Style Rules
- **Display & Headlines**: Understated, medium weight (`500`). Headlines avoid bombastic thick weights. Kerning is tracked slightly tighter (`-0.02em` to `-0.01em`) to maintain editorial tension.
- **Journal Entries (Body)**: Set in regular (`400`) at comfortable line heights (`1.55` to `1.625`) to preserve generous air between lines, reminiscent of literary magazines.
- **Metadata & Camera Exif**: Formatted with `technical-data` or `label-sm`, tracking wide (`0.06em` to `0.08em`) and rendered in uppercase muted text (`#77736D`) to echo engraved analog focal rings and darkroom contact sheets.

## Layout & Spacing

Layout in this design system is architectural and calm. The visual tempo is driven by generous white space rather than containers, boxes, or nested card enclosures.

### Layout Rules
- **Open Canvas Philosophy**: Avoid grouping journal items into padded boxes. Content flows directly on `#FAFAF7`, bounded only by optical spacing and hairline dividers.
- **Image Margins (The "Mat")**: Photographs are framed with intentional whitespace margins (a simulated gallery mat), never pressed edge-to-edge unless explicitly in raw viewfinder mode.
- **Grid Adaptability**:
  - **Mobile (< 640px)**: Single column stream with relaxed vertical rhythm (`space-xl` between entries), `margin` of `1.25rem`.
  - **Tablet (640px - 1024px)**: Asymmetric 2-column editorial spread, giving priority to visual verticality; `margin` of `2.5rem`.
  - **Desktop (> 1024px)**: Refined 3-column contact-sheet layout or a central reader column with ample exterior breathing room (`margin-desktop: 4rem`), maximizing focus on the photo story.

## Elevation & Depth

This design system rejects conventional drop shadows, plastic blurs, and elevation tiers. The aesthetic is strictly planar and tactilely flat, drawing depth from edge calibration and subtle optical shifts.

### Depth Principles
- **Zero Drop Shadows**: No blurred black shadows (`box-shadow: none`). Modals and bottom sheets float over a bare linen ground or are announced via hairline boundaries.
- **Low-Contrast Hairlines**: Divisions between the journal header, capture toolbars, and date transitions use a clean `1px` or `0.5px` border: `rgba(29, 29, 27, 0.08)`.
- **Viewfinder Translucency**: Camera overlays (reticle, exposure readout, level indicator) use pure flat opacity transitions directly over the live capture stream rather than glass-morphism panels or heavy background blurs.
- **Tonal Stepping**: In cases where stacking is mandatory (e.g., date scrubbers or contextual menus), depth is achieved through an imperceptible color shift to `#F8F7F3` outlined with the standard subtle border.

## Shapes

The geometric architecture is sharp, intentional, and editorial. Rounding is intentionally set to `0` (sharp edges) across structural elements, dialogs, inputs, and standard photo placements.

### Shape Characteristics
- **Sharp Modernist Edges**: System UI, buttons, bottom sheets, and viewports adhere to crisp right angles (`0px`), echoing trimmed paper stock and photographic darkroom prints.
- **The Stamp Motif**: Applied strictly to images, never to buttons, cards, or pills. On designated archival exports or stamp-mode captures, the photograph features either:
  1. A micro-perforated silhouette edge (reminiscent of philatelic perforations, subtle circular cutouts rendered through CSS masks).
  2. A crisp white photographic border (`4px` to `8px`) with an understated stamped date imprint at the lower right.
- **No Pills or Capsules**: Standard UI pills, badge bubbles, and bulbous containers are strictly banned.

## Components

Components are stripped of all decorative excess. They provide utility with razor-sharp quietness.

### Buttons
- **Primary Action (Minimal Text or Hairline)**: Flat background `#1D1D1B` with `#FAFAF7` typography, `0px` radius, padding `0.75rem 1.5rem`. Hover reduces opacity to `0.85`.
- **Secondary / Ghost Button**: Pure `#FAFAF7` canvas, `1px` border of `rgba(29, 29, 27, 0.15)`, text in `#1D1D1B`.
- **Text Action**: Unbordered, underlined with an ultra-thin hairline offset by `4px`, or simple all-caps tracking with `label-sm`.

### Chips & Tags
- **Strictly No Rounded Pills**: Tags are uncontained text tokens separated by middle dots (`·`) or subtle slash dividers (`/`).
- **Format**: Rendered in `label-sm`, color `#77736D`. When active, typography shifts to `#1D1D1B` with a subtle bottom hairline.

### Photo Cards & Journal Entries
- **Unboxed Architecture**: Zero outer container borders, zero shadows, zero card backgrounds.
- **Entry Structure**: The photograph sits on the canvas framed by an internal white mat. Directly below, metadata (e.g., `1/250s · f/2.8 · ISO 100 · 35mm`) is set in `technical-data` (`#77736D`), followed by the journal entry in `body-md` (`#1D1D1B`).

### Lists & Timelines
- Vertical list separated only by `space-xl` spacing and occasional ultra-fine divider lines (`rgba(29, 29, 27, 0.08)`).
- Date headers sit unadorned in `headline-sm`, aligned strictly flush left.

### Form Inputs & Text Fields
- Borderless input areas with only a single bottom hairline `1px` in `rgba(29, 29, 27, 0.12)`.
- Active focus smoothly darkens the hairline to `#1D1D1B`. Placeholder text in `#77736D` with a lighter optical weight.

### Camera Interface Controls
- **Shutter**: Concentric ultra-thin rings. An outer hairline ring (`rgba(29, 29, 27, 0.3)`) and an inner solid circle (`#1D1D1B`), sharp and flat.
- **Focus Indicator**: Precision hairline crosshairs or square brackets (`0.75px` stroke) in `#6E5A4B` or `#1D1D1B` that softly pulse upon focus lock.