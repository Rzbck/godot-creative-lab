extends "res://app/main/main_runtime_window_memory.gd"

# Thin host-feedback layer. Keep the validated runtime chain intact and only
# override host-proven workstation UX issues. LIST stays compact/visual, TRASH
# is exclusive, sketch navigation is direct, and startup republishes durable
# review snapshots so existing written notes can reach telemetry after sanitizer
# upgrades without asking the user to type them again.

const HOST_GALLERY_FIX_REVISION: int = 2
const LIST_CARD_HEIGHT: float = 68.0
const LIST_BACKDROP_LEFT: float = 0.56

var _sketch_prev_button: Button = null
var _sketch_next_button: Button = null


func _ready() -> void:
    super._ready()
    _ensure_sketch_navigation()
    _sync_sketch_navigation()
    # Written reviews already live in user://. Republish the complete preference
    # snapshot once this host layer is running so older notes are recoverable
    # remotely after the telemetry sanitizer learns the explicit `note` field.
    _schedule_review_checkpoint("startup_republish")


func _build_gallery_preview_card(definition: Dictionary) -> void:
    super._build_gallery_preview_card(definition)

    var sketch_id := str(definition.get("id", ""))
    if sketch_id.is_empty() or not _gallery_previews.has(sketch_id):
        return

    var entry: Dictionary = _gallery_previews[sketch_id]
    var card := entry.get("card") as Button
    var viewport := entry.get("viewport") as SubViewport
    if not is_instance_valid(card) or not is_instance_valid(viewport):
        return

    var grid_content: MarginContainer = null
    for child: Node in card.get_children():
        if child is MarginContainer:
            grid_content = child as MarginContainer
            break
    if is_instance_valid(grid_content):
        grid_content.name = "GridContent"

    if card.has_node("ListContent"):
        return

    # LIST is a file-browser row, not a second card layout. The real preview is
    # reused as a low-alpha backdrop over the right side of the row, so the list
    # stays dense while still giving an immediate visual cue.
    var list_layer := Control.new()
    list_layer.name = "ListContent"
    list_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    list_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    list_layer.clip_contents = true
    list_layer.visible = false
    card.add_child(list_layer)

    var backdrop := TextureRect.new()
    backdrop.name = "ListBackdrop"
    backdrop.anchor_left = LIST_BACKDROP_LEFT
    backdrop.anchor_top = 0.0
    backdrop.anchor_right = 1.0
    backdrop.anchor_bottom = 1.0
    backdrop.offset_left = 0.0
    backdrop.offset_top = 0.0
    backdrop.offset_right = 0.0
    backdrop.offset_bottom = 0.0
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.texture = viewport.get_texture()
    backdrop.modulate = Color(0.82, 0.88, 0.94, 0.32)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    list_layer.add_child(backdrop)

    var shade := ColorRect.new()
    shade.name = "ListBackdropShade"
    shade.anchor_left = LIST_BACKDROP_LEFT
    shade.anchor_top = 0.0
    shade.anchor_right = 1.0
    shade.anchor_bottom = 1.0
    shade.offset_left = 0.0
    shade.offset_top = 0.0
    shade.offset_right = 0.0
    shade.offset_bottom = 0.0
    shade.color = Color(0.01, 0.012, 0.018, 0.34)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    list_layer.add_child(shade)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_top", 4)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_bottom", 4)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    list_layer.add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(row)

    var index_label := Label.new()
    index_label.theme_type_variation = &"MicroLabel"
    index_label.text = str(definition.get("index", "---"))
    index_label.custom_minimum_size = Vector2(42.0, 0.0)
    index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    index_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(index_label)

    var title_label := Label.new()
    title_label.theme_type_variation = &"AccentLabel"
    title_label.text = str(definition.get("title", "UNTITLED"))
    title_label.custom_minimum_size = Vector2(260.0, 0.0)
    title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(title_label)

    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(spacer)

    var tags := _definition_tags(definition)
    var meta_label := Label.new()
    meta_label.theme_type_variation = &"MicroLabel"
    meta_label.text = "%s  /  %s" % [
        str(definition.get("engine", "GODOT")),
        " / ".join(tags),
    ]
    meta_label.custom_minimum_size = Vector2(360.0, 0.0)
    meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    meta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    meta_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(meta_label)

    # Keep the review badge above the decorative list layer.
    var badge := card.get_node_or_null("ReviewBadge")
    if is_instance_valid(badge):
        card.move_child(list_layer, badge.get_index())


func _apply_gallery_card_presentation() -> void:
    super._apply_gallery_card_presentation()

    for entry_variant: Variant in _gallery_previews.values():
        if not entry_variant is Dictionary:
            continue
        var entry := entry_variant as Dictionary
        var card := entry.get("card") as Button
        if not is_instance_valid(card):
            continue

        var grid_content := card.get_node_or_null("GridContent") as MarginContainer
        var list_content := card.get_node_or_null("ListContent") as Control
        if _gallery_view_mode == "list":
            card.custom_minimum_size = Vector2(0.0, LIST_CARD_HEIGHT)
            if is_instance_valid(grid_content):
                grid_content.visible = false
            if is_instance_valid(list_content):
                list_content.visible = true
        else:
            if is_instance_valid(grid_content):
                grid_content.visible = true
            if is_instance_valid(list_content):
                list_content.visible = false


func _ensure_sketch_navigation() -> void:
    if is_instance_valid(_sketch_prev_button) and is_instance_valid(_sketch_next_button):
        return

    var toolbar := get_node_or_null(
        "Margin/Shell/Body/Workspace/WorkspaceMargin/Content/ProjectView/RenderPanel/RenderColumn/ProjectToolbar"
    ) as HBoxContainer
    if not is_instance_valid(toolbar):
        return

    var back_button := toolbar.get_node_or_null("ProjectBackButton") as Button
    if not is_instance_valid(back_button):
        return

    _sketch_prev_button = Button.new()
    _sketch_prev_button.name = "PreviousSketchButton"
    _sketch_prev_button.text = "‹ PREV"
    _sketch_prev_button.custom_minimum_size = Vector2(62.0, 24.0)
    _sketch_prev_button.focus_mode = Control.FOCUS_NONE
    _sketch_prev_button.theme_type_variation = &"ToolButton"
    _sketch_prev_button.pressed.connect(_on_adjacent_sketch_pressed.bind(-1))
    toolbar.add_child(_sketch_prev_button)
    toolbar.move_child(_sketch_prev_button, back_button.get_index() + 1)

    _sketch_next_button = Button.new()
    _sketch_next_button.name = "NextSketchButton"
    _sketch_next_button.text = "NEXT ›"
    _sketch_next_button.custom_minimum_size = Vector2(62.0, 24.0)
    _sketch_next_button.focus_mode = Control.FOCUS_NONE
    _sketch_next_button.theme_type_variation = &"ToolButton"
    _sketch_next_button.pressed.connect(_on_adjacent_sketch_pressed.bind(1))
    toolbar.add_child(_sketch_next_button)
    toolbar.move_child(_sketch_next_button, _sketch_prev_button.get_index() + 1)


func _ordered_browsable_catalog() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for definition: Dictionary in _catalog:
        result.append(definition)
    result.sort_custom(Callable(self, "_catalog_definition_before"))
    return result


func _catalog_definition_before(a: Dictionary, b: Dictionary) -> bool:
    return int(a.get("index", 0)) < int(b.get("index", 0))


func _active_catalog_index(definitions: Array[Dictionary]) -> int:
    var active_id := str(_active_definition.get("id", ""))
    if active_id.is_empty():
        return -1
    for index: int in range(definitions.size()):
        if str(definitions[index].get("id", "")) == active_id:
            return index
    return -1


func _sync_sketch_navigation() -> void:
    if not is_instance_valid(_sketch_prev_button) or not is_instance_valid(_sketch_next_button):
        return

    var definitions := _ordered_browsable_catalog()
    var current := _active_catalog_index(definitions)
    var has_active := current >= 0
    _sketch_prev_button.disabled = not has_active or current <= 0
    _sketch_next_button.disabled = not has_active or current >= definitions.size() - 1

    _sketch_prev_button.tooltip_text = "Previous sketch"
    _sketch_next_button.tooltip_text = "Next sketch"
    if has_active and current > 0:
        _sketch_prev_button.tooltip_text = "Previous / %s" % str(definitions[current - 1].get("title", "")).to_upper()
    if has_active and current + 1 < definitions.size():
        _sketch_next_button.tooltip_text = "Next / %s" % str(definitions[current + 1].get("title", "")).to_upper()


func _on_adjacent_sketch_pressed(direction: int) -> void:
    var definitions := _ordered_browsable_catalog()
    var current := _active_catalog_index(definitions)
    if current < 0:
        return
    var target := current + direction
    if target < 0 or target >= definitions.size():
        return
    _telemetry_event("sketch_adjacent_navigation", {
        "direction": direction,
        "from_index": int(definitions[current].get("index", 0)),
        "to_index": int(definitions[target].get("index", 0)),
    })
    _open_sketch(definitions[target])


func _open_sketch(definition: Dictionary) -> void:
    super._open_sketch(definition)
    _sync_sketch_navigation()


func _on_gallery_trash_pressed() -> void:
    _gallery_trash_drawer_open = not _gallery_trash_drawer_open
    if _gallery_trash_drawer_open:
        _gallery_tag_drawer_open = false
        _sync_adaptive_drawer_state()
        _freeze_all_gallery_previews()
    _rebuild_gallery_trash_drawer()
    _sync_host_trash_mode()
    _telemetry_event("gallery_trash_drawer_changed", {
        "open": _gallery_trash_drawer_open,
        "trash_count": _trash_count(),
        "exclusive_mode": true,
    })


func _rebuild_gallery_trash_drawer() -> void:
    super._rebuild_gallery_trash_drawer()
    if _trash_count() <= 0:
        _gallery_trash_drawer_open = false
    _sync_host_trash_mode()


func _on_gallery_tag_pressed(tag: String) -> void:
    if _gallery_trash_drawer_open:
        _gallery_trash_drawer_open = false
        _rebuild_gallery_trash_drawer()
        _sync_host_trash_mode()
    super._on_gallery_tag_pressed(tag)


func _on_gallery_more_pressed() -> void:
    if _gallery_trash_drawer_open:
        _gallery_trash_drawer_open = false
        _rebuild_gallery_trash_drawer()
        _sync_host_trash_mode()
    super._on_gallery_more_pressed()


func _show_gallery() -> void:
    super._show_gallery()
    _sync_host_trash_mode()
    _sync_sketch_navigation()


func _sync_host_trash_mode() -> void:
    var trash_mode := _gallery_trash_drawer_open and _trash_count() > 0

    if is_instance_valid(gallery_scroll):
        gallery_scroll.visible = not trash_mode
    if is_instance_valid(_gallery_browser_row):
        _gallery_browser_row.visible = not trash_mode
    if is_instance_valid(_gallery_search):
        var search_parent := _gallery_search.get_parent() as Control
        if is_instance_valid(search_parent):
            search_parent.visible = not trash_mode

    if trash_mode:
        if is_instance_valid(_gallery_result_label):
            _gallery_result_label.text = "TRASH / %02d" % _trash_count()
        if gallery_view.visible and not _live_output_active:
            status_label.text = "GALLERY / TRASH / %d LOCAL ITEMS" % _trash_count()
    elif gallery_view.visible:
        _apply_gallery_filter()
        _sync_gallery_columns()


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched := data.duplicate(true)
    enriched["host_gallery_fix_revision"] = HOST_GALLERY_FIX_REVISION
    enriched["gallery_trash_exclusive_mode"] = _gallery_trash_drawer_open
    enriched["gallery_list_compact_backdrop"] = true
    enriched["adjacent_sketch_navigation"] = true
    super._telemetry_event(event_name, enriched)
