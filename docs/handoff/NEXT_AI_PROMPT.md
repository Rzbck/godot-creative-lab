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

Pour la prochaine exploration créative, lis d'abord :

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
- `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
- `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
- les atlases design/creative-coding pertinents
- `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md`
- `knowledge/cross-domain/IDEA_ENGINE.md`
- `knowledge/design/DESIGN_REVIEW_CHECKLIST.md`

La direction actuelle est **collision-first** : tirage technique aveugle, prototype brut couplé, observation des accidents, puis seulement interprétation et direction artistique. Les seeds A–E sont documentés dans `docs/handoff/CURRENT_WORK.md`.

Important : une passe récente (`6c20a094...`) a appliqué les contours de glyphes presque partout sur 006–010. Elle a été rejetée après test hôte : rendu parfois inversé/cassé, cinq œuvres trop similaires techniquement, surinterprétation d'un seul axe de feedback. Le rollback commence à `3a437fe...`. **Ne restaure pas la passe contours généralisée.**

Les contours/vector paths restent une technique valide parmi beaucoup d'autres. Ne les traite jamais comme le style par défaut du labo.

Le canvas PROGRAM doit rester artwork-only : pas de sketch title, numéro, tag, debug ou faux caption explicatif dans l'œuvre.

Préserve Gallery/PREVIEW/PROGRAM, TAKE LIVE, persistence, touch, live-sync et telemetry. Ne merge jamais `main` sans accord explicite.

## Règle obligatoire de fin de tâche

Tu ne dois jamais attendre que l'utilisateur te rappelle de mettre le repo à jour, d'attendre la CI ou de fournir le launcher.

Après toute modification matérielle du repo, avant ta réponse finale :

1. termine les commits/pushs prévus sur la branche active ;
2. mets à jour `docs/handoff/CURRENT_WORK.md` si l'état durable, NEXT, validation ou rejet a changé ;
3. mets à jour `HANDOFF.md` si une future session pourrait reconstruire un état périmé ;
4. mets à jour `docs/handoff/project_state.json` si l'état machine/contraintes/pointeurs knowledge ont changé ;
5. mets à jour ce `NEXT_AI_PROMPT.md` si les règles de reprise, la méthode créative ou la prochaine tâche ont changé ;
6. mets à jour `docs/handoff/OPERATIONS.md` si le workflow de test/sync/launch a changé ;
7. résous le HEAD distant final **après** tous ces commits ;
8. attends et inspecte la CI de ce SHA exact ;
9. donne le short SHA exact + le résultat CI ;
10. si un test Windows est pertinent, fournis automatiquement le bloc PowerShell canonique de `OPERATIONS.md` : il synchronise, attend la CI du SHA exact et ne lance Godot qu'après succès ;
11. après le test utilisateur, lis `telemetry/runtime` avant de demander des logs manuels.

Ne cite jamais une ancienne CI verte pour valider un HEAD plus récent.

Explique brièvement l'état réel après ton scan, puis continue directement sur GitHub.

---
