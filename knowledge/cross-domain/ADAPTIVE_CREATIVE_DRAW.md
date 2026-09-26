# Adaptive Creative Draw — DC//LAB

## Goal

DC//LAB should get better at proposing new creative systems as the user rates work, without converging into copies of whatever scored highest last week.

The draw engine optimizes two things at once:

1. **diversity / technical distance** — avoid repeatedly selecting the same representations, render paths and temporal models;
2. **explicit preference evidence** — gently bias choices using workstation REVIEW scores when available.

Preference is a bias, never a deterministic recommendation engine.

## Files

- draw space + recent history: `knowledge/cross-domain/creative_draw_space.json`
- executable draw: `scripts/creative/draw_recipe.py`
- temporal quality rules: `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`
- visual finish rules: `knowledge/cross-domain/VISUAL_FINISH_GATE.md`
- explicit rating snapshot: telemetry event `creative_preference_snapshot`

## Recipe shape

A draw selects:

- one carrier/material;
- two representations from different representation families;
- two operators from different operator families;
- one temporal model;
- one interaction consequence;
- one severe design constraint;
- one render path.

The output is a candidate `creative_signature` plus the random seed.

This signature is a **starting collision**, not a finished artwork. The required pipeline is now:

`draw -> prototype -> observe -> interpret -> mutate -> art-direct -> VISUAL_FINISH_GATE -> keep/reject`

Do not implement the raw draw literally if the coupling is weak, and do not keep a technically diverse prototype just because it is novel.

## Visual-finish correction after 026–030

The host explicitly rejected the 026–030 batch as globally weak even though it satisfied the adaptive diversity contract. That is durable evidence that **signature diversity is not visual quality**.

Every future kept work must also pass `VISUAL_FINISH_GATE.md`:

- strong frozen frame;
- authored composition and negative space;
- full-screen detail rather than visibly enlarged coarse simulation pixels;
- multiple meaningful detail scales;
- material/light logic appropriate to the carrier;
- no visible cuts/resets/phase-wrap seams;
- interaction must enter state/material logic rather than overlay a cursor effect.

A low-resolution solver may remain hidden behind a high-resolution visible render. It must not become the final image simply because it is convenient.

## Anti-repetition weighting

Every feature is penalized according to how often it appears in recorded history.

Recent use is penalized more strongly than old use:

- previous sketch: strongest penalty;
- last 3: strong penalty;
- last 5: moderate penalty.

A candidate is also compared axis-by-axis with recent signatures. By default it must differ from each recent item across at least four signature axes.

Representation pairs and operator pairs must come from different technical families.

## Preference learning

The runtime publishes all current explicit ratings in `creative_preference_snapshot`.

When a snapshot is passed to the draw engine, ratings are correlated only with **recorded signature features** of rated sketches. A high score can modestly increase the probability of related features; a low score can modestly decrease it.

The influence is deliberately bounded. Current implementation limits feature-level rating influence to roughly ±24% before diversity penalties.

A strong rating may teach the system that a mechanism worked; it must never turn every future sketch into a clone.

If telemetry is missing or stale, do not invent numeric review values. Direct qualitative host feedback remains valid evidence, but it should be recorded as such rather than fabricated into scores.

## Exploration share

A fixed exploration probability (currently 24%) ignores preference weighting entirely and uses only diversity/recency constraints.

This is essential. If every future choice exploited existing ratings, the catalogue would collapse around known taste and stop discovering new taste.

## Temporal guard

`forced_oscillator` remains available because periodic forcing can be physically valid, but it carries an additional base penalty.

The temporal CI audit separately rejects unexplained direct clock trigonometry for new sketches. A physically valid oscillator can still fail the finish gate if wrapped state produces a visible discontinuity. FARADAY QUASI's old wrapped forcing phase multiplied by fractional shader coefficients is the canonical failure.

## Recording history

Do not record every candidate draw. Record a signature only when a sketch is actually implemented/kept.

For sketch index 026+, `definition.json` must include a non-empty `creative_signature`. This gives future sessions machine-readable provenance for anti-repetition, ratings correlation, batch-distance checking and technique usage analysis.

When a future sketch is added, update the draw-space history with the implemented/mutated signature, not the raw discarded draw.

## Commands

Unbiased/diversity draw:

```text
python scripts/creative/draw_recipe.py --seed 20260925
```

Preference-aware draw from an extracted telemetry snapshot:

```text
python scripts/creative/draw_recipe.py --seed 20260925 --preferences preference_snapshot.json
```

CI self-test:

```text
python scripts/creative/draw_recipe.py --self-test --seed 20260925
```

## What ratings must not do

Do not:

- rank old works and simply clone the top one;
- remove disliked technical families permanently;
- treat one low score as universal rejection of a mechanism;
- use inferred taste when explicit structured ratings exist;
- optimize only the aggregate average while ignoring which axis failed.

For art direction, inspect individual axes plus direct qualitative host critique. A sketch with high originality but weak interaction needs a different intervention from a sketch with strong interaction but weak visual composition.
