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

Après tout test hôte, inspecte `telemetry/runtime` **avant** de demander logs/captures et avant de créer le batch suivant.

## Priorité actuelle

Le dernier test hôte concernait HEAD `a55c65c6...`.

Retours directs :
- LIST était beaucoup trop haut (132 px) : le user veut une vraie liste compacte, avec preview utilisée en background décoratif sur une partie de la ligne.
- il veut NEXT/PREV directement dans l'écran sketch.
- il a écrit de nombreux commentaires RATE et ne veut plus devoir les recopier dans le chat.
- 041 TENSION ORGAN spammait `Invalid polygon data, triangulation failed` dans `_draw()`.

## Patch implémenté

Références code avant docs :
- `21d31984...` : host layer revision 2, LIST compact + PREV/NEXT + startup review republish.
- `df9710ae...` : 041 cellules rendues en triangles explicites sûrs.
- `0c360c358e4b08fc456ba158fd35d6f62e18a253` : sanitizer telemetry conserve désormais les written reviews.
- CI code #312 : GREEN complet.

### LIST revision 2

- hauteur = 68 px;
- preview réelle réutilisée à faible alpha comme fond sur la partie droite de la ligne;
- pas de grosse vignette séparée;
- index/titre/méta en overlay compact;
- GRID inchangé;
- TRASH reste exclusif.

### PREV / NEXT

ProjectToolbar contient `‹ PREV` / `NEXT ›`.
- ordre numérique global des sketches actuellement browsables;
- trash local sauté;
- pas de wrap;
- boutons désactivés aux limites;
- switching par `_open_sketch()` normal : PROGRAM ne doit jamais être remplacé par cette navigation.

### 041

Le quad dynamique à 4 points était parfois concave/inversé, donc RenderingServer ne pouvait pas le trianguler.
Maintenant chaque cellule choisit sa diagonale la plus courte, dessine deux triangles explicites et ignore les triangles quasi nuls. La physique n'a pas changé.

## Written RATE — règle de travail obligatoire

Le remote de l'ancienne version contient bien les checkpoints et les notes numériques, mais l'ancien sanitizer retirait la string `note`. Les événements `sketch_review_note_changed` ne conservaient donc que `note_length`.

Le nouveau sanitizer :
- autorise explicitement `note`, max 2000 chars;
- nettoie les caractères de contrôle;
- garde les identifiants/signatures créatives utiles;
- refuse de publier un fichier sanitized vide.

Les commentaires sont déjà stockés localement dans `user://creative_lab_reviews.cfg`. Host layer revision 2 planifie un checkpoint au startup. **Au prochain test, vérifie que les anciens commentaires apparaissent réellement dans `creative_preference_snapshot.reviews.<sketch>.note` sans re-saisie.**

À partir de maintenant, les written reviews sont une source de premier rang :
- les lire avec les ratings numériques avant toute réparation ou nouvelle génération;
- en extraire le pourquoi des faibles/bonnes notes;
- corriger les sketches concernés quand le commentaire est actionnable;
- faire évoluer les règles durables si le même retour se répète;
- ne jamais demander au user de recoller dans le chat un commentaire déjà présent dans RATE/telemetry;
- ne jamais inventer le contenu d'un commentaire absent du remote.

## Evidence actuelle

Dernier snapshot remote lisible :
- 036 ~1.83
- 037 ~2.33
- 038 ~2.67, visual 4/originality 4 — meilleur signal récent, mais interaction/controls faibles
- 039 ~2.17
- 040 2.0
- 043 1.0
- 044 2.0
- 045 1.0

041/042 ne doivent pas être inventés s'ils ne sont pas présents dans le snapshot suivant.

## Catalogue / creative contract

Catalogue source : **001–045**.
Lire :
- `knowledge/cross-domain/VISUAL_FINISH_GATE.md`
- `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `knowledge/cross-domain/creative_draw_space.json`

Toujours :
`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Pas de coarse solver agrandi, generic clock wobble, phase wrap/reset visible, pointer overlay superficiel, ou diversité technique prise pour une réussite artistique.

## Non-régressions

- 005 reste visible **REGISTER TYPE**; ne jamais restaurer Pressure Lattice.
- pas de contour-glyph généralisé.
- pas de mur permanent de tags.
- ShaderSurface plein canvas obligatoire.
- ShaderMaterial stateful toujours local à la scène.
- navigation Gallery/PREV/NEXT ne stoppe pas PROGRAM.
- TAKE LIVE, physical output input et linked-state sync restent stables.
- RATE reste modal opaque/centré/in-app.
- pas de `Window.visible=false/true` au startup.
- pas de faux Spout/NDI.

## Prochaine validation hôte

1. sync HEAD final + attendre CI exacte;
2. LIST compact / preview background;
3. PREV/NEXT sur plusieurs sketches, vérifier PROGRAM inchangé;
4. stress 041, vérifier zéro triangulation error;
5. ne pas retaper les reviews : laisser le startup checkpoint partir;
6. telemetry-first : confirmer que les vraies strings `note` sont présentes;
7. utiliser ces commentaires avant le prochain batch créatif.

Après toute modification matérielle : code/push -> docs/state -> résoudre HEAD final -> attendre CI exacte -> rapporter SHA/CI -> PowerShell canonique si test hôte pertinent -> telemetry-first après test.
