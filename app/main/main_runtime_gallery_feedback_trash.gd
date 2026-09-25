extends "res://app/main/main_runtime_gallery_adaptive_filters.gd"

# User curation layer: durable multi-axis reviews + reversible local trash.
# Reviews are persisted locally and emitted as numeric telemetry so future AI
# sessions can learn from actual host preference signals. Trash never mutates
# version-controlled res:// source files from inside Godot; it controls local
# Gallery visibility, supports restore, and becomes locally retired after the
# configured retention period.

const GALLERY_CURATION_REVISION: int = 1
const REVIEW_PATH: String = "user://creative_lab_reviews.cfg"
const CURATION_PATH: String = "user://creative_lab_curation.cfg"
const DEFAULT_TRASH_RETENTION_DAYS: int = 30
const REVIEW_CRITERIA = [
    "visual",
    "interaction",
    "originality",
    "aliveness",
    "controls",
    "performance",
]

var _review_config := ConfigFile.new()
var _curation_config := ConfigFile.new()
var _review_loaded: bool = false
var _curation_loaded: bool = false
var _all_catalog_definitions: Dictionary = {}
var _review_score_buttons: Dictionary = {}
var _review_average_label: Label = null
var _review_badges: Dictionary = {}

var _gallery_trash_drawer: VBoxContainer = null
var _gallery_trash_button: Button = null
var _gallery_trash_drawer_open: bool = false


func _ready() -> void:
    _load_review_config()
    _load_curation_config()
    super._ready()
    _ensure_gallery_trash_drawer()
    _rebuild_gallery_tag_filters()
    _telemetry_event("gallery_curation_ready", {
        "reviewed_count": _reviewed_sketch_count(),
        "trash_count": _trash_count(),
        "retention_days": _trash_retention_days(),
    })


func _load_review_config() -> void:
    _review_config = ConfigFile.new()
    var error := _review_config.load(REVIEW_PATH)
    if error != OK and error != ERR_FILE_NOT_FOUND:
        push_warning("Could not load sketch reviews: error %d" % int(error))
    _review_loaded = error == OK or error == ERR_FILE_NOT_FOUND


func _load_curation_config() -> void:
    _curation_config = ConfigFile.new()
    var error := _curation_config.load(CURATION_PATH)
    if error != OK and error != ERR_FILE_NOT_FOUND:
        push_warning("Could not load Gallery curation: error %d" % int(error))
    _curation_loaded = error == OK or error == ERR_FILE_NOT_FOUND
    if _curation_loaded and not _curation_config.has_section_key("settings", "retention_days"):
        _curation_config.set_value("settings", "retention_days", DEFAULT_TRASH_RETENTION_DAYS)
        _save_curation_config()


func _load_catalog() -> void:
    super._load_catalog()

    _all_catalog_definitions.clear()
    for definition: Dictionary in _catalog:
        var sketch_id := str(definition.get("id", ""))
        if not sketch_id.is_empty():
            _all_catalog_definitions[sketch_id] = definition.duplicate(true)

    _expire_trash_entries()

    var visible_catalog: Array[Dictionary] = []
    for definition: Dictionary in _catalog:
        var sketch_id := str(definition.get("id", ""))
        if not _is_locally_removed(sketch_id):
            visible_catalog.append(definition)
    _catalog = visible_catalog


func _build_gallery() -> void:
    _review_badges.clear()
    super._build_gallery()
    _ensure_gallery_trash_drawer()
    _rebuild_gallery_trash_drawer()


func _build_gallery_preview_card(definition: Dictionary) -> void:
    super._build_gallery_preview_card(definition)

    var sketch_id := str(definition.get("id", ""))
    if sketch_id.is_empty() or not _gallery_previews.has(sketch_id):
        return

    var entry: Dictionary = _gallery_previews[sketch_id]
    var card := entry.get("card") as Button
    var preview_sketch := entry.get("sketch") as Node
    if is_instance_valid(preview_sketch):
        _sync_named_full_canvas_surfaces(preview_sketch, Vector2(GALLERY_PREVIEW_SIZE))

    if not is_instance_valid(card):
        return

    var badge := Label.new()
    badge.name = "ReviewBadge"
    badge.theme_type_variation = &"MicroLabel"
    badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    badge.anchor_left = 1.0
    badge.anchor_right = 1.0
    badge.offset_left = -66.0
    badge.offset_right = -10.0
    badge.offset_top = 8.0
    badge.offset_bottom = 26.0
    card.add_child(badge)
    _review_badges[sketch_id] = badge
    _refresh_review_badge(sketch_id)


func _sync_preview_resolution(force: bool = false) -> void:
    super._sync_preview_resolution(force)
    if is_instance_valid(_active_sketch):
        _sync_named_full_canvas_surfaces(_active_sketch, Vector2(sketch_viewport.size))


func _sync_named_full_canvas_surfaces(root: Node, target_size: Vector2) -> void:
    if not is_instance_valid(root) or target_size.x <= 0.0 or target_size.y <= 0.0:
        return
    var matches := root.find_children("ShaderSurface", "ColorRect", true, false)
    for node: Node in matches:
        var surface := node as ColorRect
        if not is_instance_valid(surface):
            continue
        if surface.has_method("sync_to_viewport"):
            surface.call("sync_to_viewport", true)
        else:
            # Host-side fallback. CI requires the shared component for new code,
            # but old/user content should still never expose a broken viewport.
            surface.position = Vector2.ZERO
            surface.size = target_size


func _open_sketch(definition: Dictionary) -> void:
    var sketch_id := str(definition.get("id", ""))
    if _is_locally_removed(sketch_id):
        status_label.text = "SKETCH IS IN TRASH / RESTORE FROM GALLERY"
        return
    super._open_sketch(definition)
    call_deferred("_report_active_surface_contract")


func _report_active_surface_contract() -> void:
    await get_tree().process_frame
    if not is_instance_valid(_active_sketch):
        return

    var target := Vector2(sketch_viewport.size)
    _sync_named_full_canvas_surfaces(_active_sketch, target)
    var min_coverage := 1.0
    var surface_count := 0
    var matches := _active_sketch.find_children("ShaderSurface", "ColorRect", true, false)
    for node: Node in matches:
        var surface := node as ColorRect
        if not is_instance_valid(surface):
            continue
        surface_count += 1
        var coverage_x := surface.size.x / maxf(1.0, target.x)
        var coverage_y := surface.size.y / maxf(1.0, target.y)
        min_coverage = minf(min_coverage, minf(coverage_x, coverage_y))

    _telemetry_event("sketch_surface_contract", {
        "sketch_id": str(_active_definition.get("id", "")),
        "surface_count": surface_count,
        "viewport_size": [int(target.x), int(target.y)],
        "min_coverage": min_coverage,
        "pass": surface_count == 0 or min_coverage >= 0.995,
    })


func _build_parameter_inspector(sketch: Node) -> void:
    super._build_parameter_inspector(sketch)
    var sketch_id := str(_active_definition.get("id", ""))
    if sketch_id.is_empty():
        return
    _append_review_controls(sketch_id)


func _append_review_controls(sketch_id: String) -> void:
    _review_score_buttons.clear()
    _review_average_label = null

    parameter_list.add_child(HSeparator.new())

    var review_header := HBoxContainer.new()
    var title := Label.new()
    title.theme_type_variation = &"AccentLabel"
    title.text = "REVIEW"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    review_header.add_child(title)

    _review_average_label = Label.new()
    _review_average_label.theme_type_variation = &"MicroLabel"
    review_header.add_child(_review_average_label)
    parameter_list.add_child(review_header)

    var hint := Label.new()
    hint.theme_type_variation = &"MicroLabel"
    hint.text = "YOUR SCORES FEED FUTURE CREATIVE ITERATIONS"
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parameter_list.add_child(hint)

    var review := _review_for(sketch_id)
    for criterion: String in REVIEW_CRITERIA:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 4)

        var label := Label.new()
        label.theme_type_variation = &"MicroLabel"
        label.text = criterion.to_upper()
        label.custom_minimum_size = Vector2(86.0, 0.0)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)

        var row_buttons: Array[Button] = []
        for score: int in range(1, 6):
            var button := Button.new()
            button.text = str(score)
            button.custom_minimum_size = Vector2(25.0, 22.0)
            button.focus_mode = Control.FOCUS_NONE
            button.toggle_mode = true
            button.theme_type_variation = &"ToolButton"
            button.set_pressed_no_signal(int(review.get(criterion, 0)) == score)
            button.pressed.connect(_on_review_score_pressed.bind(sketch_id, criterion, score))
            row.add_child(button)
            row_buttons.append(button)
        _review_score_buttons[criterion] = row_buttons
        parameter_list.add_child(row)

    _refresh_active_review_summary(sketch_id)

    var trash_button := Button.new()
    trash_button.text = "MOVE TO TRASH"
    trash_button.focus_mode = Control.FOCUS_NONE
    trash_button.theme_type_variation = &"ToolButton"
    trash_button.tooltip_text = "Hide from this workstation Gallery. Restore before automatic purge."
    trash_button.pressed.connect(_on_move_active_to_trash.bind(sketch_id))
    parameter_list.add_child(trash_button)


func _review_section(sketch_id: String) -> String:
    return "review_%s" % sketch_id


func _review_for(sketch_id: String) -> Dictionary:
    var result: Dictionary = {}
    if not _review_loaded:
        return result
    var section := _review_section(sketch_id)
    for criterion: String in REVIEW_CRITERIA:
        result[criterion] = clampi(int(_review_config.get_value(section, criterion, 0)), 0, 5)
    return result


func _review_average(review: Dictionary) -> float:
    var total := 0.0
    var count := 0
    for criterion: String in REVIEW_CRITERIA:
        var score := int(review.get(criterion, 0))
        if score > 0:
            total += float(score)
            count += 1
    return 0.0 if count == 0 else total / float(count)


func _on_review_score_pressed(sketch_id: String, criterion: String, score: int) -> void:
    if not _review_loaded:
        return
    var section := _review_section(sketch_id)
    var current := int(_review_config.get_value(section, criterion, 0))
    var next_score := 0 if current == score else score
    _review_config.set_value(section, criterion, next_score)
    var error := _review_config.save(REVIEW_PATH)
    if error != OK:
        push_warning("Could not save sketch review: error %d" % int(error))
        return

    var buttons_variant: Variant = _review_score_buttons.get(criterion, [])
    if buttons_variant is Array:
        var buttons := buttons_variant as Array
        for index: int in range(buttons.size()):
            var button := buttons[index] as Button
            if is_instance_valid(button):
                button.set_pressed_no_signal(next_score == index + 1)

    _refresh_active_review_summary(sketch_id)
    _refresh_review_badge(sketch_id)

    var review := _review_for(sketch_id)
    _telemetry_event("sketch_review_changed", {
        "sketch_id": sketch_id,
        "criterion": criterion,
        "score": next_score,
        "ratings": review,
        "average": _review_average(review),
    })


func _refresh_active_review_summary(sketch_id: String) -> void:
    if not is_instance_valid(_review_average_label):
        return
    var review := _review_for(sketch_id)
    var average := _review_average(review)
    var rated := 0
    for criterion: String in REVIEW_CRITERIA:
        if int(review.get(criterion, 0)) > 0:
            rated += 1
    _review_average_label.text = "—" if rated == 0 else "%.1f / 5  (%d/6)" % [average, rated]


func _refresh_review_badge(sketch_id: String) -> void:
    if not _review_badges.has(sketch_id):
        return
    var badge := _review_badges[sketch_id] as Label
    if not is_instance_valid(badge):
        return
    var average := _review_average(_review_for(sketch_id))
    badge.visible = average > 0.0
    badge.text = "R %.1f" % average if average > 0.0 else ""


func _reviewed_sketch_count() -> int:
    if not _review_loaded:
        return 0
    var count := 0
    for section: String in _review_config.get_sections():
        if not section.begins_with("review_"):
            continue
        if _review_average(_review_for(section.trim_prefix("review_"))) > 0.0:
            count += 1
    return count


func _trash_retention_days() -> int:
    if not _curation_loaded:
        return DEFAULT_TRASH_RETENTION_DAYS
    return clampi(int(_curation_config.get_value("settings", "retention_days", DEFAULT_TRASH_RETENTION_DAYS)), 1, 365)


func _trash_count() -> int:
    if not _curation_loaded or not _curation_config.has_section("trash"):
        return 0
    return _curation_config.get_section_keys("trash").size()


func _is_locally_removed(sketch_id: String) -> bool:
    if not _curation_loaded or sketch_id.is_empty():
        return false
    return _curation_config.has_section_key("trash", sketch_id) \
        or _curation_config.has_section_key("retired", sketch_id)


func _save_curation_config() -> void:
    if not _curation_loaded:
        return
    var error := _curation_config.save(CURATION_PATH)
    if error != OK:
        push_warning("Could not save Gallery curation: error %d" % int(error))


func _expire_trash_entries() -> void:
    if not _curation_loaded or not _curation_config.has_section("trash"):
        return
    var now := int(Time.get_unix_time_from_system())
    var max_age := _trash_retention_days() * 86400
    var changed := false
    for sketch_id: String in _curation_config.get_section_keys("trash"):
        var trashed_at := int(_curation_config.get_value("trash", sketch_id, now))
        if now - trashed_at < max_age:
            continue
        _curation_config.erase_section_key("trash", sketch_id)
        _curation_config.set_value("retired", sketch_id, now)
        changed = true
    if changed:
        _save_curation_config()


func _rebuild_gallery_tag_filters() -> void:
    super._rebuild_gallery_tag_filters()
    _ensure_gallery_trash_drawer()
    _append_gallery_trash_button()


func _append_gallery_trash_button() -> void:
    if not is_instance_valid(_gallery_tag_flow):
        return
    if is_instance_valid(_gallery_trash_button):
        _gallery_trash_button.queue_free()
    _gallery_trash_button = null

    var count := _trash_count()
    if count <= 0:
        _gallery_trash_drawer_open = false
        if is_instance_valid(_gallery_trash_drawer):
            _gallery_trash_drawer.visible = false
        return

    _gallery_trash_button = Button.new()
    _gallery_trash_button.custom_minimum_size = Vector2(0.0, 24.0)
    _gallery_trash_button.focus_mode = Control.FOCUS_NONE
    _gallery_trash_button.toggle_mode = true
    _gallery_trash_button.theme_type_variation = &"ToolButton"
    _gallery_trash_button.text = "TRASH  %d" % count
    _gallery_trash_button.set_pressed_no_signal(_gallery_trash_drawer_open)
    _gallery_trash_button.pressed.connect(_on_gallery_trash_pressed)
    _gallery_tag_flow.add_child(_gallery_trash_button)


func _ensure_gallery_trash_drawer() -> void:
    if is_instance_valid(_gallery_trash_drawer) or not is_instance_valid(_gallery_filter_panel):
        return
    _gallery_trash_drawer = VBoxContainer.new()
    _gallery_trash_drawer.name = "GalleryTrashDrawer"
    _gallery_trash_drawer.visible = false
    _gallery_trash_drawer.add_theme_constant_override("separation", 5)
    _gallery_filter_panel.add_child(_gallery_trash_drawer)


func _on_gallery_trash_pressed() -> void:
    _gallery_trash_drawer_open = not _gallery_trash_drawer_open
    if _gallery_trash_drawer_open:
        _gallery_tag_drawer_open = false
        _sync_adaptive_drawer_state()
    _rebuild_gallery_trash_drawer()
    _telemetry_event("gallery_trash_drawer_changed", {
        "open": _gallery_trash_drawer_open,
        "trash_count": _trash_count(),
    })


func _rebuild_gallery_trash_drawer() -> void:
    if not is_instance_valid(_gallery_trash_drawer):
        return

    _expire_trash_entries()
    for child: Node in _gallery_trash_drawer.get_children():
        child.queue_free()

    _gallery_trash_drawer.visible = _gallery_trash_drawer_open and _trash_count() > 0
    if is_instance_valid(_gallery_trash_button):
        _gallery_trash_button.set_pressed_no_signal(_gallery_trash_drawer.visible)
        _gallery_trash_button.text = "TRASH  %d" % _trash_count()

    if not _gallery_trash_drawer.visible:
        return

    var header := HBoxContainer.new()
    var label := Label.new()
    label.theme_type_variation = &"MicroLabel"
    label.text = "TRASH / AUTO PURGE"
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(label)

    var retention := OptionButton.new()
    retention.focus_mode = Control.FOCUS_NONE
    var retention_values := [7, 14, 30]
    var current_days := _trash_retention_days()
    for index: int in range(retention_values.size()):
        var days: int = retention_values[index]
        retention.add_item("%d DAYS" % days)
        retention.set_item_metadata(index, days)
        if days == current_days:
            retention.select(index)
    retention.item_selected.connect(_on_retention_selected.bind(retention))
    header.add_child(retention)
    _gallery_trash_drawer.add_child(header)

    var now := int(Time.get_unix_time_from_system())
    var ids: Array[String] = []
    for id: String in _curation_config.get_section_keys("trash"):
        ids.append(id)
    ids.sort()

    for sketch_id: String in ids:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        var definition: Dictionary = _all_catalog_definitions.get(sketch_id, {}) as Dictionary
        var title_text := str(definition.get("title", sketch_id)).to_upper()
        var trashed_at := int(_curation_config.get_value("trash", sketch_id, now))
        var age_days := int(floor(float(maxi(0, now - trashed_at)) / 86400.0))
        var days_left := maxi(0, _trash_retention_days() - age_days)

        var item_label := Label.new()
        item_label.theme_type_variation = &"MicroLabel"
        item_label.text = "%s  /  %dD LEFT" % [title_text, days_left]
        item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        item_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        row.add_child(item_label)

        var restore := Button.new()
        restore.text = "RESTORE"
        restore.focus_mode = Control.FOCUS_NONE
        restore.theme_type_variation = &"ToolButton"
        restore.pressed.connect(_on_restore_from_trash.bind(sketch_id))
        row.add_child(restore)

        var purge := Button.new()
        purge.text = "PURGE"
        purge.focus_mode = Control.FOCUS_NONE
        purge.theme_type_variation = &"ToolButton"
        purge.tooltip_text = "Remove permanently from this workstation Gallery. Source remains versioned in Git."
        purge.pressed.connect(_on_purge_from_trash.bind(sketch_id))
        row.add_child(purge)
        _gallery_trash_drawer.add_child(row)


func _on_retention_selected(index: int, option: OptionButton) -> void:
    if not _curation_loaded:
        return
    var days := int(option.get_item_metadata(index))
    _curation_config.set_value("settings", "retention_days", days)
    _save_curation_config()
    _expire_trash_entries()
    _rebuild_gallery_trash_drawer()
    _rebuild_gallery_tag_filters()
    _telemetry_event("gallery_trash_retention_changed", {"retention_days": days})


func _on_move_active_to_trash(sketch_id: String) -> void:
    if not _curation_loaded or sketch_id.is_empty():
        return
    _curation_config.set_value("trash", sketch_id, int(Time.get_unix_time_from_system()))
    _save_curation_config()
    _telemetry_event("sketch_trashed", {
        "sketch_id": sketch_id,
        "retention_days": _trash_retention_days(),
    })
    call_deferred("_reload_gallery_after_curation")


func _on_restore_from_trash(sketch_id: String) -> void:
    if not _curation_loaded:
        return
    _curation_config.erase_section_key("trash", sketch_id)
    _save_curation_config()
    _telemetry_event("sketch_restored", {"sketch_id": sketch_id})
    call_deferred("_reload_gallery_after_curation")


func _on_purge_from_trash(sketch_id: String) -> void:
    if not _curation_loaded:
        return
    _curation_config.erase_section_key("trash", sketch_id)
    _curation_config.set_value("retired", sketch_id, int(Time.get_unix_time_from_system()))
    _save_curation_config()
    _telemetry_event("sketch_purged", {"sketch_id": sketch_id})
    call_deferred("_reload_gallery_after_curation")


func _reload_gallery_after_curation() -> void:
    _unload_active_sketch()
    _load_catalog()
    _build_gallery()
    _show_gallery()


func _show_gallery() -> void:
    super._show_gallery()
    _ensure_gallery_trash_drawer()
    _rebuild_gallery_trash_drawer()


func _close_window() -> void:
    if _review_loaded:
        _review_config.save(REVIEW_PATH)
    _save_curation_config()
    super._close_window()


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched := data.duplicate(true)
    enriched["gallery_curation_revision"] = GALLERY_CURATION_REVISION
    enriched["reviewed_sketch_count"] = _reviewed_sketch_count()
    enriched["trash_count"] = _trash_count()
    enriched["trash_retention_days"] = _trash_retention_days()
    super._telemetry_event(event_name, enriched)
