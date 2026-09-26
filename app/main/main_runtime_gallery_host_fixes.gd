extends "res://app/main/main_runtime_window_memory.gd"

# Thin host-feedback layer. Keep the validated runtime chain intact and only
# override the Gallery behaviours that were directly proven wrong on Windows:
# LIST must stay visual, and TRASH must be an exclusive browser mode instead of
# leaving the normal Gallery visible behind its drawer.

const HOST_GALLERY_FIX_REVISION: int = 1
const LIST_PREVIEW_WIDTH: float = 260.0
const LIST_CARD_HEIGHT: float = 132.0


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

    var list_margin := MarginContainer.new()
    list_margin.name = "ListContent"
    list_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    list_margin.add_theme_constant_override("margin_left", 10)
    list_margin.add_theme_constant_override("margin_top", 8)
    list_margin.add_theme_constant_override("margin_right", 12)
    list_margin.add_theme_constant_override("margin_bottom", 8)
    list_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    list_margin.visible = false
    card.add_child(list_margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    list_margin.add_child(row)

    var preview := TextureRect.new()
    preview.name = "ListPreview"
    preview.custom_minimum_size = Vector2(LIST_PREVIEW_WIDTH, LIST_CARD_HEIGHT - 16.0)
    preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    preview.texture = viewport.get_texture()
    preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(preview)

    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.size_flags_vertical = Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation", 4)
    info.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(info)

    var header := HBoxContainer.new()
    header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.add_child(header)

    var index_label := Label.new()
    index_label.theme_type_variation = &"MicroLabel"
    index_label.text = str(definition.get("index", "---"))
    index_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(index_label)

    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(spacer)

    var live_label := Label.new()
    live_label.theme_type_variation = &"MicroLabel"
    live_label.text = "HOVER / LIVE"
    live_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(live_label)

    var title_label := Label.new()
    title_label.theme_type_variation = &"AccentLabel"
    title_label.text = str(definition.get("title", "UNTITLED"))
    title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.add_child(title_label)

    var tags := _definition_tags(definition)
    var meta_label := Label.new()
    meta_label.theme_type_variation = &"MicroLabel"
    meta_label.text = "%s / %s" % [
        str(definition.get("engine", "GODOT")),
        " / ".join(tags),
    ]
    meta_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.add_child(meta_label)

    var description_label := Label.new()
    description_label.theme_type_variation = &"MicroLabel"
    description_label.text = str(definition.get("description", ""))
    description_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.add_child(description_label)


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
        var list_content := card.get_node_or_null("ListContent") as MarginContainer
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
    super._telemetry_event(event_name, enriched)
