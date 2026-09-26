# Visual Finish Gate

This gate exists because a novel mechanism or a diverse creative signature does **not** guarantee a finished artwork. The host explicitly rejected 026–030 as globally weak despite good technical diversity. Future batches must pass both the mechanism gate and this visual-finish gate.

## 1. Frozen-frame test

Before a sketch is considered finished, a representative still frame must work as an image without relying on motion or interaction to rescue it.

Require:

- one immediately legible visual idea;
- deliberate composition and negative space;
- at least three persistent identity anchors;
- no debug-grid / tech-demo look unless the grid is the artwork's actual structural carrier;
- no accidental empty areas, clipped focal material, or UI-like decoration;
- parameter defaults must already look authored.

## 2. Resolution and detail

The final visible image must survive full-screen PROGRAM output.

- Do not expose a coarse CPU simulation texture as the final surface merely enlarged to the viewport.
- A low-resolution solver is allowed as hidden state, but the visible render must reconstruct full-resolution geometry/material/detail from it.
- Prefer antialiased vector geometry, MultiMesh/particles, full-resolution shader material, raymarching, or a genuinely high-resolution image path for the visible layer.
- Build at least three detail scales when the concept supports it: silhouette / medium structure / micro-material detail.
- Micro-detail must serve the carrier (facets, grain, fibers, caustics, surface roughness, etc.), not generic noise sprinkled on top.

## 3. Material and light

When a sketch claims a physical carrier, its shading language should support that claim.

- derive highlights from normals/gradients/geometry where possible;
- use roughness, occlusion, thickness, refraction/dispersion, fiber direction or particulate response intentionally;
- avoid a flat palette swap standing in for materiality;
- avoid global glow as an automatic quality shortcut.

## 4. Temporal continuity

The existing temporal-quality rule still applies, with one additional hard requirement:

**No visible cut, reset, phase wrap, respawn wall, or synchronized population restart may be perceptible in normal viewing.**

Any wrapped state reused through a non-integer transform must be treated as discontinuous until proven otherwise. Faraday Quasi's wrapped forcing phase multiplied by fractional shader coefficients is the canonical failure case.

## 5. Interaction quality

Interaction must enter the system's state or material logic.

Reject by default:

- cursor-centered radial overlays;
- click-only brightness flashes;
- direct local shader bumps unrelated to system state;
- effects that disappear immediately on release without changing future behavior.

Prefer pressure, gesture velocity, topology changes, source motion, state writing, impulses, fracture, boundary changes, phase/material changes, or persistent memory.

Press, drag and release must each have intentional behavior. Recovery should be continuous.

## 6. Batch diversity

For a five-work batch:

- no more than two works may share the same primary visible rendering family;
- at least three substantially different technical representations must be visible in the final batch;
- at least one work should use geometry/instancing/particles rather than a fullscreen fragment shader;
- at least one work should use a materially different temporal model;
- changing only palette, text, cursor mapping or noise function is not a new work.

The adaptive creative draw is a collision generator, not an art director. Draw first, mutate, then reject any candidate that cannot meet this finish gate.

## 7. Host review

Repository CI can validate syntax, contracts and smoke behavior. It cannot certify beauty.

After a batch is REPO_VALIDATED, host review must specifically judge:

- frozen frame;
- full-screen detail;
- motion continuity;
- press / drag / release quality;
- parameter extremes;
- PREVIEW / PROGRAM parity;
- sustained autonomous behavior for at least 20–30 seconds.

A batch that is technically green but visually rejected remains creatively rejected. Do not use its existence as evidence that the direction succeeded.
