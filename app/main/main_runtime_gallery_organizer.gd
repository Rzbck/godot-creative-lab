extends "res://app/main/main_runtime_program_output.gd"

# Automatic gallery organization layer.
#
# Convention: the first tag in definition.json is the visual family used for
# grouping. Every tag remains searchable/filterable. New sketches therefore
# organize themselves without hard-coded project IDs or manual gallery edits.

const GALLERY_ORGANIZER_REVISION: int = 1
const GALLERY_CARD_COLUMN_WIDTH: float = 270.0

var _gallery_filter_panel: VBoxContainer = null
var _gallery_search: LineEdit = null
var _gallery_tag_flow: HFlowContainer = null
var _gallery_result_label: Label = null
var _gallery_active_tag: String = ""
var _gallery_search_query: String = ""

# group name -> { section, grid, count_label }
var _gallery_groups: Dictionary = {}
# sketch id -> definition
var _gallery_definitions_by_id: Dictionary = {}
# tag -> Button
var _gallery_tag_buttons: Dictionary = {}


func _ready() -> void:
    super._ready()
    _ensure_gallery_filter_ui()
    _apply_gallery_filter()


func _build_gallery() -> void:
    # Parent creates the real thumbnails and persistence-aware cards first.
    super._build_gallery()

    _ensure_gallery_filter_ui()
    _organize_gallery_cards()
    _rebuild_gallery_tag_filters()
    _apply_gallery_filter()


func _ensure_gallery_filter_ui() -> void:
    if is_instance_valid(_gallery_filter_panel):
        return
    if not is_instance_valid(gallery_view):
        return

    _gallery_filter_panel = VBoxContainer.new()
    _gallery_filter_panel.name = "GalleryFilters"
    _gallery_filter_panel.add_theme_constant_override("separation", 5)

    var search_row: HBoxContainer = HBoxContainer.new()
    search_row.add_theme_constant_override("separation", 8)
    _gallery_filter_panel.add_child(search_row)

    var search_prefix: Label = Label.new()
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
    _gallery_result_label.text = ""
    search_row.add_child(_gallery_result_label)

    _gallery_tag_flow = HFlowContainer.new()
    _gallery_tag_flow.name = "GalleryTagFilters"
    _gallery_tag_flow.add_theme_constant_override("h_separation", 5)
    _gallery_tag_flow.add_theme_constant_override("v_separation", 4)
    _gallery_filter_panel.add_child(_gallery_tag_flow)

    gallery_view.add_child(_gallery_filter_panel)
    # GalleryToolbar stays first, filters second, scroll/content third.
    gallery_view.move_child(_gallery_filter_panel, 1)


func _organize_gallery_cards() -> void:
    _gallery_groups.clear()
    _gallery_definitions_by_id.clear()
    gallery_grid.columns = 1

    var grouped: Dictionary = {}
    for definition: Dictionary in _catalog:
        var sketch_id: String = str(definition.get("id", ""))
        if sketch_id.is_empty() or not _gallery_previews.has(sketch_id):
            continue

        _gallery_definitions_by_id[sketch_id] = definition
        var group_name: String = _primary_gallery_group(definition)
        if not grouped.has(group_name):
            grouped[group_name] = []
        (grouped[group_name] as Array).append(sketch_id)

    var group_names: Array = grouped.keys()
    group_names.sort()

    for group_variant: Variant in group_names:
        var group_name: String = str(group_variant)
        var section: VBoxContainer = VBoxContainer.new()
        section.name = "Group_%s" % group_name.to_pascal_case()
        section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        section.add_theme_constant_override("separation", 6)
        gallery_grid.add_child(section)

        var header: HBoxContainer = HBoxContainer.new()
        header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        section.add_child(header)

        var title: Label = Label.new()
        title.theme_type_variation = &"AccentLabel"
        title.text = "// %s" % group_name
        header.add_child(title)

        var spacer: Control = Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_child(spacer)

        var count_label: Label = Label.new()
        count_label.theme_type_variation = &"MicroLabel"
        header.add_child(count_label)

        var separator: HSeparator = HSeparator.new()
        section.add_child(separator)

        var group_grid: GridContainer = GridContainer.new()
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

        var sketch_ids: Array = grouped[group_name] as Array
        for sketch_id_variant: Variant in sketch_ids:
            var sketch_id: String = str(sketch_id_variant)
            var entry: Dictionary = _gallery_previews[sketch_id]
            var card: Button = entry.get("card") as Button
            if not is_instance_valid(card):
                continue
            if card.get_parent() != null:
                card.get_parent().remove_child(card)
            group_grid.add_child(card)


func _primary_gallery_group(definition: Dictionary) -> String:
    var tags_variant: Variant = definition.get("tags", [])
    if tags_variant is Array:
        var tags: Array = tags_variant as Array
        if not tags.is_empty():
            var primary: String = str(tags[0]).strip_edges().to_upper()
            if not primary.is_empty():
                return primary
    return "UNTAGGED"


func _definition_tags(definition: Dictionary) -> PackedStringArray:
    var result: PackedStringArray = PackedStringArray()
    var tags_variant: Variant = definition.get("tags", [])
    if not tags_variant is Array:
        return result
    for tag_variant: Variant in tags_variant as Array:
        var tag: String = str(tag_variant).strip_edges().to_upper()
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
        var tag: String = str(tag_variant)
        _add_gallery_tag_button(tag, int(tag_counts[tag]), tag)

    _sync_gallery_tag_button_states()


func _add_gallery_tag_button(label_text: String, count: int, filter_tag: String) -> void:
    var button: Button = Button.new()
    button.custom_minimum_size = Vector2(0.0, 24.0)
    button.focus_mode = Control.FOCUS_NONE
    button.toggle_mode = true
    button.theme_type_variation = &"ToolButton"
    button.text = "%s  %02d" % [label_text, count]
    button.pressed.connect(_on_gallery_tag_pressed.bind(filter_tag))
    _gallery_tag_flow.add_child(button)
    _gallery_tag_buttons[filter_tag] = button


func _on_gallery_tag_pressed(tag: String) -> void:
    if _gallery_active_tag == tag and not tag.is_empty():
        _gallery_active_tag = ""
    else:
        _gallery_active_tag = tag
    _sync_gallery_tag_button_states()
    _apply_gallery_filter()
    _telemetry_event("gallery_filter_changed", {
        "gallery_organizer_revision": GALLERY_ORGANIZER_REVISION,
        "active_tag": _gallery_active_tag,
        "query": _gallery_search_query,
        "visible_count": _visible_gallery_card_count(),
    })


func _sync_gallery_tag_button_states() -> void:
    for tag_variant: Variant in _gallery_tag_buttons.keys():
        var tag: String = str(tag_variant)
        var button: Button = _gallery_tag_buttons[tag] as Button
        if is_instance_valid(button):
            button.set_pressed_no_signal(tag == _gallery_active_tag)


func _on_gallery_search_changed(value: String) -> void:
    _gallery_search_query = value.strip_edges().to_upper()
    _apply_gallery_filter()


func _definition_matches_gallery_filter(definition: Dictionary) -> bool:
    var tags: PackedStringArray = _definition_tags(definition)
    if not _gallery_active_tag.is_empty() and not tags.has(_gallery_active_tag):
        return false

    if _gallery_search_query.is_empty():
        return true

    var haystack_parts: PackedStringArray = PackedStringArray([
        str(definition.get("id", "")),
        str(definition.get("index", "")),
        str(definition.get("title", "")),
        str(definition.get("engine", "")),
        str(definition.get("description", "")),
        " ".join(tags),
    ])
    var haystack: String = " ".join(haystack_parts).to_upper()

    # Multiple words are ANDed, so "type rgb" narrows naturally without an
    # advanced query language.
    var terms: PackedStringArray = _gallery_search_query.split(" ", false)
    for term: String in terms:
        if not haystack.contains(term):
            return false
    return true


func _apply_gallery_filter() -> void:
    if _gallery_definitions_by_id.is_empty():
        return

    var visible_by_group: Dictionary = {}
    var visible_total: int = 0

    for sketch_id_variant: Variant in _gallery_definitions_by_id.keys():
        var sketch_id: String = str(sketch_id_variant)
        var definition: Dictionary = _gallery_definitions_by_id[sketch_id]
        var visible: bool = _definition_matches_gallery_filter(definition)
        var group_name: String = _primary_gallery_group(definition)

        var entry: Dictionary = _gallery_previews.get(sketch_id, {}) as Dictionary
        var card: Button = entry.get("card") as Button
        if is_instance_valid(card):
            card.visible = visible

        if visible:
            visible_total += 1
            visible_by_group[group_name] = int(visible_by_group.get(group_name, 0)) + 1
        elif _gallery_live_preview_id == sketch_id:
            _freeze_gallery_preview(sketch_id)
            _gallery_live_preview_id = ""

    for group_variant: Variant in _gallery_groups.keys():
        var group_name: String = str(group_variant)
        var group_entry: Dictionary = _gallery_groups[group_name]
        var section: VBoxContainer = group_entry.get("section") as VBoxContainer
        var count_label: Label = group_entry.get("count_label") as Label
        var count: int = int(visible_by_group.get(group_name, 0))
        if is_instance_valid(section):
            section.visible = count > 0
        if is_instance_valid(count_label):
            count_label.text = "[%03d]" % count

    if is_instance_valid(_gallery_result_label):
        _gallery_result_label.text = "%02d / %02d" % [visible_total, _catalog.size()]

    if gallery_view.visible and not _live_output_active:
        var filter_label: String = "ALL" if _gallery_active_tag.is_empty() else _gallery_active_tag
        status_label.text = "GALLERY / %d SHOWN / %d TOTAL / %s" % [
            visible_total,
            _catalog.size(),
            filter_label,
        ]


func _visible_gallery_card_count() -> int:
    var count: int = 0
    for sketch_id_variant: Variant in _gallery_previews.keys():
        var entry: Dictionary = _gallery_previews[sketch_id_variant]
        var card: Button = entry.get("card") as Button
        if is_instance_valid(card) and card.visible:
            count += 1
    return count


func _sync_gallery_columns() -> void:
    if not gallery_view.visible:
        return

    gallery_grid.columns = 1
    var available_width: float = gallery_scroll.size.x
    var columns: int = maxi(1, int(floor(available_width / GALLERY_CARD_COLUMN_WIDTH)))

    for entry_variant: Variant in _gallery_groups.values():
        if not entry_variant is Dictionary:
            continue
        var group_entry: Dictionary = entry_variant as Dictionary
        var group_grid: GridContainer = group_entry.get("grid") as GridContainer
        if is_instance_valid(group_grid) and group_grid.columns != columns:
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
    if is_instance_valid(_gallery_search):
        _gallery_search.grab_focus()


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched: Dictionary = data.duplicate(true)
    enriched["gallery_organizer_revision"] = GALLERY_ORGANIZER_REVISION
    enriched["gallery_group_count"] = _gallery_groups.size()
    enriched["gallery_active_tag"] = _gallery_active_tag
    enriched["gallery_search_query"] = _gallery_search_query
    enriched["gallery_visible_count"] = _visible_gallery_card_count()
    super._telemetry_event(event_name, enriched)
