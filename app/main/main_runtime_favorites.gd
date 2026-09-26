extends "res://app/main/main_runtime_gallery_host_fixes.gd"

# Durable positive-curation signal layered after the validated host fixes.
# Favorites are local/user-owned, survive restarts, appear in Gallery badges,
# and publish explicit telemetry so future creative passes can distinguish
# "I like this / this has potential" from a numeric review alone.

const FAVORITES_REVISION: int = 1
const FAVORITE_SEED_REVISION: int = 1
const FAVORITE_SEED_ID: String = "054_hinge_choir"

var _favorite_button: Button = null


func _ready() -> void:
    super._ready()
    _ensure_favorite_seed()
    _refresh_all_favorite_badges()


func _append_review_controls(sketch_id: String) -> void:
    super._append_review_controls(sketch_id)

    _favorite_button = Button.new()
    _favorite_button.name = "FavoriteButton"
    _favorite_button.focus_mode = Control.FOCUS_NONE
    _favorite_button.toggle_mode = true
    _favorite_button.theme_type_variation = &"ToolButton"
    _favorite_button.tooltip_text = "Mark as a favorite / high-potential sketch. This is published with preference telemetry."
    _favorite_button.pressed.connect(_on_favorite_pressed.bind(sketch_id))
    parameter_list.add_child(_favorite_button)
    _refresh_favorite_button(sketch_id)


func _ensure_favorite_seed() -> void:
    if not _curation_loaded:
        return
    var seeded_revision := int(_curation_config.get_value("settings", "favorite_seed_revision", 0))
    if seeded_revision >= FAVORITE_SEED_REVISION:
        return

    # Explicit host request: HINGE CHOIR starts favorited even though it still
    # needs a deeper physics pass. This migration runs once; the user can
    # un-favorite it afterwards without the app forcing it back on.
    _curation_config.set_value("favorites", FAVORITE_SEED_ID, true)
    _curation_config.set_value("settings", "favorite_seed_revision", FAVORITE_SEED_REVISION)
    _save_curation_config()
    _telemetry_event("sketch_favorite_changed", {
        "sketch_id": FAVORITE_SEED_ID,
        "favorite": true,
        "reason": "host_seed",
        "favorite_count": _favorite_count(),
    })


func _is_favorite(sketch_id: String) -> bool:
    if not _curation_loaded or sketch_id.is_empty():
        return false
    return bool(_curation_config.get_value("favorites", sketch_id, false))


func _favorite_ids() -> Array[String]:
    var ids: Array[String] = []
    if not _curation_loaded or not _curation_config.has_section("favorites"):
        return ids
    for sketch_id: String in _curation_config.get_section_keys("favorites"):
        if bool(_curation_config.get_value("favorites", sketch_id, false)):
            ids.append(sketch_id)
    ids.sort()
    return ids


func _favorite_count() -> int:
    return _favorite_ids().size()


func _set_favorite(sketch_id: String, favorite: bool) -> void:
    if not _curation_loaded or sketch_id.is_empty():
        return
    if favorite:
        _curation_config.set_value("favorites", sketch_id, true)
    elif _curation_config.has_section_key("favorites", sketch_id):
        _curation_config.erase_section_key("favorites", sketch_id)
    _save_curation_config()


func _on_favorite_pressed(sketch_id: String) -> void:
    var next_favorite := not _is_favorite(sketch_id)
    _set_favorite(sketch_id, next_favorite)
    _refresh_favorite_button(sketch_id)
    _refresh_review_badge(sketch_id)

    _telemetry_event("sketch_favorite_changed", {
        "sketch_id": sketch_id,
        "favorite": next_favorite,
        "favorite_count": _favorite_count(),
    })
    _schedule_review_checkpoint("favorite")


func _refresh_favorite_button(sketch_id: String) -> void:
    if not is_instance_valid(_favorite_button):
        return
    var favorite := _is_favorite(sketch_id)
    _favorite_button.set_pressed_no_signal(favorite)
    _favorite_button.text = "★ FAVORITE / POTENTIAL" if favorite else "☆ ADD FAVORITE / POTENTIAL"


func _refresh_review_badge(sketch_id: String) -> void:
    super._refresh_review_badge(sketch_id)
    if not _review_badges.has(sketch_id):
        return
    var badge := _review_badges[sketch_id] as Label
    if not is_instance_valid(badge):
        return

    var favorite := _is_favorite(sketch_id)
    var average := _review_average(_review_for(sketch_id))
    badge.visible = favorite or average > 0.0
    if favorite and average > 0.0:
        badge.text = "★  R %.1f" % average
    elif favorite:
        badge.text = "★"
    elif average > 0.0:
        badge.text = "R %.1f" % average
    else:
        badge.text = ""


func _refresh_all_favorite_badges() -> void:
    for sketch_id_variant: Variant in _review_badges.keys():
        _refresh_review_badge(str(sketch_id_variant))


func _emit_preference_snapshot(reason: String) -> void:
    super._emit_preference_snapshot(reason)
    _emit_favorite_snapshot(reason)


func _emit_favorite_snapshot(reason: String) -> void:
    if not _curation_loaded:
        return

    var favorites: Dictionary = {}
    for sketch_id: String in _favorite_ids():
        var entry: Dictionary = {}
        var definition_variant: Variant = _all_catalog_definitions.get(sketch_id, {})
        if definition_variant is Dictionary:
            var definition := definition_variant as Dictionary
            entry["title"] = str(definition.get("title", sketch_id))
            entry["tags"] = definition.get("tags", [])
            if definition.has("creative_signature"):
                entry["creative_signature"] = definition.get("creative_signature")
        favorites[sketch_id] = entry

    _telemetry_event("creative_favorite_snapshot", {
        "reason": reason,
        "favorites_revision": FAVORITES_REVISION,
        "favorite_count": favorites.size(),
        "favorites": favorites,
    })


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched := data.duplicate(true)
    enriched["favorites_revision"] = FAVORITES_REVISION
    super._telemetry_event(event_name, enriched)
