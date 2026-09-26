extends "res://app/main/main_runtime_program_output.gd"

# Scalable Gallery organization + browser presentation layer.
# Tags remain semantic/searchable metadata, but the user can browse the library
# like a file manager: global sort, flat/grid/list presentation, adjustable card
# size, or semantic FAMILY grouping. Reflow never recreates sketch instances.

const GALLERY_ORGANIZER_REVISION: int = 2
const GALLERY_VIEW_STATE_PATH: String = "user://creative_lab_gallery_view.cfg"
const GALLERY_CARD_WIDTH_MIN: float = 180.0
const GALLERY_CARD_WIDTH_MAX: float = 430.0
const GALLERY_CARD_WIDTH_DEFAULT: float = 270.0

var _gallery_filter_panel: VBoxContainer = null
var _gallery_search: LineEdit = null
var _gallery_tag_flow: HFlowContainer = null
var _gallery_result_label: Label = null
var _gallery_active_tag: String = ""
var _gallery_search_query: String = ""

var _gallery_browser_row: HBoxContainer = null
var _gallery_sort_option: OptionButton = null
var _gallery_grid_button: Button = null
var _gallery_list_button: Button = null
var _gallery_size_slider: HSlider = null
var _gallery_sort_mode: String = "index_asc"
var _gallery_view_mode: String = "grid"
var _gallery_card_width: float = GALLERY_CARD_WIDTH_DEFAULT
var _gallery_view_config := ConfigFile.new()

# group name -> { section, grid, count_label }
var _gallery_groups: Dictionary = {}
# sketch id -> definition
var _gallery_definitions_by_id: Dictionary = {}
# tag -> Button
var _gallery_tag_buttons: Dictionary = {}


func _ready() -> void:
    _load_gallery_browser_state()
    super._ready()
    _ensure_gallery_filter_ui()
    _ensure_gallery_browser_controls()
    _organize_gallery_cards()
    _apply_gallery_filter()
    _sync_gallery_columns()


func _build_gallery() -> void:
    super._build_gallery()
    _ensure_gallery_filter_ui()
    _ensure_gallery_browser_controls()
    _organize_gallery_cards()
    _rebuild_gallery_tag_filters()
    _apply_gallery_filter()
    _sync_gallery_columns()


func _load_gallery_browser_state() -> void:
    _gallery_view_config = ConfigFile.new()
    var error := _gallery_view_config.load(GALLERY_VIEW_STATE_PATH)
    if error != OK and error != ERR_FILE_NOT_FOUND:
        push_warning("Could not load Gallery browser state: error %d" % int(error))
    _gallery_sort_mode = str(_gallery_view_config.get_value("browser", "sort", "index_asc"))
    if not ["index_asc", "index_desc", "title", "family"].has(_gallery_sort_mode):
        _gallery_sort_mode = "index_asc"
    _gallery_view_mode = str(_gallery_view_config.get_value("browser", "view", "grid"))
    if not ["grid", "list"].has(_gallery_view_mode):
        _gallery_view_mode = "grid"
    _gallery_card_width = clampf(
        float(_gallery_view_config.get_value("browser", "card_width", GALLERY_CARD_WIDTH_DEFAULT)),
        GALLERY_CARD_WIDTH_MIN,
        GALLERY_CARD_WIDTH_MAX
    )


func _save_gallery_browser_state() -> void:
    _gallery_view_config.set_value("browser", "sort", _gallery_sort_mode)
    _gallery_view_config.set_value("browser", "view", _gallery_view_mode)
    _gallery_view_config.set_value("browser", "card_width", _gallery_card_width)
    var error := _gallery_view_config.save(GALLERY_VIEW_STATE_PATH)
    if error != OK:
        push_warning("Could not save Gallery browser state: error %d" % int(error))


func _ensure_gallery_filter_ui() -> void:
    if is_instance_valid(_gallery_filter_panel):
        return
    if not is_instance_valid(gallery_view):
        return

    _gallery_filter_panel = VBoxContainer.new()
    _gallery_filter_panel.name = "GalleryFilters"
    _gallery_filter_panel.add_theme_constant_override("separation", 5)

    var search_row := HBoxContainer.new()
    search_row.add_theme_constant_override("separation", 8)
    _gallery_filter_panel.add_child(search_row)

    var search_prefix := Label.new()
    search_prefix.theme_type_variation = &"AccentLabel"
    search_prefix.text = ">"
    search_row.add_child(search_prefix)

    _gallery_search = LineEdit.new()
    _gallery_search.name = "GallerySearch"
    _gallery_search.custom_minimum_size = Vector2(300.0, 26.0)
    _gallery_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _gallery_search.placeholder_text = "SEARCH TITLE / TAG / ENGINE / DESCRIPTION..."
    _gallery_search.clear_button_enabled = true
    _gallery_search.text_changed.connect(_on_gallery_search_changed)
    search_row.add_child(_gallery_search)

    _gallery_result_label = Label.new()
    _gallery_result_label.theme_type_variation = &"MicroLabel"
    search_row.add_child(_gallery_result_label)

    _gallery_tag_flow = HFlowContainer.new()
    _gallery_tag_flow.name = "GalleryTagFilters"
    _gallery_tag_flow.add_theme_constant_override("h_separation", 5)
    _gallery_tag_flow.add_theme_constant_override("v_separation", 4)
    _gallery_filter_panel.add_child(_gallery_tag_flow)

    gallery_view.add_child(_gallery_filter_panel)
    gallery_view.move_child(_gallery_filter_panel, 1)


func _ensure_gallery_browser_controls() -> void:
    if is_instance_valid(_gallery_browser_row) or not is_instance_valid(_gallery_filter_panel):
        return

    _gallery_browser_row = HBoxContainer.new()
    _gallery_browser_row.name = "GalleryBrowserControls"
    _gallery_browser_row.add_theme_constant_override("separation", 6)

    var label := Label.new()
    label.theme_type_variation = &"MicroLabel"
    label.text = "VIEW"
    _gallery_browser_row.add_child(label)

    _gallery_sort_option = OptionButton.new()
    _gallery_sort_option.focus_mode = Control.FOCUS_NONE
    _gallery_sort_option.custom_minimum_size = Vector2(122.0, 24.0)
    var sorts := [
        ["INDEX ↑", "index_asc"],
        ["INDEX ↓", "index_desc"],
        ["TITLE A–Z", "title"],
        ["FAMILY", "family"],
    ]
    for i: int in range(sorts.size()):
        var item: Array = sorts[i]
        _gallery_sort_option.add_item(str(item[0]))
        _gallery_sort_option.set_item_metadata(i, item[1])
        if str(item[1]) == _gallery_sort_mode:
            _gallery_sort_option.select(i)
    _gallery_sort_option.item_selected.connect(_on_gallery_sort_selected)
    _gallery_browser_row.add_child(_gallery_sort_option)

    _gallery_grid_button = Button.new()
    _gallery_grid_button.text = "GRID"
    _gallery_grid_button.focus_mode = Control.FOCUS_NONE
    _gallery_grid_button.toggle_mode = true
    _gallery_grid_button.theme_type_variation = &"ToolButton"
    _gallery_grid_button.pressed.connect(_on_gallery_view_mode_pressed.bind("grid"))
    _gallery_browser_row.add_child(_gallery_grid_button)

    _gallery_list_button = Button.new()
    _gallery_list_button.text = "LIST"
    _gallery_list_button.focus_mode = Control.FOCUS_NONE
    _gallery_list_button.toggle_mode = true
    _gallery_list_button.theme_type_variation = &"ToolButton"
    _gallery_list_button.pressed.connect(_on_gallery_view_mode_pressed.bind("list"))
    _gallery_browser_row.add_child(_gallery_list_button)

    var size_label := Label.new()
    size_label.theme_type_variation = &"MicroLabel"
    size_label.text = "SIZE"
    _gallery_browser_row.add_child(size_label)

    _gallery_size_slider = HSlider.new()
    _gallery_size_slider.min_value = GALLERY_CARD_WIDTH_MIN
    _gallery_size_slider.max_value = GALLERY_CARD_WIDTH_MAX
    _gallery_size_slider.step = 10.0
    _gallery_size_slider.value = _gallery_card_width
    _gallery_size_slider.custom_minimum_size = Vector2(120.0, 22.0)
    _gallery_size_slider.value_changed.connect(_on_gallery_size_changed)
    _gallery_browser_row.add_child(_gallery_size_slider)

    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _gallery_browser_row.add_child(spacer)

    _gallery_filter_panel.add_child(_gallery_browser_row)
    _gallery_filter_panel.move_child(_gallery_browser_row, 1)
    _sync_gallery_browser_controls()


func _sync_gallery_browser_controls() -> void:
    if is_instance_valid(_gallery_grid_button):
        _gallery_grid_button.set_pressed_no_signal(_gallery_view_mode == "grid")
    if is_instance_valid(_gallery_list_button):
        _gallery_list_button.set_pressed_no_signal(_gallery_view_mode == "list")
    if is_instance_valid(_gallery_size_slider):
        _gallery_size_slider.editable = _gallery_view_mode == "grid"
        _gallery_size_slider.value = _gallery_card_width


func _on_gallery_sort_selected(index: int) -> void:
    if not is_instance_valid(_gallery_sort_option):
        return
    _gallery_sort_mode = str(_gallery_sort_option.get_item_metadata(index))
    _save_gallery_browser_state()
    _organize_gallery_cards()
    _apply_gallery_filter()
    _sync_gallery_columns()
    _telemetry_event("gallery_browser_changed", {"action":"sort"})


func _on_gallery_view_mode_pressed(mode: String) -> void:
    if mode == _gallery_view_mode:
        _sync_gallery_browser_controls()
        return
    _gallery_view_mode = mode
    _save_gallery_browser_state()
    _apply_gallery_card_presentation()
    _sync_gallery_browser_controls()
    _sync_gallery_columns()
    _telemetry_event("gallery_browser_changed", {"action":"view"})


func _on_gallery_size_changed(value: float) -> void:
    if _gallery_view_mode != "grid":
        return
    _gallery_card_width = clampf(value, GALLERY_CARD_WIDTH_MIN, GALLERY_CARD_WIDTH_MAX)
    _save_gallery_browser_state()
    _apply_gallery_card_presentation()
    _sync_gallery_columns()


func _organize_gallery_cards() -> void:
    if not is_instance_valid(gallery_grid):
        return

    # Detach live card nodes before deleting old section containers. The actual
    # SubViewports remain alive, so sorting never restarts a simulation.
    for entry_variant: Variant in _gallery_previews.values():
        if not entry_variant is Dictionary:
            continue
        var card := (entry_variant as Dictionary).get("card") as Button
        if is_instance_valid(card) and card.get_parent() != null:
            card.get_parent().remove_child(card)

    for child: Node in gallery_grid.get_children():
        child.free()

    _gallery_groups.clear()
    _gallery_definitions_by_id.clear()
    gallery_grid.columns = 1

    for definition: Dictionary in _catalog:
        var sketch_id := str(definition.get("id", ""))
        if not sketch_id.is_empty() and _gallery_previews.has(sketch_id):
            _gallery_definitions_by_id[sketch_id] = definition

    var ordered_ids := _sorted_gallery_ids()
    if _gallery_sort_mode == "family":
        var grouped: Dictionary = {}
        for sketch_id: String in ordered_ids:
            var definition: Dictionary = _gallery_definitions_by_id[sketch_id]
            var group_name := _primary_gallery_group(definition)
            if not grouped.has(group_name):
                grouped[group_name] = []
            (grouped[group_name] as Array).append(sketch_id)
        var names: Array = grouped.keys()
        names.sort()
        for group_variant: Variant in names:
            var group_name := str(group_variant)
            _create_gallery_group(group_name, grouped[group_name] as Array, true)
    else:
        _create_gallery_group("PROJECTS", ordered_ids, false)

    _apply_gallery_card_presentation()


func _create_gallery_group(group_name: String, sketch_ids: Array, show_header: bool) -> void:
    var section := VBoxContainer.new()
    section.name = "Group_%s" % group_name.to_pascal_case()
    section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    section.add_theme_constant_override("separation", 6)
    gallery_grid.add_child(section)

    var count_label: Label = null
    if show_header:
        var header := HBoxContainer.new()
        header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        section.add_child(header)

        var title := Label.new()
        title.theme_type_variation = &"AccentLabel"
        title.text = "// %s" % group_name
        header.add_child(title)

        var spacer := Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_child(spacer)

        count_label = Label.new()
        count_label.theme_type_variation = &"MicroLabel"
        header.add_child(count_label)
        section.add_child(HSeparator.new())

    var group_grid := GridContainer.new()
    group_grid.name = "Cards"
    group_grid.columns = 3
    group_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    group_grid.add_theme_constant_override("h_separation", 12)
    group_grid.add_theme_constant_override("v_separation", 12)
    section.add_child(group_grid)

    _gallery_groups[group_name] = {
        "section": section,
        "grid": group_grid,
        "count_label": count_label,
    }

    for sketch_id_variant: Variant in sketch_ids:
        var sketch_id := str(sketch_id_variant)
        var entry: Dictionary = _gallery_previews.get(sketch_id, {}) as Dictionary
        var card := entry.get("card") as Button
        if is_instance_valid(card):
            group_grid.add_child(card)


func _sorted_gallery_ids() -> Array[String]:
    var ids: Array[String] = []
    for sketch_id_variant: Variant in _gallery_definitions_by_id.keys():
        ids.append(str(sketch_id_variant))
    ids.sort_custom(Callable(self, "_gallery_id_before"))
    return ids


func _gallery_id_before(a: String, b: String) -> bool:
    var da: Dictionary = _gallery_definitions_by_id.get(a, {}) as Dictionary
    var db: Dictionary = _gallery_definitions_by_id.get(b, {}) as Dictionary
    match _gallery_sort_mode:
        "index_desc":
            return int(da.get("index", 0)) > int(db.get("index", 0))
        "title":
            var ta := str(da.get("title", a)).to_upper()
            var tb := str(db.get("title", b)).to_upper()
            return ta < tb if ta != tb else int(da.get("index", 0)) < int(db.get("index", 0))
        "family":
            var ga := _primary_gallery_group(da)
            var gb := _primary_gallery_group(db)
            return ga < gb if ga != gb else int(da.get("index", 0)) < int(db.get("index", 0))
        _:
            return int(da.get("index", 0)) < int(db.get("index", 0))


func _apply_gallery_card_presentation() -> void:
    for entry_variant: Variant in _gallery_previews.values():
        if not entry_variant is Dictionary:
            continue
        var entry := entry_variant as Dictionary
        var card := entry.get("card") as Button
        if not is_instance_valid(card):
            continue
        var previews := card.find_children("*", "TextureRect", true, false)
        var preview: TextureRect = null
        if not previews.is_empty():
            preview = previews[0] as TextureRect

        if _gallery_view_mode == "list":
            card.custom_minimum_size = Vector2(0.0, 68.0)
            if is_instance_valid(preview):
                preview.visible = false
        else:
            var preview_height := clampf(_gallery_card_width * 0.56, 102.0, 242.0)
            card.custom_minimum_size = Vector2(_gallery_card_width, preview_height + 78.0)
            if is_instance_valid(preview):
                preview.visible = true
                preview.custom_minimum_size = Vector2(0.0, preview_height)


func _primary_gallery_group(definition: Dictionary) -> String:
    var tags_variant: Variant = definition.get("tags", [])
    if tags_variant is Array:
        var tags: Array = tags_variant as Array
        if not tags.is_empty():
            var primary := str(tags[0]).strip_edges().to_upper()
            if not primary.is_empty():
                return primary
    return "UNTAGGED"


func _current_gallery_group(definition: Dictionary) -> String:
    return _primary_gallery_group(definition) if _gallery_sort_mode == "family" else "PROJECTS"


func _definition_tags(definition: Dictionary) -> PackedStringArray:
    var result := PackedStringArray()
    var tags_variant: Variant = definition.get("tags", [])
    if not tags_variant is Array:
        return result
    for tag_variant: Variant in tags_variant as Array:
        var tag := str(tag_variant).strip_edges().to_upper()
        if not tag.is_empty() and not result.has(tag):
            result.append(tag)
    return result


func _rebuild_gallery_tag_filters() -> void:
    if not is_instance_valid(_gallery_tag_flow):
        return
    for child: Node in _gallery_tag_flow.get_children():
        child.queue_free()
    _gallery_tag_buttons.clear()

    var tag_counts: Dictionary = {}
    for definition: Dictionary in _catalog:
        for tag: String in _definition_tags(definition):
            tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1

    _add_gallery_tag_button("ALL", _catalog.size(), "")
    var tags: Array = tag_counts.keys()
    tags.sort()
    for tag_variant: Variant in tags:
        var tag := str(tag_variant)
        _add_gallery_tag_button(tag, int(tag_counts[tag]), tag)
    _sync_gallery_tag_button_states()


func _add_gallery_tag_button(label_text: String, count: int, filter_tag: String) -> void:
    var button := Button.new()
    button.custom_minimum_size = Vector2(0.0, 24.0)
    button.focus_mode = Control.FOCUS_NONE
    button.toggle_mode = true
    button.theme_type_variation = &"ToolButton"
    button.text = "%s  %02d" % [label_text, count]
    button.pressed.connect(_on_gallery_tag_pressed.bind(filter_tag))
    _gallery_tag_flow.add_child(button)
    _gallery_tag_buttons[filter_tag] = button


func _on_gallery_tag_pressed(tag: String) -> void:
    _gallery_active_tag = "" if _gallery_active_tag == tag and not tag.is_empty() else tag
    _sync_gallery_tag_button_states()
    _apply_gallery_filter()
    _telemetry_event("gallery_filter_changed", {
        "active_tag": _gallery_active_tag,
        "query": _gallery_search_query,
        "visible_count": _visible_gallery_card_count(),
    })


func _sync_gallery_tag_button_states() -> void:
    for tag_variant: Variant in _gallery_tag_buttons.keys():
        var tag := str(tag_variant)
        var button := _gallery_tag_buttons[tag] as Button
        if is_instance_valid(button):
            button.set_pressed_no_signal(tag == _gallery_active_tag)


func _on_gallery_search_changed(value: String) -> void:
    _gallery_search_query = value.strip_edges().to_upper()
    _apply_gallery_filter()


func _definition_matches_gallery_filter(definition: Dictionary) -> bool:
    var tags := _definition_tags(definition)
    if not _gallery_active_tag.is_empty() and not tags.has(_gallery_active_tag):
        return false
    if _gallery_search_query.is_empty():
        return true

    var haystack_parts := PackedStringArray([
        str(definition.get("id", "")),
        str(definition.get("index", "")),
        str(definition.get("title", "")),
        str(definition.get("engine", "")),
        str(definition.get("description", "")),
        " ".join(tags),
    ])
    var haystack := " ".join(haystack_parts).to_upper()
    var terms := _gallery_search_query.split(" ", false)
    for term: String in terms:
        if not haystack.contains(term):
            return false
    return true


func _apply_gallery_filter() -> void:
    if _gallery_definitions_by_id.is_empty():
        return

    var visible_by_group: Dictionary = {}
    var visible_total := 0
    for sketch_id_variant: Variant in _gallery_definitions_by_id.keys():
        var sketch_id := str(sketch_id_variant)
        var definition: Dictionary = _gallery_definitions_by_id[sketch_id]
        var visible := _definition_matches_gallery_filter(definition)
        var group_name := _current_gallery_group(definition)

        var entry: Dictionary = _gallery_previews.get(sketch_id, {}) as Dictionary
        var card := entry.get("card") as Button
        if is_instance_valid(card):
            card.visible = visible

        if visible:
            visible_total += 1
            visible_by_group[group_name] = int(visible_by_group.get(group_name, 0)) + 1
        elif _gallery_live_preview_id == sketch_id:
            _freeze_gallery_preview(sketch_id)
            _gallery_live_preview_id = ""

    for group_variant: Variant in _gallery_groups.keys():
        var group_name := str(group_variant)
        var group_entry: Dictionary = _gallery_groups[group_name]
        var section := group_entry.get("section") as VBoxContainer
        var count_label := group_entry.get("count_label") as Label
        var count := int(visible_by_group.get(group_name, 0))
        if is_instance_valid(section):
            section.visible = count > 0
        if is_instance_valid(count_label):
            count_label.text = "[%03d]" % count

    if is_instance_valid(_gallery_result_label):
        _gallery_result_label.text = "%02d / %02d" % [visible_total, _catalog.size()]

    if gallery_view.visible and not _live_output_active:
        var filter_label := "ALL" if _gallery_active_tag.is_empty() else _gallery_active_tag
        status_label.text = "GALLERY / %d SHOWN / %d TOTAL / %s / %s" % [
            visible_total,
            _catalog.size(),
            filter_label,
            _gallery_sort_mode.to_upper(),
        ]


func _visible_gallery_card_count() -> int:
    var count := 0
    for entry_variant: Variant in _gallery_previews.values():
        if not entry_variant is Dictionary:
            continue
        var card := (entry_variant as Dictionary).get("card") as Button
        if is_instance_valid(card) and card.visible:
            count += 1
    return count


func _sync_gallery_columns() -> void:
    if not gallery_view.visible:
        return
    gallery_grid.columns = 1
    var available_width := maxf(1.0, gallery_scroll.size.x)
    var columns := 1
    if _gallery_view_mode == "grid":
        columns = maxi(1, int(floor(available_width / maxf(GALLERY_CARD_WIDTH_MIN, _gallery_card_width + 12.0))))

    for entry_variant: Variant in _gallery_groups.values():
        if not entry_variant is Dictionary:
            continue
        var group_grid := (entry_variant as Dictionary).get("grid") as GridContainer
        if is_instance_valid(group_grid):
            group_grid.columns = columns


func _remove_gallery_rollover_tooltips() -> void:
    _clear_tooltips_recursive(gallery_grid)


func _clear_tooltips_recursive(node: Node) -> void:
    if node is Control:
        (node as Control).tooltip_text = ""
    for child: Node in node.get_children():
        _clear_tooltips_recursive(child)


func _show_gallery() -> void:
    super._show_gallery()
    _apply_gallery_filter()
    _sync_gallery_columns()
    if is_instance_valid(_gallery_search):
        _gallery_search.grab_focus()


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched := data.duplicate(true)
    enriched["gallery_organizer_revision"] = GALLERY_ORGANIZER_REVISION
    enriched["gallery_group_count"] = _gallery_groups.size()
    enriched["gallery_active_tag"] = _gallery_active_tag
    enriched["gallery_search_query"] = _gallery_search_query
    enriched["gallery_visible_count"] = _visible_gallery_card_count()
    enriched["gallery_sort_mode"] = _gallery_sort_mode
    enriched["gallery_view_mode"] = _gallery_view_mode
    enriched["gallery_card_width"] = _gallery_card_width
    super._telemetry_event(event_name, enriched)
