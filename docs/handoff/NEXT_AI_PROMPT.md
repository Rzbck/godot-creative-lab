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

## Priorité 1 — startup window memory

Le user a rejeté le démarrage visible `1280×720 windowed -> fullscreen`. La télémétrie fraîche a confirmé ce jump (~730 ms).

Top runtime actuel :

`app/main/main_runtime_window_memory.gd`

État persisté :

`user://creative_lab_window_state.cfg`

Le root Window est caché dans `_enter_tree()`, le dernier mode/screen/position/size/restore rect est appliqué, puis l’app n’est révélée qu’après settle. Premier lancement = fullscreen par défaut.

F11 reste la présentation du sketch et ne doit pas écraser la préférence de fenêtre du workstation.

Événement attendu : `workstation_window_state_restored`.

État : **IMPLEMENTED_NOT_HOST_VALIDATED**. Après test Windows, vérifie spécifiquement absence du flash et restauration fullscreen/maximized/windowed.

## Priorité 2 — notes utilisateur

Lis d’abord `creative_preference_snapshot` d’une session fraîche.

Dernier snapshot complet connu : `session_5e0960d4c3e0c6a7.jsonl`, 16 sketches notés.

Moyennes axes : visual 2.25, interaction 2.125, originality 2.125, aliveness 1.8125, controls 2.0, performance 3.0625.

Signaux forts :

- 020 ECHO TISSUE ~4.17;
- 012 CHEMICAL BLOCKS ~3.33;
- 017 EDGE BLOOM ~2.83.

Faibles : 014 = 1.0, 016 ~1.5, 024 ~1.67, 022 ~1.83.

Interprétation : favoriser couplage local, propagation, mémoire et interaction qui change l’évolution future, mais ne pas cloner 020. Le biais rating reste borné et 24% des draws restent exploration-first.

## REVIEW UI

Le `PopupPanel` transparent/off-center est rejeté. REVIEW v3 = ligne compacte + modal in-app opaque/centré. Ne restaure jamais le popup natif.

## Batch actuel 026–030

La Gallery source doit compter 30 sketches.

- 026 VOID TENSION — réseau contraint + territoires Voronoi, fracture/réparation, touch coupe les liens.
- 027 GLASS TIDE — SDF glass + fronts d’onde asynchrones, touch altère la topologie optique.
- 028 LUMEN MAZE — transport lumineux sur graphe, jam/release, obstacles persistants.
- 029 FIBER FELT — fibres + masque de compaction, phase transition loose→felted.
- 030 REACTOR SKIN — réaction-diffusion + membrane/mesh stress, fracture/réparation.

Toutes les définitions ont `creative_seed` + `creative_signature`. Les signatures implémentées sont dans `knowledge/cross-domain/creative_draw_space.json`.

## Qualité temporelle

Le user rejette les loops visibles cheap / `sin(time)` décoratifs.

Lire `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`.

Préférer :

`time -> état/force/mémoire/événement -> système couplé -> rendu`

À partir de 026, trigonométrie directe sur `sketch_time`, `u_time` ou shader `TIME` nécessite `TEMPORAL_INTENT:`.

## Tirage créatif

Utilise :

- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `knowledge/cross-domain/creative_draw_space.json`
- `scripts/creative/draw_recipe.py`

Le moteur pénalise répétition historique/récente, impose distance/familles distinctes et applique seulement un biais borné des ratings. 24% exploration ignore les préférences.

Ne prends pas le tirage brut comme concept final : `draw -> prototype couplé -> observe -> interprète -> art-direct -> mutate`.

## Non-régressions

- 005 reste visuellement **REGISTER TYPE**, jamais Pressure Lattice.
- ne restaure pas le contour-glyph généralisé comme représentation maison.
- ne restaure pas le mur permanent de tags.
- `ShaderSurface` plein-canvas obligatoire via `sketches/_shared/full_canvas_surface.gd`.
- navigation ne stoppe pas PROGRAM ; TAKE LIVE, touch, live-sync et telemetry restent stables.
- RATE modal reste in-app opaque/centré.
- ne restaure pas le startup visible petit->fullscreen.
- pas de faux Spout/NDI.

## Prochaine opération

Test hôte prioritaire :

1. lancer : aucune petite fenêtre avant l’état final;
2. fermer/reouvrir en fullscreen, maximized puis fenêtre déplacée/redimensionnée;
3. vérifier RATE modal;
4. confirmer 30 cartes;
5. regarder 026–030 20–30 s idle puis interaction + mains retirées;
6. noter 026–030;
7. fermer normalement;
8. telemetry-first : `workstation_window_state_restored`, `creative_preference_snapshot`, perf/surface events, HEAD testé.

Après toute modification matérielle : terminer commits/docs, résoudre HEAD final, attendre CI du SHA exact, donner short SHA + CI et PowerShell canonique de `OPERATIONS.md` si test Windows pertinent.
