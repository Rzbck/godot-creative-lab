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
8. `knowledge/cross-domain/VISUAL_FINISH_GATE.md`
9. `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`
10. `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`

Après un test hôte, inspecte `telemetry/runtime` **avant** de demander logs/captures. Vérifie toujours que la session correspond au HEAD testé et qu'elle n'est pas vide.

## État créatif actuel

Le user a explicitement rejeté **026–030** comme globalement faibles visuellement. Ne traite pas ce batch comme une réussite du moteur adaptatif et n'invente pas les notes numériques 026–030 : le dernier publish de fermeture a écrit un `latest.jsonl` / session vide.

Le moteur adaptatif est seulement un générateur de collisions techniques. Le pipeline obligatoire devient :

`draw -> prototype -> observe -> mutate -> art-direct -> VISUAL_FINISH_GATE -> keep/reject`

Le user attend des œuvres fortes à grande résolution : frozen frame composé, plusieurs échelles de détail, matériau/lumière crédibles, interaction qui modifie réellement l'état, aucun aspect de petite simulation agrandie.

## Corrections runtime à valider sur l'hôte

### Fenêtre workstation — revision 2

Top runtime : `app/main/main_runtime_window_memory.gd`.

La télémétrie du pass précédent a prouvé que le custom Maximize faisait passer le client borderless en native fullscreen. Le chemin natif Maximize est rejeté.

Revision 2 :

- restaure l'état avant le premier frame visible ;
- représente `maximized` comme une fenêtre borderless **WINDOWED** occupant le usable rect avec garde basse de 2 px ;
- garde un restore rect séparé ;
- migre l'ancien état fullscreen issu du vieux Maximize vers ce logical-maximized ;
- F11 reste indépendant ;
- la fermeture flush puis démarre explicitement le publisher final avant `quit`.

État : **REPO_VALIDATED / HOST_VALIDATION_REQUIRED**.

### 025 FARADAY QUASI

Le cut était réel : une phase de forcing wrapée à `2π` était multipliée par des coefficients fractionnaires dans le shader, donc l'image devenait mathématiquement discontinue au wrap. Le clic ajoutait aussi un bump local direct au rendu.

Correction actuelle :

- forcing phase interne seulement ;
- phases modales visuelles continues/non-wrapées ;
- shader ne reçoit plus la phase wrapée ;
- clic/drag modifie énergie/détuning modal, pas une bosse visuelle superposée ;
- surface full-resolution avec normales/material shading continus.

État : **REPO_VALIDATED / HOST_VALIDATION_REQUIRED**.

## Nouveau batch 031–035

Gallery source attendue : **35 sketches**.

- **031 FOLD CHAMBER** — relief Delaunay vectoriel ~150 points, contraintes/springs, shading par facette, pression = refolding.
- **032 LUMEN SWARM** — jusqu'à ~900 streaks lumineux via MultiMesh, halo/core séparés, advection spatiale, source inertielle déplaçable.
- **033 OBSIDIAN CATHEDRAL** — architecture SDF raymarch full-resolution, AO/normales/facettes/specular, fractures persistantes au touch, aucun shader TIME.
- **034 PHOSPHOR SAND** — solver mémoire 128×72 caché ; rendu final shader full-resolution avec relief, gradients, grain micro, particules et réponse spectrale.
- **035 DUNE CHOIR** — vraie PDE d'onde amortie ; rendu final en topographie vectorielle perspective antialiasée avec seams et glints de courbure.

Le batch code `3ff965f...` a déjà passé CI #287. Les commits de documentation postérieurs exigent néanmoins une CI finale sur le HEAD exact.

## Visual finish gate — règle permanente

Lire `knowledge/cross-domain/VISUAL_FINISH_GATE.md` avant toute nouvelle œuvre substantielle.

Exigences : frozen frame fort, composition/negative space intentionnels, identité persistante, au moins plusieurs échelles de détail quand pertinent, final visuellement haute résolution, solver coarse seulement comme état caché, matériau/lumière cohérents avec le carrier, aucun phase-wrap/reset/respawn wall visible, interaction intégrée au système plutôt qu'effet curseur.

## Qualité temporelle

Le user rejette les loops visibles cheap et le `sin(time)` décoratif.

Préférer :

`time -> état/force/mémoire/événement -> système couplé -> rendu`

À partir de 026, trigonométrie directe sur `sketch_time`, `u_time` ou shader `TIME` nécessite `TEMPORAL_INTENT:`. Même avec un mécanisme périodique valide, tout wrap visible reste interdit.

## Non-régressions

- 005 reste visuellement **REGISTER TYPE**, jamais Pressure Lattice.
- ne restaure pas le contour-glyph généralisé comme représentation maison.
- 026–030 restent en source/historique mais sont créativement rejetés.
- ne restaure pas le mur permanent de tags.
- `ShaderSurface` plein-canvas obligatoire via `sketches/_shared/full_canvas_surface.gd`.
- navigation ne stoppe pas PROGRAM ; TAKE LIVE, touch, live-sync et telemetry restent stables.
- RATE modal reste in-app opaque/centré.
- pas de faux Spout/NDI.
- ne jamais inventer des ratings absents de la télémétrie.

## Prochaine opération hôte

1. lancer : aucun petit-window/fullscreen hop visible ;
2. custom Maximize/Restore plusieurs fois : rester native windowed, sans basculer fullscreen ;
3. fermer/réouvrir une fois expanded puis une fois windowed déplacée/redimensionnée ;
4. FARADAY : idle ~30 s puis press/drag/release répétés, aucune coupure globale ;
5. ouvrir 031–035 en grand PREVIEW puis PROGRAM/F11 ; juger d'abord le frozen frame, puis idle, interaction et recovery ;
6. noter 031–035 ;
7. fermer normalement ;
8. next AI = telemetry-first, en exigeant un publish final non vide avant de lire les nouvelles notes.

Après toute modification matérielle : terminer commits/docs, résoudre HEAD final, attendre CI du SHA exact, donner short SHA + CI et le PowerShell canonique de `OPERATIONS.md` si test Windows pertinent.
