# DC//LAB Living Systems for Realtime Art

This document defines what DC//LAB means by a **living realtime system**.

A work is not alive merely because something moves every frame. A sine wave, noise wobble or looping animation can be useful, but they do not by themselves create a system with behavior.

A living system has internal state, relationships, time scales and consequences. It continues to evolve when nobody touches it. Interaction changes its conditions rather than simply turning an effect on.

## 1. Autonomous baseline

Before interaction, the work should already possess a legible behavior.

Possible autonomous processes:

- coupled oscillators that drift toward/away from synchronization;
- agents with attraction, repulsion, fatigue or territory;
- stress that slowly accumulates and releases;
- reaction/diffusion or other concentration fields;
- material repair after damage;
- memory traces that migrate or fade;
- competing populations/states;
- slow parameter climate that modulates faster motion;
- cellular state transitions;
- typography whose anatomy changes through internal rules.

The viewer should be able to observe the piece for 30 seconds without touching it and discover change that is more meaningful than a decorative loop.

## 2. Internal state before visible effect

Model the system in terms of variables with meaning.

Examples:

```text
stress
fatigue
cohesion
pressure
memory
scar depth
permeability
phase
population
heat
nutrient
visibility confidence
repair capacity
```

Then derive the visual output from those variables.

Weak:

```text
mouse_down -> distortion_amount = 1
```

Stronger:

```text
gesture velocity -> local stress
stress diffuses to neighbours
fatigue lowers resistance
fracture changes local topology
repair slowly rebuilds the boundary
```

The second chain produces consequences the viewer can learn.

## 3. Interaction is perturbation

Prefer verbs such as:

- feed;
- starve;
- wound;
- seed;
- inhibit;
- select;
- isolate;
- attract;
- repel;
- compress;
- redirect;
- synchronize;
- desynchronize;
- contaminate;
- freeze;
- unlock;
- change boundary conditions.

Avoid making every piece use:

```text
click -> effect appears
release -> effect disappears
```

A gesture should normally change state that the autonomous system then redistributes, transforms, remembers or repairs.

## 4. Multiple time scales

One time scale often feels mechanical.

Combine at least two when appropriate:

### Fast

- touch response;
- collision;
- spring impulse;
- fracture;
- local reveal.

### Medium

- advection;
- neighbour coupling;
- drift;
- synchronization;
- erosion;
- recomposition.

### Slow

- fatigue;
- climate;
- memory;
- scar healing;
- population migration;
- identity phase changes.

A strong system can respond immediately while still carrying consequences minutes later.

## 5. Coupling creates behavior

Independent animated objects are usually less interesting than coupled ones.

Useful coupling patterns:

### Neighbour coupling

```text
state[i] changes state[i-1] and state[i+1]
```

Examples: rows synchronize, glyphs transmit pressure, grid cells spread stress.

### Field coupling

```text
objects write to field
field changes objects
```

Examples: glyph curvature injects flow; flow changes the glyph boundary.

### Resource coupling

```text
multiple agents consume one limited quantity
```

Examples: only some words may remain fully legible; increasing one voice suppresses another.

### Structural coupling

```text
one element's geometry becomes another element's constraint
```

Examples: counters become particle chambers; line length changes oscillator frequency.

### Temporal coupling

```text
past state modifies future response
```

Examples: repeated touch creates fatigue so later touch has stronger/weaker consequences.

## 6. Feedback, not filter stacks

A one-way chain is often predictable:

```text
text -> noise -> distortion -> color
```

A feedback loop can become a system:

```text
letter deformation
-> changes local field
-> field changes neighbour spacing
-> spacing changes pressure
-> pressure changes letter deformation
```

Feedback should be bounded. Define limits, decay, conservation or repair rules so the system does not merely explode into chaos.

## 7. State transitions and regimes

Continuous motion is not the only form of life.

A piece can move through regimes:

```text
stable
-> stressed
-> fractured
-> reorganizing
-> repaired-with-scar
```

or:

```text
individual voices
-> synchronization
-> chorus
-> phase collapse
-> re-emergence
```

Transitions create dramaturgy without requiring a linear timeline.

Useful triggers:

- accumulated stress threshold;
- local density;
- dwell time;
- repeated gestures;
- global synchronization level;
- memory saturation;
- spontaneous stochastic event with controlled probability.

## 8. Emergence test

Ask whether the system can produce a state that was not explicitly authored frame-by-frame.

Emergence does **not** mean randomness.

It can result from:

- simple neighbour rules;
- feedback;
- competing constraints;
- conservation;
- delayed response;
- hysteresis;
- local interactions across many elements.

If every interesting frame is directly scripted, the system may be animated but not generative in a meaningful sense.

## 9. Designed unpredictability

Pure randomness weakens identity.

Use constrained stochasticity for:

- event timing;
- choice between a few valid regimes;
- seeding positions;
- mutation of local parameters;
- imperfections inside a stable grammar.

Keep persistent identity anchors:

- palette roles;
- deformation law;
- topology rules;
- hierarchy;
- coupling family;
- temporal signature.

The viewer should recognize the piece even when they cannot predict its next exact state.

## 10. Living typography

Typography can be a population/material instead of static text.

Possible state lives at several depths:

### Word / line level

- reading hierarchy;
- synchronization;
- density;
- competition for space.

### Glyph level

- position;
- phase;
- width/weight axes;
- neighbour springs;
- role in a population.

### Anatomy / contour level

- stem stress;
- counter pressure;
- local curvature;
- fracture;
- repair;
- terminal inertia;
- aperture opening.

The deeper the artistic claim, the deeper the representation should be.

Refer to `../design/STRUCTURAL_TYPOGRAPHY.md`.

## 11. Parameter philosophy

Exposed controls should alter system rules.

Good examples:

- cohesion;
- autonomy;
- fatigue;
- repair rate;
- coupling radius;
- permeability;
- mutation probability;
- scar memory;
- resource scarcity;
- synchronization strength.

Weak default panel:

- speed;
- distortion;
- noise;
- glow;
- effect amount;
- another effect amount.

Those can exist internally, but the operator-facing model should describe the artwork's behavior.

## 12. Default-state rule

A sketch must not depend on slider tuning to become interesting.

Default values should provide:

- coherent composition;
- visible autonomous behavior;
- enough temporal depth to understand the system;
- controlled palette;
- strong hierarchy;
- safe performance.

Parameters should explore alternate personalities of a good system, not rescue a weak default.

## 13. Interaction dramaturgy

Design interaction as a relationship over time.

Possible sequence:

```text
observe
-> approach/select
-> perturb
-> system resists or amplifies
-> consequence propagates
-> viewer releases
-> system remembers/repairs/reorganizes
```

The most interesting moment may happen **after** the hand leaves the screen.

Do not make every interaction immediately obedient. Resistance, latency, inertia and indirect causality can make the work feel less like UI and more like a material/system.

## 14. Full-canvas and UI separation

The PROGRAM canvas contains only the artwork.

Gallery/editor UI owns:

- sketch title;
- index/number;
- tags;
- instructions;
- technical labels;
- debug information.

If explanatory text is required to understand the interaction, first ask whether the behavior itself can communicate the affordance more elegantly.

## 15. PREVIEW / PROGRAM determinism

Autonomy must remain compatible with DC//LAB live synchronization.

The editor/preview simulation remains the authority while linked.

Synchronize the state that actually determines future evolution, for example:

- oscillator phases;
- agent positions/velocities;
- memory buffers or compact summaries;
- scars;
- seeds/event counters;
- slow climate variables;
- population states.

Do not rely on two independent random timelines and hope they look similar.

When randomness is needed:

- use deterministic seeds or explicit generated events;
- synchronize event counters/seeds/state;
- avoid frame-rate-dependent branching when possible.

## 16. Performance budget

Living systems can become expensive quickly.

Choose representation based on state topology:

- small coupled population -> GDScript arrays/explicit agents;
- many independent points -> MultiMesh/particles/GPU;
- per-pixel field -> shader texture/compute/feedback;
- contour anatomy -> cached sampled outlines/SDF;
- global slow state -> compact CPU variables.

The workstation must remain responsive while PROGRAM is live.

## 17. Thirty-second acceptance test

Before calling a new realtime artwork complete:

### Hands off: 0–30 seconds

Observe without interaction.

Reject or rethink if:

- nothing meaningful happens;
- the only behavior is a trivial loop;
- all elements move independently with no relationship;
- interesting states require slider changes.

### One gesture, then hands off

Interact once for 1–3 seconds, then stop.

Look for:

- propagation;
- memory;
- redistribution;
- delayed response;
- recovery;
- regime change;
- meaningful scars.

If everything instantly returns to the untouched loop, question whether interaction affects the system deeply enough.

### Repeated interaction

Repeat similar gestures.

Ask whether history matters. If every gesture produces exactly the same temporary animation, temporal depth is likely weak.

## 18. Concept template

Before coding, write:

```text
AUTONOMOUS PROCESS:

INTERNAL STATE:

COUPLING:

FAST TIME SCALE:

SLOW TIME SCALE:

USER PERTURBATION:

WHAT PERSISTS AFTER RELEASE:

POSSIBLE REGIME CHANGES:

VISUAL INVARIANTS:

LIVE-SYNC STATE:
```

If most of these fields are empty, the concept is probably still an interactive effect rather than a living system.
