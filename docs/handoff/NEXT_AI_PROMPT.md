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

Après un test hôte, inspecte `telemetry/runtime` avant de demander logs/captures. Vérifie que la session correspond au HEAD testé.

## Important — notes utilisateur

Le REVIEW est maintenant compact via `app/main/main_runtime_gallery_compact_review.gd` : une ligne REVIEW/average/RATE/TRASH, avec les six axes dans un popup.

Lis en priorité l’événement `creative_preference_snapshot`, qui contient l’état consolidé des notes explicites. Ne reconstruis pas inutilement les préférences depuis des clics fragmentés si ce snapshot existe.

Les notes servent de **preuve et de biais modéré**, pas de classement à cloner. Conserve une vraie exploration.

## Important — qualité temporelle

Le user rejette explicitement les boucles visibles cheap / respiration-bobbing de type `sin(time)` utilisées seulement pour faire bouger une œuvre.

Lire :

`knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`

Règle :

`time -> état/force/mémoire/événement -> système couplé -> rendu`

plutôt que :

`time -> sin/cos -> position/scale/alpha/warp visible`.

Une oscillation physique/conceptuelle reste autorisée (Faraday par exemple). À partir de 026, tout trigonométrie directe sur `sketch_time`, `u_time` ou shader `TIME` doit porter un commentaire `TEMPORAL_INTENT:` expliquant pourquoi.

CI : `scripts/ci/audit_temporal_motion.py`.

Le premier audit complet a trouvé 38 observations historiques dans <=025. Certaines périodes fixes sont seulement des cadences de simulation : ne traite pas tout warning comme un défaut visuel.

Refactors actuels :

- 021 ROSENSWEIG : auto-magnet target/dwell variable, plus de Lissajous/orbite temporelle directe.
- 022 LIESEGANG : épuisement/repos/recharge de réservoir, plus de gros front qui snap-reset visiblement.
- 024 GRANULAR JAM : creep selon stress/vitesse/confinement/asymétrie, avalanche indexée par événement.
- 025 FARADAY : forcing périodique intentionnel conservé, chirp stateful variable, ripple tactile décoratif temporel retiré.

## Important — prochain tirage créatif

Utilise le nouveau système adaptatif :

- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `knowledge/cross-domain/creative_draw_space.json`
- `scripts/creative/draw_recipe.py`

Il choisit carrier + 2 représentations de familles différentes + 2 opérateurs de familles différentes + modèle temporel + interaction + contrainte design + render path.

Il pénalise la répétition historique/récente. Les notes explicites peuvent biaiser légèrement les probabilités, mais 24% des tirages ignorent entièrement le biais de préférence pour préserver la découverte.

Pour tout sketch 026+, `definition.json` doit contenir `creative_signature`. Ne stocke dans l’historique que les concepts effectivement implémentés/conservés.

Ne prends jamais le tirage brut comme concept final : `draw -> prototype couplé -> observe -> interprète -> art-direct -> mutate`.

## Historique / non-régressions

- 005 reste visuellement **REGISTER TYPE**, jamais Pressure Lattice.
- ne restaure pas le contour-glyph généralisé `6c20a094...` comme représentation maison.
- ne restaure pas le mur permanent de tags.
- `ShaderSurface` plein-canvas obligatoire via `sketches/_shared/full_canvas_surface.gd`.
- navigation ne stoppe pas PROGRAM ; TAKE LIVE, touch, live-sync et telemetry restent stables.
- pas de faux Spout/NDI.

## Prochaine opération

Test hôte :

1. vérifier que REVIEW ne prend plus la hauteur du panneau paramètres ;
2. RATE ouvre le popup, notes persistantes + badge Gallery ;
3. fermer normalement pour publier `creative_preference_snapshot` complet ;
4. regarder 021 ~60 s pour vérifier disparition du mouvement analytique répétitif ;
5. suivre 022 pendant épuisement/repos/recharge ;
6. charger/relâcher 024 et juger creep/avalanche ;
7. tester 025 et distinguer oscillation Faraday légitime de l’ancien habillage périodique ;
8. continuer à noter les œuvres selon chaque axe ;
9. ensuite telemetry-first et décider quels warnings historiques méritent un refactor selon notes + identité.

Après toute modification matérielle : terminer commits/docs, résoudre HEAD final, attendre CI du SHA exact, donner short SHA + CI et le PowerShell canonique de `OPERATIONS.md` si test Windows pertinent.
