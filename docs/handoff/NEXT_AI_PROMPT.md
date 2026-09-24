# Prompt for the next AI session

Copy/paste the block below into a fresh AI conversation with GitHub access.

---

Reprends le projet **DC//LAB / Godot Creative Lab** depuis `Rzbck/godot-creative-lab`.

Commence par résoudre le HEAD réel de `feat/creative-sketches-002-004-20260924` et sa CI exacte, puis lis :

1. `AGENTS.md`
2. `HANDOFF.md`
3. `docs/handoff/CURRENT_WORK.md`
4. `docs/handoff/OPERATIONS.md`
5. `docs/handoff/project_state.json`
6. `docs/ARCHITECTURE.md`

Inspecte la PR #7 et l'architecture runtime avant toute modification du host. Pour un retour après test, consulte d'abord `telemetry/runtime`.

## Direction créative actuelle

Le labo utilise en priorité la méthode **collision-first** :

`tirage technique aveugle -> prototype couplé -> observation -> interprétation -> direction artistique -> mutation`

Lis d'abord :

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
- `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
- `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
- `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
- les atlases design/creative-coding pertinents
- `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md`
- `knowledge/cross-domain/IDEA_ENGINE.md`

Une ancienne passe contours généralisée (`6c20a094...`) sur 006–010 a été rejetée. Ne la restaure pas. `005_pressure_lattice` doit rester visuellement **REGISTER TYPE**, pas Pressure Lattice.

## Retour hôte important sur 011–015

La première batch collision-first était techniquement/creativement plus intéressante, mais :

- visuellement encore trop faible ;
- 3 paramètres par sketch ne suffisent pas ;
- les systèmes raster/cellulaires ne faisaient pas assez réellement travailler les pixels/cellules entre eux.

La télémétrie du test montrait 15 previews chargées sur le runtime correspondant, donc le retour est principalement créatif/systemique.

### Nouvelles règles durables

Pour un lab substantiel :

- viser **6–9 contrôles indépendants** quand le mécanisme le permet ;
- au moins la moitié des contrôles doivent modifier l'évolution future, pas seulement le rendu courant ;
- un système dit organique/cellulaire doit avoir de vrais échanges locaux : diffusion, excitation/réfractaire, ressources, pression, phase, délai, contraintes, réparation, etc. ;
- préférer plusieurs échelles de temps ;
- collision-first n'excuse pas un default visuellement négligé : palette, masse/vides et frozen frames doivent déjà être cohérents ;
- pas de titre/index/tag/debug dans le canvas PROGRAM.

## Batch actuelle 016–020

Graine du tirage : `202609242031`.

Cinq nouveaux labs sont implémentés :

- `016_predator_vein` / **PREDATOR VEIN** — réseau de nutriments + diffusion + hystérésis + champ cellulaire + prédateurs persistants/scars; 8 paramètres.
- `017_edge_bloom` / **EDGE BLOOM** — tissu excitable 64×36 + huit voisins + réfractaire + edge feed + spores gradient/deposit/split; 9 paramètres.
- `018_current_memory` / **CURRENT MEMORY** — membrane d'onde 52×30 + mémoire retardée + courant de particules + reconnexion + void asymétrique; 9 paramètres.
- `019_soft_flock` / **SOFT FLOCK** — boids + membrane Verlet + abrasion/réparation des liens + obstacle persistant; 9 paramètres; deux couleurs seulement.
- `020_echo_tissue` / **ECHO TISSUE** — tissu excitable 72×40 + voisinage + morphologie densité + réfractaire + feedback retardé + reseeding autonome; 9 paramètres.

Commit runtime : `e2ff8328532a4eab057c63b8bd1d361bc706ba15`.
CI #221 a validé import Godot 4.7.1, smoke main-scene et propreté Git pour ce commit runtime.

**Toujours résoudre le HEAD final réel après les commits de docs.**

## Prochaine opération

Le prochain travail est le **test hôte 016–020**, pas la génération automatique d'une nouvelle batch.

1. Gallery doit montrer 20 sketches.
2. Juger d'abord le default visuel sans toucher aux paramètres.
3. Laisser chaque sketch vivre 20–30 secondes.
4. Faire une interaction, retirer la main et regarder propagation/réparation/migration.
5. Ensuite explorer les 8–9 contrôles et vérifier qu'ils créent vraiment des régimes différents.
6. Tester les meilleurs sur PROGRAM/touch.
7. Lire la télémétrie juste après le test.
8. Décider lesquels pousser, muter ou tuer.

Préserve Gallery/PREVIEW/PROGRAM, TAKE LIVE, persistence, touch, live-sync et telemetry. Ne merge jamais `main` sans accord explicite.

## Règle obligatoire de fin de tâche

Après toute modification matérielle du repo, sans attendre que l'utilisateur le rappelle :

1. termine tous les commits/pushs prévus sur la branche active ;
2. mets à jour `CURRENT_WORK.md`, `HANDOFF.md`, `project_state.json`, ce prompt et `OPERATIONS.md` là où l'état durable/workflow a changé ;
3. résous le HEAD distant final **après** tous ces commits ;
4. attends et inspecte la CI de ce SHA exact ;
5. donne le short SHA exact + résultat CI ;
6. si un test Windows est pertinent, fournis automatiquement le PowerShell canonique de `OPERATIONS.md`, qui synchronise et ne lance Godot qu'après succès CI du SHA exact ;
7. après le test utilisateur, lis `telemetry/runtime` avant de demander des logs manuels.

Ne valide jamais un HEAD récent avec une ancienne CI verte.

---
