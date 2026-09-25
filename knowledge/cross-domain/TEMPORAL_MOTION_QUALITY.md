# Temporal Motion Quality — DC//LAB

## Purpose

A realtime artwork can be technically animated and still feel dead when the viewer can see the clock behind it. This document defines the temporal-quality contract used by DC//LAB for new sketches and for audits of older work.

The problem is not `sin()` or loops as programming constructs. The problem is **obvious periodicity used as substitute for behavior**.

## Core rule

> Time may advance a system. A naked global clock should rarely be the final visible cause of position, scale, opacity, warp, drift or composition.

Prefer a chain such as:

`time -> state transition / force / memory -> coupled system -> rendered consequence`

instead of:

`time -> sin() -> visible position`

## Temporal classes

### 1. Causal state evolution — preferred

Examples:

- reaction/diffusion;
- neighbour excitation + refractory state;
- contact forces + friction + stress;
- population birth/death/resource exchange;
- delayed feedback;
- hysteresis;
- spring/inertia with dissipation;
- erosion/repair;
- conserved phase separation;
- accumulated damage and recovery.

These systems do not need to return to a previous frame. Their motion is a consequence of state.

### 2. Event-driven stochastic evolution — preferred for autonomous drift

Examples:

- bounded random walk with momentum;
- target reselection after variable dwell times;
- Poisson-like events;
- asynchronous reseeding;
- state-dependent regime changes;
- noise or interpolated random targets used as a low-energy driver.

The goal is not visual randomness. It is to avoid a short exact return horizon when no periodic mechanism is conceptually required.

### 3. Physical / conceptual oscillator — allowed with intent

Periodic forcing is legitimate when periodicity is part of the mechanism: Faraday excitation, pendulum/oscillator systems, cyclic machinery, rhythm, explicitly looped audiovisual work, etc.

Even then, prefer:

`periodic forcing -> evolving state -> visible pattern`

rather than decorating the final image with unrelated clock-driven waves.

For new sketches, direct clock trigonometry in runtime files must be accompanied by a nearby `TEMPORAL_INTENT:` comment explaining why the oscillator is part of the work.

### 4. Decorative clock motion — rejected by default

Avoid generic patterns such as:

```text
x = center + sin(time * speed) * amount
alpha = 0.5 + sin(time) * 0.5
warp = sin(time + glyph_index)
row_offset = cos(time + row)
```

when their only purpose is “make it move”. They create visible breathing, bobbing, orbiting and wobbling with a predictable return.

## Reset quality

A loop can feel bad without trigonometry.

Reject or redesign when viewers can perceive:

- every particle resetting together;
- a radial front snapping back to zero;
- a regime changing every exact N seconds indefinitely;
- a simulation reseeding at a fixed obvious beat;
- a camera/field returning to the same path;
- a phase wrap that causes a visual jump.

Prefer exhaustion/recharge, staggered lifetimes, variable dwell, thresholds, hysteresis, successor generations or state continuity.

## Intentional loops

A true seamless loop remains valid as an artistic constraint. If the artwork is intentionally looped:

- declare it in the creative signature / concept;
- make closure exact and visually clean;
- ensure the loop period is compositionally meaningful;
- do not confuse a clean authored loop with accidental `sin(time)` ambience.

## Interaction

Press/drag/release should modify state rather than temporarily add a cursor effect whenever possible.

Good consequences include:

- change a material property;
- create/delete links;
- inject/remove mass or energy;
- write memory;
- move a boundary/source;
- change local pressure/temperature/concentration;
- seed a population;
- alter topology;
- push a system across a threshold.

After release, the system should resolve the consequence according to its own dynamics.

## Review protocol

Inspect a candidate at three horizons:

1. **15 seconds** — is an obvious bob/pulse/orbit already visible?
2. **60 seconds** — does the composition revisit the same path/state suspiciously often?
3. **5 minutes** — does the system have enough state depth to stay credible, or is the long horizon just a repeated short loop?

For physical oscillators, ask a different question: is the periodicity causing meaningful state selection/coupling, or merely visible decoration?

## Relationship to ratings

Explicit workstation REVIEW ratings are evidence, not an instruction to clone the highest-rated sketch.

The adaptive creation system may use ratings to bias feature probabilities, but diversity/novelty penalties must remain strong and a fixed exploration share must ignore preference bias. We want learning without converging into one house technique.

## CI boundary

`scripts/ci/audit_temporal_motion.py` reports direct clock-driven trigonometry across the historical corpus.

For new sketch indices (026+), CI additionally requires:

- a `creative_signature` in `definition.json`;
- no direct `sin/cos` of `sketch_time`, `u_time` or shader `TIME` unless the runtime file contains a `TEMPORAL_INTENT:` explanation.

Static CI cannot judge visual quality. It catches the cheap, identifiable failure mode; host review and ratings remain the artistic evidence layer.
