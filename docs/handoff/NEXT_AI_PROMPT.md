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

Pour un retour après test, inspecte d'abord `telemetry/runtime`. N'attribue jamais des FPS à un sketch si la télémétrie ne correspond pas au HEAD/session testé.

## Direction créative

Méthode actuelle : **collision-first**.

`tirage technique / phénomène -> prototype couplé -> observation -> interprétation -> direction artistique -> mutation`

Lire en priorité :

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
- `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
- `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
- `knowledge/cross-domain/PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
- `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
- `knowledge/cross-domain/REALTIME_PERFORMANCE_BUDGET.md`
- atlases design/creative-coding pertinents
- `CROSS_DOMAIN_ATLAS.md` / `IDEA_ENGINE.md` quand un mécanisme mérite une vraie identité.

Règles : 6–9 contrôles indépendants pour un lab substantiel lorsque pertinent; vraie propagation/couplage local pour l'organique; plusieurs échelles de temps; default visuel regardable; interaction = condition physique/état futur; pas de titre/index/debug dans le canvas; pas de technique maison par défaut.

Une ancienne passe contours généralisée `6c20a094...` sur 006–010 est rejetée. `005_pressure_lattice` reste visuellement **REGISTER TYPE**, jamais Pressure Lattice.

## Retour hôte 016–020

Le user juge 016–020 **clairement meilleurs / commence à être pas mal**, mais veut encore plus de matière réelle, d'interactivité et de beauté. Il a aussi observé certains sketches sous son très haut baseline de fluidité (~330 FPS).

Telemetry-first a été fait, mais le remote est stale : dernier publish `82114646068521140f1727b7d323803f7de51e58`, runtime `6dd4b307...`, 15 previews. Donc aucune attribution exacte de FPS à 016–020 n'est actuellement justifiée.

Code audit a néanmoins trouvé deux hotspots évidents :

- 017 : ~2304 primitives Canvas potentielles par frame;
- 020 : ~2880 cellules + voisinage recalculé pendant `_draw()`.

Ils ont été optimisés : champ dense -> `ImageTexture` mise à jour à cadence de simulation + un draw; 020 cache la densité.

## Nouvelle banque physique/chimie

`PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md` ajoute notamment : BZ, Liesegang, spinodal/Cahn–Hilliard, Bénard–Marangoni, Faraday, Rosensweig/ferrofluides, DLA, jamming/force chains, Rayleigh–Taylor, Kelvin–Helmholtz et Saffman–Taylor.

Principe obligatoire : conserver au moins une vraie causalité/seuil du phénomène, pas uniquement son look.

## Batch actuelle 021–025

Graine : `202609250742`.

- `021_rosensweig_field` / **ROSENSWEIG FIELD** — seuil magnétique, pics couplés, viscosité/hystérésis; movable magnet; 8 params; shader plein écran.
- `022_liesegang_front` / **LIESEGANG FRONT** — réservoirs, front diffusif, supersaturation, bandes précipitées, déplétion/dissolution; 8 params.
- `023_spinodal_marangoni` / **SPINODAL MARANGONI** — phase-field conservé-ish + quench thermique + advection tension de surface; 9 params; texture basse résolution.
- `024_granular_jam` / **GRANULAR JAM** — grains packés, contacts/friction/load, chaînes de force, creep, avalanche retardée; 9 params; graphe de contact calculé une seule fois par step.
- `025_faraday_quasi` / **FARADAY QUASI** — quatre modes CPU + résonance paramétrique/mode competition + shader plein écran; 8 params.

Commit runtime : `50e7d9f9296768a09a56c7a8f7ac421a4d823389`.
CI #224 a validé policy, import Godot 4.7.1, smoke et cleanliness pour ce commit runtime.

Toujours résoudre le **HEAD final docs inclus** et sa CI avant test.

## Prochaine opération

Test hôte :

1. Gallery doit afficher **25 sketches**.
2. Tester 017 + 020 d'abord pour comparer la fluidité après optimisation.
3. Regarder 021–025 20–30 secondes aux defaults.
4. Interagir, relâcher, regarder les conséquences physiques/chimiques continuer.
5. Explorer ensuite les contrôles.
6. Tester les meilleurs sur PROGRAM/touch.
7. Fermer normalement puis lire immédiatement la télémétrie fraîche.
8. Exiger que la télémétrie corresponde au HEAD testé avant d'attribuer une chute FPS.

Préserve Gallery/PREVIEW/PROGRAM, TAKE LIVE, persistence, touch, live-sync et telemetry. Ne merge jamais `main` sans accord explicite.

## Règle obligatoire de fin de tâche

Après toute modification matérielle : finir les commits/pushs, mettre à jour la continuité durable, résoudre le HEAD distant final après tous les commits, attendre la CI de ce SHA exact, donner short SHA + CI, fournir automatiquement le PowerShell canonique de `OPERATIONS.md` si un test Windows est pertinent, puis telemetry-first après le test.

---
