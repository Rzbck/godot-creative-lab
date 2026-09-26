# DC//LAB Design + Typography Knowledge Library

This folder is the visual-design counterpart to `knowledge/creative-coding/`.

The creative-coding library answers **how can this move, simulate, react or render?**
This library answers **why does the composition look controlled, intentional, legible, expressive and professionally designed?**

The goal is to combine both systems when creating DC//LAB sketches. A technically impressive shader with weak typography, bad margins, accidental spacing, shallow interaction or uncontrolled hierarchy is not considered finished.

Last research pass: **2026-09-24**.

## Research workflow

When starting or reviewing a sketch:

1. Identify the visual role: poster, typographic field, identity system, information layer, installation surface, motion composition, etc.
2. Open `TYPOGRAPHY_ATLAS.md` for type-specific constraints and opportunities.
3. Open `STRUCTURAL_TYPOGRAPHY.md` when the concept acts on the anatomy, contours or internal structure of letters.
4. Open `GRAPHIC_DESIGN_ATLAS.md` for hierarchy, composition, grid, color, rhythm and system thinking.
5. Open `REALTIME_DESIGN_BRIDGE.md` before translating static design ideas into animation, touch, shader deformation or multi-screen output.
6. Use `SOURCE_CATALOG.md` to inspect several professional references, archives and primary technical sources.
7. Use `sources.json` when future tooling needs machine-readable search/filtering.
8. Run the checklist in `DESIGN_REVIEW_CHECKLIST.md` before considering a visual direction production-ready.

## Core rules

**Never confuse generative freedom with accidental layout.**

Randomness, distortion, interaction, particles, feedback and motion should operate inside a designed system. We want controlled variability: the result may evolve continuously, but margins, hierarchy, rhythm, optical balance and interaction logic should remain intentional.

**A realtime artwork should normally be alive before the viewer touches it.**

The idle state is not a waiting room. Interaction should perturb, feed, damage, select, inhibit or redirect an autonomous system whose behavior is already legible.

**Choose a representation deep enough for the artistic claim.**

If the concept is about the structure of a letter, manipulating only the glyph position/scale is insufficient. Move to vector contours, sampled points, SDF/MSDF or another representation that exposes the anatomy actually being discussed.

**The PROGRAM canvas is the artwork, not a project card.**

Sketch title, number, category and explanatory metadata belong to Gallery/editor UI. They are not burned into the final composition unless that exact text is itself the artistic material.

## Main domains

- `type-anatomy-metrics` — baseline, cap/x-height, ascenders, descenders, sidebearings, glyph bounds.
- `structural-type` — contour-level deformation, counters, stems, bowls, apertures, terminals, topology and SDF boundaries.
- `spacing-rhythm` — kerning, tracking, leading, word spacing, line length, vertical rhythm.
- `hierarchy` — scale, weight, width, contrast, position, density, color, motion priority.
- `grid-layout` — columns, modular grids, baseline grids, safe areas, optical alignment, anti-grid strategies.
- `poster-composition` — scale, crop, tension, negative space, sequence, edge relationships.
- `color` — palette systems, contrast, temperature, luminance, perceptual color, accessibility.
- `editorial` — text/image relationships, pacing, pagination, captions, information density.
- `identity-systems` — repeatable rules, typography systems, visual tokens, responsive identity.
- `motion-design` — timing, rhythm, transition grammar, kinetic type, continuity, motion hierarchy.
- `living-systems` — autonomous state, coupled agents, slow variables, fatigue, memory, repair, emergence.
- `spatial-type` — text in physical/virtual space, projection, screens, installation, wayfinding.
- `variable-type` — weight/width/optical/slant/custom axes as continuous design parameters.
- `realtime-type` — SDF/MSDF, glyph masks, deformation, particles, feedback, audio/touch mapping.
- `accessibility` — legibility, contrast, text spacing resilience, motion comfort, color independence.
- `multi-script` — shaping, script-specific metrics, directionality and avoiding Latin-only assumptions.

## Source tiers

- **A — Primary / canonical:** official specifications, major archives/museums, original authors, established design institutions and long-running professional references.
- **B — Professional practice / curated:** respected studios, magazines, foundries, specialist archives and professional design systems.
- **C — Inspiration / trend:** current work galleries and community sources. Useful for visual research, but not automatically authoritative.

## Cross-pollination with creative coding

We intentionally want hybrids. Examples:

- Swiss/grid discipline × particle flow fields.
- Variable-font axes × audio envelopes.
- Editorial hierarchy × realtime data streams.
- Poster cropping × fullscreen responsive output.
- Letterpress/print texture × feedback shaders.
- Kinetic typography × touch velocity.
- Glyph contours × coupled spring/material systems.
- Counter area × fluid pressure or reaction state.
- Wayfinding logic × spatial installations.
- Color-system rules × reaction-diffusion palettes.
- Baseline grids × generative displacement.
- Optical margins × lens distortion.

The design system is allowed to bend; it should not disappear accidentally.

## Files

- `SOURCE_CATALOG.md` — curated web, archive, technical and studio references.
- `TYPOGRAPHY_ATLAS.md` — practical type principles and realtime translations.
- `STRUCTURAL_TYPOGRAPHY.md` — representation depth, contour/anatomy deformation, autonomous type behavior and Godot outline access.
- `GRAPHIC_DESIGN_ATLAS.md` — composition, grid, poster, identity, color and systems thinking.
- `REALTIME_DESIGN_BRIDGE.md` — how to convert professional design logic into shader/live behavior.
- `DESIGN_REVIEW_CHECKLIST.md` — production review before validating a sketch.
- `sources.json` — machine-readable index for future research/browser tooling.

## Research policy

This library stores links and our own summaries/analysis. It does not copy books, articles, fonts, imagery or proprietary design systems into the repository. External code, fonts and assets require an explicit license review before reuse. Visual references are used to understand principles, not to clone another designer's work.
