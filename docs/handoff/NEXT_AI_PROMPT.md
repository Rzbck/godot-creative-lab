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

Inspecte la PR #7, `app/main/main_runtime.tscn` et sa vraie chaîne `extends` avant de toucher à l'architecture runtime.

Pour un retour après test, consulte d'abord `telemetry/runtime` avant de demander des logs.

## État créatif important

001–010 existent déjà. Une ancienne passe (`6c20a094...`) a appliqué des contours de glyphes presque partout sur 006–010 et a été rejetée après test hôte : rendu parfois inversé/cassé, cinq œuvres trop similaires et surutilisation d'une seule représentation. Le rollback commence à `3a437fe...`. **Ne restaure pas la passe contours généralisée.**

Le laboratoire est maintenant en méthode **collision-first** :

`tirage technique aveugle -> prototype brut couplé -> observation -> interprétation -> direction artistique -> mutation`

Lis en priorité :

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
- `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
- `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
- les atlases design/creative-coding pertinents
- `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md`
- `knowledge/cross-domain/IDEA_ENGINE.md`

## Nouvelle batch 011–015

Cinq **prototypes de laboratoire bruts** sont maintenant implémentés dans la Gallery. Ils ne doivent pas être traités comme des œuvres finales avant test hôte :

- `011_swarm_relay` / **SWARM RELAY** — agents + graphe dynamique; touch = dommage local des liens + répulsion, puis reformation.
- `012_chemical_blocks` / **CHEMICAL BLOCKS** — réaction-diffusion Gray-Scott; touch = injection de réactif.
- `013_cut_cell` / **CUT CELL** — territoires nearest-site + graphe; touch = coupe réelle de liens, puis cicatrisation.
- `014_ribbon_morph` / **RIBBON MORPH** — raster binaire + morphologie + reconstruction en rubans; touch = dépôt de matière, dwell = changement de régime.
- `015_phase_pack` / **PHASE PACK** — packing/collisions + règles de phase + champ de distance; touch = conversion de phase + répulsion.

Le commit racine d'implémentation est `230ef4ff...`; les cinq `.gd.uid` générés ensuite sont maintenant suivis. **Résous toujours le HEAD final réel**, ne teste pas uniquement ce SHA historique.

Premier résultat CI connu du commit runtime initial : import Godot 4.7.1 et smoke main-scene passaient; l'échec était uniquement la propreté Git due aux cinq UID non suivis. Le HEAD final doit tout de même avoir sa propre CI verte.

### Prochaine opération

Le prochain vrai travail est le **test hôte 011–015**, pas une nouvelle génération d'œuvres :

1. Gallery doit montrer 15 sketches et de vraies previews pour 011–015.
2. Regarder chaque nouveau système 15–30 secondes sans toucher et sans régler les sliders.
3. Faire un geste, retirer la main et observer la conséquence.
4. Tester les meilleurs candidats sur PROGRAM/touch.
5. Après le test, lire la nouvelle télémétrie.
6. Ensuite seulement choisir les accidents/mécanismes qui méritent une passe artistique studio; tuer ou muter les autres.

PROGRAM canvas reste artwork-only : pas de titre/index/tag/debug/faux caption de projet dans l'œuvre.

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
