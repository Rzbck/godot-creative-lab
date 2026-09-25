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
7. `docs/SKETCH_CONTRACT.md`

Après tout retour de test, inspecte d'abord `telemetry/runtime` et vérifie que HEAD/session correspondent au test avant d'attribuer FPS ou layout.

## Architecture produit actuelle

Top runtime :

`app/main/main_runtime_gallery_feedback_trash.gd`

Il étend :

`gallery_feedback_trash -> gallery_adaptive_filters -> gallery_organizer -> program_output -> gallery_persistence -> live_output -> ...`

Préserve PREVIEW/PROGRAM, TAKE LIVE, PROGRAM persistant pendant navigation, touch physical output, live-sync, persistence et télémétrie async.

## Contrat plein-canvas — obligatoire

Un bug hôte sur 025 FARADAY QUASI a montré un PREVIEW 1520×852 correct mais un `ShaderSurface` fixé à 1280×720, laissant du gris à droite/en bas.

Règle maintenant obligatoire :

- une surface nommée `ShaderSurface` doit utiliser `res://sketches/_shared/full_canvas_surface.gd`;
- la taille logique 1280×720 ne doit jamais devenir une taille physique fixe de surface;
- `scripts/ci/validate_repository.py` bloque les scènes `ShaderSurface` sans composant partagé ou avec offsets fixes 1280/720;
- le host a aussi un fallback runtime et émet `sketch_surface_contract` avec coverage/pass.

Ne contourne pas cette règle sketch par sketch. Si un futur rendu plein-canvas utilise un autre nom/representation, ajoute un contrat/test équivalent plutôt que réintroduire une surface fixe.

## REVIEW — préférence utilisateur structurée

Chaque sketch ouvert expose six notes 1–5 :

- VISUAL
- INTERACTION
- ORIGINALITY
- ALIVENESS
- CONTROLS
- PERFORMANCE

Persistées dans `user://creative_lab_reviews.cfg`.

Chaque changement émet `sketch_review_changed` avec les scores et la moyenne; les cartes notées affichent `R x.x`.

**Utilise ces notes comme données créatives prioritaires** pour améliorer les sketches existants et orienter les prochains tirages/concepts. Si la télémétrie contient des ratings explicites, ne remplace pas ces données par une intuition vague sur les goûts du user.

## TRASH / curation

`MOVE TO TRASH` masque immédiatement un sketch de la Gallery locale.

- config : `user://creative_lab_curation.cfg`;
- `TRASH n` apparaît si nécessaire;
- RESTORE disponible;
- rétention 7/14/30 jours, default 30;
- expiration ou PURGE -> état local `retired`.

Important : PURGE ne supprime **pas** les fichiers source Git. Le runtime ne doit pas supprimer `res://sketches/...`. Une vraie suppression du repo reste une action Git explicite après décision humaine.

Ne ressuscite pas automatiquement les sketches localement retired dans l'UI.

## Gallery tags

Ne restaure pas le mur de tags.

- ALL toujours visible;
- max 6 quick tags générés;
- universels masqués;
- rares/restants sous MORE;
- rare actif promu;
- recherche indexe tous les tags;
- groupe primaire = premier tag de definition.json.

## Direction créative

Méthode courante : collision-first.

Lire en priorité :

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
- `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
- `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
- `knowledge/cross-domain/PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
- `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
- `knowledge/cross-domain/REALTIME_PERFORMANCE_BUDGET.md`
- atlases design/creative-coding pertinents.

Règles : diversité technique réelle; coupling interne; 6–9 contrôles indépendants quand pertinent; plusieurs échelles de temps; default visuel cohérent; interaction qui modifie le futur du système; science utilisée par causalité, pas seulement par look; performance pensée dès la représentation.

005 reste REGISTER TYPE, jamais Pressure Lattice. La passe contours généralisée `6c20a094...` est rejetée.

## Corpus actuel

Source catalogue : 25 sketches.

021–025 : ROSENSWEIG FIELD, LIESEGANG FRONT, SPINODAL MARANGONI, GRANULAR JAM, FARADAY QUASI.

017 et 020 ont déjà été optimisés via champs ImageTexture/cached neighbour data.

## Prochaine opération

Test hôte des nouvelles briques produit + poursuite du test créatif :

1. ouvrir 025 en workstation maximisée : aucune zone grise; le render couvre le PREVIEW 1520×852;
2. resize/maximize + tester 025, 021, 005;
3. F11 sur shader plein-canvas;
4. noter plusieurs critères d'un sketch, revenir Gallery, vérifier badge et persistance;
5. déplacer un sketch non critique dans Trash, vérifier disparition + TRASH, puis RESTORE;
6. poursuivre jugement artistique/perf de 021–025;
7. fermer normalement;
8. lire immédiatement télémétrie fraîche : `sketch_surface_contract`, `sketch_review_changed`, trash events, perf/session.

## Règle obligatoire de fin de tâche

Après toute modification matérielle : finir commits/pushs, mettre à jour continuité durable, résoudre HEAD final après tous les commits, attendre la CI de ce SHA exact, donner short SHA + CI, fournir automatiquement le PowerShell canonique de `OPERATIONS.md` si test Windows pertinent, puis telemetry-first après le test.

Ne merge jamais `main` sans accord explicite.

---
