# Prompt for the next AI session

Reprends **DC//LAB / Godot Creative Lab** depuis `Rzbck/godot-creative-lab`.

Commence par résoudre le HEAD réel de `feat/creative-sketches-002-004-20260924` et sa CI exacte, puis lis :

1. `AGENTS.md`
2. `HANDOFF.md`
3. `docs/handoff/CURRENT_WORK.md`
4. `docs/handoff/OPERATIONS.md`
5. `docs/handoff/project_state.json`
6. `docs/ARCHITECTURE.md`
7. `docs/SKETCH_CONTRACT.md`

Après un test hôte, inspecte `telemetry/runtime` avant de demander logs/captures et vérifie que la session correspond au HEAD testé.

## Important — RATE UI

Le user a host-rejeté le `PopupPanel` RATE v2 : transparent, moche, pas centré. Ne le restaure pas.

`app/main/main_runtime_gallery_compact_review.gd` est maintenant REVIEW UI revision 3 :

- sidebar compact `REVIEW <avg>/5  RATE  TRASH`;
- RATE = modal **in-app** plein écran, pas popup natif;
- backdrop sombre;
- carte opaque design-system;
- centrage `CenterContainer`;
- × / Escape / clic ou touch hors carte pour fermer;
- notes persistantes + badge Gallery inchangés.

Après le prochain test, inspecte `review_modal_changed` si la télémétrie a bien avancé.

## Important — démarrage fullscreen

L’application doit maintenant ouvrir le **workstation complet en native fullscreen** dès `_ready()` du top runtime.

Ce n’est pas F11 :

- UI Gallery/paramètres/chrome reste visible au lancement;
- F11 reste présentation render d’un sketch;
- le rect windowed normal est mémorisé avant le passage fullscreen pour permettre Restore;
- après F11/Esc, le workstation doit revenir au mode fullscreen précédent.

Événement télémétrie : `workstation_startup_fullscreen`.

## Important — état télémétrie du feedback précédent

Lors de la critique du popup, telemetry-first a été fait mais la branche distante était stale :

- `latest.jsonl` vide;
- `telemetry/runtime` encore à `dd9194667593...` (2026-09-25 07:09:55Z), antérieur au test.

Donc ne prétends pas que ce feedback popup était telemetry-validated. Il vient directement du user.

## Important — notes utilisateur

Lis en priorité `creative_preference_snapshot` lorsqu’il existe dans une session fraîche. Il contient l’état consolidé des notes explicites.

Les notes servent de preuve et de biais modéré, pas de classement à cloner. Conserve une vraie exploration.

## Important — qualité temporelle

Le user rejette les boucles visibles cheap / respiration-bobbing de type `sin(time)` utilisées seulement pour faire bouger une œuvre.

Lire `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`.

Règle préférée :

`time -> état/force/mémoire/événement -> système couplé -> rendu`

plutôt que :

`time -> sin/cos -> position/scale/alpha/warp visible`.

Une oscillation physique/conceptuelle reste autorisée. À partir de 026, toute trigonométrie directe sur `sketch_time`, `u_time` ou shader `TIME` doit porter `TEMPORAL_INTENT:`.

CI : `scripts/ci/audit_temporal_motion.py`.

Premier audit : 38 observations historiques dans <=025.

Refactors actuels :

- 021 ROSENSWEIG : target/dwell variable, plus de Lissajous/orbite temporelle directe.
- 022 LIESEGANG : épuisement/repos/recharge, plus de front snap-reset visible.
- 024 GRANULAR JAM : creep stress/vitesse/confinement/asymétrie, avalanche indexée événement.
- 025 FARADAY : forcing périodique intentionnel, chirp stateful, ripple tactile décoratif retiré.

## Important — prochain tirage créatif

Utilise :

- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `knowledge/cross-domain/creative_draw_space.json`
- `scripts/creative/draw_recipe.py`

Il choisit carrier + 2 représentations de familles différentes + 2 opérateurs de familles différentes + modèle temporel + interaction + contrainte design + render path.

Il pénalise la répétition. Les notes peuvent biaiser légèrement, mais 24% des tirages ignorent entièrement le biais de préférence.

Pour tout sketch 026+, `definition.json` doit contenir `creative_signature`. Ne stocke que les concepts effectivement implémentés/conservés.

## Historique / non-régressions

- 005 reste visuellement **REGISTER TYPE**, jamais Pressure Lattice.
- ne restaure pas le contour-glyph généralisé `6c20a094...` comme représentation maison.
- ne restaure pas le mur permanent de tags.
- `ShaderSurface` plein-canvas obligatoire via `sketches/_shared/full_canvas_surface.gd`.
- navigation ne stoppe pas PROGRAM ; TAKE LIVE, touch, live-sync et telemetry restent stables.
- pas de faux Spout/NDI.

## Prochaine opération

Test hôte prioritaire :

1. lancer l’app : workstation doit remplir l’écran immédiatement avec tout le chrome UI;
2. Restore puis re-expand : géométrie stable;
3. ouvrir un sketch puis RATE : carte opaque et parfaitement centrée;
4. Restore/resize puis RATE : toujours centrée;
5. tester ×, Escape, clic/touch hors carte;
6. changer/effacer plusieurs notes, rouvrir, vérifier persistance + badge Gallery;
7. F11 puis Esc : retour au fullscreen workstation précédent;
8. fermer normalement;
9. ensuite telemetry-first sur session fraîche et HEAD testé.

Après toute modification matérielle : terminer commits/docs, résoudre HEAD final, attendre CI du SHA exact, donner short SHA + CI et le PowerShell canonique de `OPERATIONS.md` si test Windows pertinent.
