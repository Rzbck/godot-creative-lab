# Prompt for the next AI session

Reprends **DC//LAB / Godot Creative Lab** depuis `Rzbck/godot-creative-lab`.

Avant toute conclusion, résous le HEAD réel de `feat/creative-sketches-002-004-20260924` et la CI de ce SHA exact, puis lis :

1. `AGENTS.md`
2. `HANDOFF.md`
3. `docs/handoff/CURRENT_WORK.md`
4. `docs/handoff/OPERATIONS.md`
5. `docs/handoff/project_state.json`
6. `docs/ARCHITECTURE.md`
7. `docs/SKETCH_CONTRACT.md`

Après tout test hôte, inspecte `telemetry/runtime` **avant** de demander logs/captures et avant de réparer ou créer un nouveau batch.

## Etat actuel

Catalogue source : **001–050**.

Le batch **046–050** a été construit après lecture croisée des notes numériques + written reviews disponibles. Il est techniquement validé mais **pas encore accepté visuellement par le user**.

Implementation HEAD avant docs : `96471494f10c8c292ab8b0c0c04ea6dcf2828034`.
CI code **#340** : GREEN complet (policy, temporal audit, creative draw self-test, Godot import, main smoke, cleanliness).

Ne confonds jamais ce succès CI avec un succès artistique.

## Evidence utilisateur désormais vérifiée

La pipeline written-review est maintenant réellement vérifiée. Session `67a6e7499c4524cf`, runtime `ceecb6be59a9` : les notes existent sous `creative_preference_snapshot.reviews.<sketch>.note` et le startup republish fonctionne.

Axes moyens visibles :
- visual ~2.06
- interaction ~1.72
- originality ~1.92
- aliveness ~1.64
- controls ~1.56
- performance ~2.42

Donc les trois faiblesses dominantes à corriger sont : **controls, aliveness, interaction**.

Signaux positifs bornés :
- 020 ECHO TISSUE ~4.17 : causalité/lisibilité/contrôle forts, mais ne pas le cloner;
- 012 CHEMICAL BLOCKS ~3.33;
- 038 ELECTRIC LACE ~2.67, visual 4 + originality 4 : sources compréhensibles, mais interaction/controls restaient faibles.

Written reviews utiles :
- 041 : trop basic pour le sujet, physique peu ressentie, bugs visuels quand on tire trop;
- 042 : plutôt pas mal mais manque d'interaction; paramètres semblent ne rien faire au lieu de créer un résultat réellement différent;
- 043 : incompréhensible, pas interactif temps réel, clic sans sensation, rejet visuel;
- 044 : trop pixelisé, pas de reset, paramètres faibles;
- 045 : rejet visuel/semantic très fort, résultat incompréhensible.

Règle durable : **un paramètre est valide s'il change visiblement le régime/composition/comportement**, pas s'il fait seulement varier un “amount”. Une interaction doit être immédiatement lisible et laisser une conséquence stateful/différée.

## Batch 046–050

### 046 INK SHEAR
- filaments d'encre vectoriels persistants;
- le geste écrit des eddies persistants;
- viscosité/vorticité/bleed/pigment/brush/memory doivent produire des changements réellement lisibles;
- aucun coarse fluid grid visible.

### 047 MOIRE APERTURE
- champ analytique full-resolution;
- apertures/anchors directement dragables;
- density/angle/shear/lens doivent basculer vers des familles d'interférence distinctes;
- pas de texture de solver grossière.

### 048 ACTIVE NEMATIC
- solver direction/flow discret caché;
- rendu final = 880 filaments MultiMesh;
- geste écrit orientation/spin;
- alignment/activity/defect birth/flow memory doivent produire des régimes active-matter différents.

### 049 TEMPER SKIN
- métal thermique avec conduction/cooling/oxide memory;
- interaction dépend de l'état : zone froide chauffée, zone déjà chaude quench/refroidie;
- paramètres = durée thermique, couplage et mémoire matériau, pas simple brightness.

### 050 FERRO TRACE
- 1100 limaille/filings MultiMesh;
- 2–4 pôles directement déplaçables;
- hystérésis d'orientation;
- reprendre la lisibilité de sources de 038 sans reprendre son esthétique.

`knowledge/cross-domain/creative_draw_space.json` contient maintenant 046–050 dans l'historique collision-avoidance.

## Host test prioritaire

Quand le user teste :

1. confirmer Gallery = 50;
2. laisser chaque 046–050 vivre 20–30 s au default avant manipulation;
3. interaction -> release -> vérifier réponse immédiate + mémoire/consequence;
4. pousser tous les paramètres sur de grands écarts et relever ceux qui semblent inutiles;
5. vérifier 046 eddies opposés et persistance;
6. vérifier 047 regimes d'interférence très différents;
7. vérifier 048 defects/flow visibles via filaments, jamais via pixels grossiers;
8. vérifier 049 heat puis quench state-dependent + extremes conduction/cooling/oxide;
9. vérifier 050 poles dragables + réorganisation/hystérésis des filings;
10. RATE numeric + WHY/NOTES normalement, sans demander au user de recopier les notes dans le chat;
11. fermeture normale, puis **telemetry-first** sur le tour suivant;
12. n'attribuer FPS/ratings qu'après vérification que telemetry correspond au HEAD/session réellement testé.

## Contrats à préserver

- 005 visible = **REGISTER TYPE**; ne jamais restaurer Pressure Lattice.
- pas de contour-glyph généralisé.
- pas de mur permanent de tags.
- LIST reste compacte ~68 px, preview en background décoratif.
- PREV/NEXT ne remplace jamais PROGRAM; TAKE LIVE reste explicite.
- PROGRAM persiste à travers Gallery/Settings/navigation.
- linked PREVIEW/PROGRAM = même timeline/state.
- physical PROGRAM touch/mouse fonctionne.
- ShaderSurface plein canvas.
- ShaderMaterial mutable toujours local à la scène.
- RATE opaque/centré/in-app.
- pas de `Window.visible=false/true` au startup.
- pas de faux Spout/NDI.
- pas de generic direct-clock wobble comme aliveness.
- pas de solver coarse exposé comme finition artistique.
- written reviews = source de premier rang, mais ne jamais transformer un bon score en règle de clonage.

## Completion obligatoire

Après toute modification matérielle : code/push -> docs/state -> résoudre HEAD final -> attendre CI exacte -> inspecter tous les jobs -> rapporter SHA/CI -> PowerShell canonique si test hôte pertinent -> telemetry-first après test.
