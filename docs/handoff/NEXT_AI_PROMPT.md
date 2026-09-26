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

## État actuel

Catalogue source : **001–045**.
Top runtime : `res://app/main/main_runtime_gallery_host_fixes.gd`, couche fine au-dessus de `main_runtime_window_memory.gd`.

Le user n’a **pas encore retesté** la version qui contient les derniers correctifs 037/038/040, les fixes Gallery LIST/TRASH et les nouveaux 041–045. Ne pas qualifier cette version de validée visuellement : elle est repo/CI validée seulement.

## Gallery — derniers correctifs hôte

### LIST

Le précédent LIST cachait la preview. Désormais chaque ligne conserve une vraie preview SubViewport sur la gauche (~260 px) et index/titre/engine/tags/description à droite. GRID/LIST réutilise les cartes et simulations existantes.

### TRASH

Le précédent bouton TRASH ouvrait seulement un drawer tout en laissant les shaders normaux visibles. Désormais TRASH est un mode exclusif : normal Gallery scroll/search/browser cachés, seuls les items Trash sont affichés. Un tag normal ou MORE sort du mode Trash. Restore/Purge restent locaux et ne touchent jamais la source Git.

## Correctifs précédents à retester

### 037 / 040

- ShaderMaterial local à chaque instance;
- double-buffer ImageTexture;
- publication d’état complet;
- reconstruction multi-tap du solveur caché;
- objectif : aucun flash noir/ancienne frame au clic/scrub et moins d’escaliers visibles.

### 038 ELECTRIC LACE

- hit-test réel sur charge visible;
- drag direct;
- clic vide = rien;
- petite inertie au lâcher.

## Nouveaux 041–045

### 041 TENSION ORGAN

Soft-body/constraint mesh 17×10. Springs structurelles + diagonales, forcing autonome par événements, direct node grab, énergie résiduelle après release. Rendu vectoriel en facettes de stress + fils de tension.

### 042 MYCELIUM RELAY

Écologie d’agents branchants avec nutriments autonomes, chemotaxis, énergie et chemins persistants. Le geste **peint des nutriments persistants** que l’organisme découvre ensuite : interaction indirecte sur le futur du système, pas drag d’objet.

### 043 SLIT MEMORY

Dix canaux couplés + vrai buffer historique 180 frames. Le rendu échantillonne l’histoire réelle. Le geste écrit des plis temporels persistants qui compriment/répètent/décalent l’historique pendant que la dynamique source continue.

### 044 EXCITABLE GLASS

Automate excitable/réfractaire caché 96×54. Pacemakers autonomes. Touch calme = seed; touch sur état actif = quench. Double-buffer et shader verre full-res multi-tap avec relief/caustiques/grain.

### 045 RIFT VOLUME

Raymarch SDF full-res : trois masses toroïdales + membrane pliée. Ancres CPU amorties, pas de shader TIME. Touch écrit une cicatrice/érosion persistante dans un champ caché et pousse les masses. Normales, AO, matériau minéral/spec/rim.

Les cinq ont live-sync, `creative_signature` et `visual_finish`.

## Validation connue avant docs finales

Code/UID commit : `c43be4300105e8677db22dd7c291a59d80fbc9f5`.
CI #307 : complètement verte (policy, temporal audit, adaptive draw self-test, Godot 4.7.1 import, main smoke, tracked cleanliness).

Après les docs, toujours résoudre le **nouveau HEAD final** et sa CI exacte; ne jamais utiliser #307 comme validation du HEAD docs inclus.

## REVIEW / feedback

RATE revision 4 contient les six axes + `WHY / NOTES`, sauvegarde locale et inclusion dans `creative_preference_snapshot`. Chaque changement programme un checkpoint télémétrie asynchrone ~0.8 s plus tard.

Derniers ratings distants fiables : 031=2.0, 032=1.5, 033=1.0, 034≈2.17, 035=1.0. Aucun nouveau score fiable 036–045. Ne rien inventer.

## Creative contract

Lire `VISUAL_FINISH_GATE.md`, `TEMPORAL_MOTION_QUALITY.md`, `ADAPTIVE_CREATIVE_DRAW.md` et `creative_draw_space.json`.

Toujours :

`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Le user veut image forte immobile, matière/lumière, vie organique, déformation contrôlée et interactions qui changent réellement état/topologie/mémoire. Éviter la répétition souris/slider. Pas de clock wobble générique, phase wrap visible, reset/respawn wall, coarse solver agrandi, ni interaction curseur superficielle.

## Non-régressions

- 005 visible = **REGISTER TYPE**, jamais Pressure Lattice.
- pas de contour-glyph généralisé comme house style.
- ShaderSurface plein canvas obligatoire.
- ShaderMaterial mutable toujours local à la scène.
- navigation ne stoppe jamais PROGRAM; TAKE LIVE/touch/live-sync restent stables.
- RATE reste opaque/centré/in-app.
- pas de `root_window.visible=false/true` sur la fenêtre principale.
- pas de faux Spout/NDI.

## Prochaine opération hôte

1. résoudre final HEAD + exact CI;
2. LIST : confirmer preview visuelle dans chaque ligne;
3. TRASH : confirmer vue exclusive + restore/purge;
4. stress-test 037/040, puis direct drag 038;
5. tester 041–045 : frozen frame, idle 20–30 s, interaction/recovery, extrêmes paramètres;
6. RATE + WHY/NOTES;
7. fermer normalement;
8. telemetry-first sur la session correspondante.

Après toute modification matérielle : code/push -> docs -> résoudre HEAD final -> attendre CI du SHA exact -> rapporter short SHA + CI -> fournir PowerShell canonique si host test pertinent.
