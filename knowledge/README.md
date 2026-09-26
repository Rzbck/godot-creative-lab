# DC//LAB Knowledge Library

This directory is the project's externalized research memory.

The intention is to avoid designing from vague recollection alone. Before creating a new visual direction, inspect recognized references, compare multiple sources, extract principles, verify licensing/provenance, then build an original DC//LAB interpretation.

The library now has three complementary layers: **technical methods**, **professional visual-design principles**, and **cross-domain translation/mutation**. The third layer exists specifically to help produce new identities rather than merely recombine familiar effects.

## Libraries

### `creative-coding/`

Shaders, procedural graphics, simulations, particles, feedback, realtime interaction, compute, generative systems and technical references.

Start with:

- `creative-coding/README.md`
- `creative-coding/CONCEPT_ATLAS.md`
- `creative-coding/SOURCE_CATALOG.md`

### `design/`

Typography, spacing, grids, margins, hierarchy, poster/editorial composition, color, visual identity, motion systems, spatial typography and design criticism/history.

Start with:

- `design/README.md`
- `design/TYPOGRAPHY_ATLAS.md`
- `design/GRAPHIC_DESIGN_ATLAS.md`
- `design/REALTIME_DESIGN_BRIDGE.md`
- `design/DESIGN_REVIEW_CHECKLIST.md`

### `cross-domain/`

Bridges between domains and a deliberate idea-generation system. This layer asks how typography can become geometry, how grids can become coordinate systems, how interaction can become forces, how simulation can become graphic language, and how several such translations can be coupled into an original realtime identity.

Start with:

- `cross-domain/README.md`
- `cross-domain/CROSS_DOMAIN_ATLAS.md`
- `cross-domain/IDEA_ENGINE.md`
- `cross-domain/SOURCE_CATALOG.md`

Use `cross-domain/sources.json` for future machine-readable search/generation tooling.

## Default research recipe

For a substantial new sketch, deliberately combine:

1. one **carrier** or identity anchor;
2. one **design principle**;
3. one **typographic principle** when type is involved;
4. one **creative-coding technique**;
5. at least one **representation change / cross-domain bridge**;
6. one **interaction or temporal model**;
7. one strong **constraint**;
8. several independent external references.

Then run the candidate through the mutation process in `cross-domain/IDEA_ENGINE.md` before implementation.

Example structure:

```text
modular editorial grid
+ variable-width typography
+ glyph outlines converted to a distance field
+ vector-field advection
+ touch injects velocity rather than direct displacement
+ feedback memory
+ two-color constraint
```

That gives us a designed generative system rather than a pile of effects.

## Originality policy

The library is not a style catalogue.

- Extract principles, representations and operators rather than copying surface appearance.
- Prefer several independent references from different domains.
- Mutate the first coherent combination before implementation.
- Let at least one cross-domain bridge change the underlying representation or behavior.
- Preserve professional composition/hierarchy constraints even when the system is highly generative.
- A concept should remain describable by its own rules if all reference names are removed.

## Repository policy

The knowledge library stores links, metadata and our own notes. It does not automatically vendor third-party code, fonts, screenshots, articles or copyrighted book content. Any external asset/code import requires an explicit license review.
