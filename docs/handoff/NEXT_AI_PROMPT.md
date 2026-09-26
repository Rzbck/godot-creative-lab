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

Après tout test hôte, inspecte `telemetry/runtime` **avant** de demander logs/captures. Ne jamais inventer un rating absent de la télémétrie.

## Dernier retour hôte

Le user a testé 036–040.

- 037 DENDRITE BLOOM : rendu cellulaire/pixelisé + flashes noir/ancienne frame dès interaction ou changement de paramètre.
- 038 ELECTRIC LACE : premier signal positif clair (`vraiment sympa`) mais interaction souris trop faible; il veut attraper les charges directement.
- 040 SCHLIEREN VEIL : même glitch stale-frame pendant clic et scrub paramètres.
- il veut écrire un commentaire libre dans RATE pour expliquer pourquoi un axe est bas/haut.
- il veut une Gallery type Finder/Explorer : tri fiable, GRID/LIST et taille de cartes réglable.

## Correctif implémenté

Commit code de référence : `e20e1751ed2dae70899f56fcf5217b3d84e75910`, CI #299 complètement verte avant les commits docs.

### Isolation ShaderMaterial — règle permanente

Cause racine probable du stale-frame : Gallery conserve une vraie instance cachée de chaque sketch et synchronise ses paramètres. Les scènes shader partageaient leur `ShaderMaterial`; la vignette pouvait donc réécrire les uniforms/textures de l'instance active.

Maintenant :

- tous les `ShaderMaterial` de sketch existants ont `resource_local_to_scene = true`;
- `scripts/ci/validate_repository.py` échoue si un futur runtime `.tscn` oublie cette isolation;
- PREVIEW / Gallery thumbnail / PROGRAM ne doivent jamais partager des uniforms stateful.

### 037 / 040

- deux `ImageTexture` alternées : écriture sur texture inactive puis switch du sampler;
- interaction marque l'état GPU dirty et pousse une frame complète;
- reconstruction shader multi-tap du solveur caché pour réduire les gros escaliers de cellules;
- ne pas augmenter brutalement la grille CPU : l'état doit rester raisonnable pour le live-sync.

### 038

- clic uniquement sur une charge dans un vrai hit radius;
- charge suit directement le pointeur pendant drag;
- clic vide ne saisit rien;
- petite inertie au lâcher;
- anneau de prise discret seulement pendant manipulation.

## REVIEW revision 4

RATE modal contient maintenant **WHY / NOTES** :

- texte persistant dans `user://creative_lab_reviews.cfg`;
- texte inclus dans `creative_preference_snapshot`;
- bouton SAVE REVIEW + sauvegarde à fermeture du modal;
- max 2000 caractères;
- checkpoint telemetry publié ~0.8 s après la dernière note/commentaire afin de ne plus dépendre de la fermeture de l'app.

## Gallery browser revision 2

- default **INDEX ↑**, vue plate donc 001→040 réellement ordonnée;
- INDEX ↓, TITLE A–Z, FAMILY;
- FAMILY restaure les groupes tags;
- GRID / LIST;
- slider de taille des cartes en GRID;
- état persistant `user://creative_lab_gallery_view.cfg`;
- tri/reflow réutilise les cartes/SubViewports existants, ne redémarre pas les simulations.

## Telemetry / window revision 4

Le dernier `session_close_request` distant était encore vide. La dernière publication intermédiaire non vide a permis de récupérer 031–035 :

- 031 avg 2.0
- 032 avg 1.5
- 033 avg 1.0
- 034 avg ~2.17
- 035 avg 1.0

Les nouvelles notes 036–040 ne sont **pas** disponibles côté serveur : ne pas les inventer.

Revision 4 shutdown : `session_close_flush` (non auto-publié) -> `flush()` -> `FileAccess.close()` explicite -> release handle -> un seul publisher final caché avec reason `session_close_request`.

## Creative contract

Catalogue source : **001–040**.

Le user a rejeté 026–035 globalement; la diversité technique ne suffit pas. 038 est un signal positif à préserver, pas à transformer arbitrairement.

Lire `knowledge/cross-domain/VISUAL_FINISH_GATE.md` et `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`.

Toujours :

`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Pas de clock wobble générique, phase wrap visible, reset/respawn wall, coarse solver agrandi comme artwork final, ni interaction curseur superficielle.

## Non-régressions

- 005 visible reste **REGISTER TYPE**, jamais Pressure Lattice.
- pas de contour-glyph généralisé comme house style.
- pas de mur permanent de tags.
- `ShaderSurface` plein canvas obligatoire.
- ShaderMaterial de sketch toujours local à la scène.
- navigation ne stoppe pas PROGRAM; TAKE LIVE/touch/live-sync stables.
- RATE reste modal in-app opaque centré.
- pas de `root_window.visible=false/true` sur la fenêtre principale.
- pas de faux Spout/NDI.

## Prochaine opération hôte

1. résoudre HEAD final + CI exacte;
2. tester 037 en scrub paramètres + clic/drag : aucun flash noir/ancienne frame;
3. tester 040 pareil;
4. tester le grab direct de 038;
5. écrire une note WHY dans RATE, SAVE REVIEW, attendre brièvement;
6. vérifier tri 001→040, autres tris, GRID/LIST, taille et persistance après restart;
7. fermer normalement;
8. telemetry-first : confirmer un checkpoint review non vide et une fermeture non vide.

Après toute modification matérielle : code/push -> docs -> résoudre HEAD final -> attendre CI du SHA exact -> rapporter short SHA + CI -> fournir PowerShell canonique si host test pertinent.
