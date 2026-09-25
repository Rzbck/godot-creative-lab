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

## Priorité hôte

Le précédent lancement sur `672385c8...` a exposé une erreur Godot 4.7.1 : `Can't change visibility of main window` dans `_enter_tree()` de `main_runtime_window_memory.gd`. Revision 3 ne touche plus à `Window.visible`; elle applique mode/screen/rect directement dans `_enter_tree()` avant le premier frame de scène.

Le custom Maximize reste un borderless WINDOWED work-area rectangle avec garde basse de 2 px, jamais le fullscreen natif. F11 reste la présentation artwork.

La fermeture telemetry ferme maintenant le `FileAccess` avant de lancer le publisher final pour éviter la course qui avait produit des `latest.jsonl` vides. À valider sur Windows.

## Retours créatifs les plus récents

Le snapshot intermédiaire de la session `003706451ab202f2` récupère enfin les notes 026–030 :

- 026 VOID TENSION = 1.0 partout ;
- 027 GLASS TIDE = visual 2, tous les autres axes 1, moyenne ~1.17 ;
- 028 LUMEN MAZE = 1.0 partout ;
- 029 FIBER FELT = 1.0 partout ;
- 030 REACTOR SKIN = 1.0 partout.

Le user a également qualifié 031–035 de « pas fameux » sans snapshot numérique correspondant. Traite 026–035 comme un échec de direction visuelle globale, pas comme une réussite du système adaptatif.

Le user demande : image magnifique, forte même immobile, détaillée à grande résolution, matière/lumière crédibles, plusieurs échelles de détail, interaction qui modifie l'état au lieu d'ajouter un effet souris, et aucune coupure/loop visible.

## Batch actuel 036–040

La Gallery source doit compter **40 sketches** avant curation locale.

- **036 POLAR STRESS** — photoélasticité / biréfringence ; 4 charges persistantes pilotent un shader optique plein écran.
- **037 DENDRITE BLOOM** — croissance cristalline anisotrope + nutriment ; solveur 96×54 caché, matériau final full-res facetté.
- **038 ELECTRIC LACE** — lignes de champ électrostatique vectorielles antialiasées recalculées autour de 5 charges mobiles.
- **039 SOAP CONSTELLATION** — 8 cellules de mousse pression/surface-tension + film mince iridescent full-res.
- **040 SCHLIEREN VEIL** — champ densité/chaleur/vitesse 80×45 caché, rendu full-res basé gradients de densité type schlieren.

Tous ont `creative_signature` + `visual_finish` et 8–9 paramètres.

## Visual Finish Gate

Lire `knowledge/cross-domain/VISUAL_FINISH_GATE.md`.

Depuis 036, `scripts/ci/validate_repository.py` exige dans `definition.json` :

- `visual_finish.composition` ;
- `material_model` ;
- `final_render` ;
- au moins 3 `detail_scales` ;
- `interaction_stateful=true`.

La CI ne juge pas la beauté ; elle interdit seulement de sauter silencieusement l'étape de finition.

## Qualité temporelle

Toujours préférer :

`time -> état/force/mémoire/événement -> système couplé -> rendu`

Pas de `sin(time)` décoratif, phase wrap visible, reset, respawn wall ou restart synchronisé. FARADAY QUASI reste le cas canonique d'une phase physique valide dont le rendu avait malgré tout créé une coupure.

## Tirage créatif

Le moteur adaptatif reste un générateur de collisions, jamais un art director. Pipeline obligatoire :

`draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Les ratings biaisent modestement les tirages ; exploration indépendante conservée.

## Non-régressions

- 005 reste visuellement **REGISTER TYPE**, jamais Pressure Lattice.
- ne restaure pas le contour-glyph généralisé comme représentation maison.
- ne restaure pas le mur permanent de tags.
- `ShaderSurface` plein-canvas obligatoire via `sketches/_shared/full_canvas_surface.gd`.
- navigation ne stoppe pas PROGRAM ; TAKE LIVE, touch et live-sync restent stables.
- RATE modal reste in-app opaque/centré.
- ne restaure pas `root_window.visible=false/true` sur la fenêtre principale.
- pas de faux Spout/NDI.

## Prochaine opération

Test hôte prioritaire :

1. lancement sans erreur `Can't change visibility of main window` ;
2. Maximize/Restore stable, fermeture/réouverture cohérente ;
3. confirmer 40 cartes source moins curation locale ;
4. FARADAY : vérifier absence de cut idle + click/drag ;
5. regarder 036–040 d'abord immobiles, puis 20–30 s idle, puis interaction ;
6. noter 036–040 sur les six axes ;
7. fermer normalement sans Ctrl+C ;
8. telemetry-first : exiger un `latest.jsonl` non vide et un nouveau `creative_preference_snapshot`.

Après toute modification matérielle : terminer commits/docs, résoudre HEAD final, attendre CI du SHA exact, donner short SHA + CI et PowerShell canonique de `OPERATIONS.md` si test Windows pertinent.
