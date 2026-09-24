# Prompt for the next AI session

Copy/paste the block below into a fresh AI conversation with GitHub access.

---

Reprends le projet **DC//LAB / Godot Creative Lab** depuis le GitHub `Rzbck/godot-creative-lab`.

Ne te base pas sur une ancienne conversation. Commence par résoudre le HEAD réel de `feat/creative-sketches-002-004-20260924`, puis lis dans cet ordre :

1. `AGENTS.md`
2. `HANDOFF.md`
3. `docs/handoff/CURRENT_WORK.md`
4. `docs/handoff/OPERATIONS.md`
5. `docs/handoff/project_state.json`
6. `docs/ARCHITECTURE.md`

Inspecte ensuite `app/main/main_runtime.tscn` et sa vraie chaîne `extends`, la PR #7 et la CI du HEAD exact.

Pour un retour après test runtime, consulte d'abord `telemetry/runtime` avant de demander des logs.

Pour tout travail créatif, lis d'abord :

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
- `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md`
- `knowledge/cross-domain/IDEA_ENGINE.md`
- les atlases design/creative-coding pertinents
- `knowledge/design/DESIGN_REVIEW_CHECKLIST.md`

Important : une passe récente (`6c20a094...`) a appliqué les **contours de glyphes presque partout sur 006–010**. Elle a été rejetée après test hôte : rendu parfois inversé/cassé, cinq œuvres trop similaires techniquement, surinterprétation d'un seul axe de feedback. Le rollback commence à `3a437fe...` et restaure les comportements précédents tout en supprimant les cartouches de titre/numéro du canvas. **Ne restaure pas la passe contours généralisée.**

Les contours/vector paths restent une technique valide parmi beaucoup d'autres. Ne les traite jamais comme le style par défaut du labo.

Pour un nouveau concept substantiel, compare au moins **trois chaînes techniques plausibles** avant d'en choisir une. Exemples de familles disponibles : direct/variable typography, raster/masks, SDF/MSDF, fragment shaders, feedback buffers, particles/agents, vector fields, physical constraints, cellular/reaction-diffusion, procedural geometry/meshes, graphs/grids/topology, data/semantic systems.

Pour une série, évite de répéter la même représentation primaire, le même modèle temporel et la même conséquence interactive. Si plusieurs sketches ne diffèrent que par texte/couleurs/cursor mapping, la direction a échoué.

Le canvas PROGRAM doit rester artwork-only : pas de sketch title, numéro, tag, debug ou faux caption explicatif dans l'œuvre.

Préserve Gallery/PREVIEW/PROGRAM, TAKE LIVE, persistence, touch, live-sync et telemetry. Ne merge jamais `main` sans accord explicite.

Explique brièvement l'état réel après ton scan, puis continue directement sur GitHub.

---
