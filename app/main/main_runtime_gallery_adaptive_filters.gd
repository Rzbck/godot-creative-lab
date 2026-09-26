extends "res://app/main/main_runtime_gallery_organizer.gd"

# Scalable Gallery filtering layer.
#
# The catalogue may grow to hundreds of sketches/tags, so the main filter rail
# is intentionally bounded. Search still indexes every tag. The rail shows only
# a small automatically selected set of useful/discriminating tags, while rare
# tags live in a collapsed drawer and universal tags are omitted because they
# do not narrow the result set.

const GALLERY_ADAPTIVE_FILTER_REVISION: int = 1
const MAX_QUICK_TAGS: int = 6
const MIN_QUICK_TAG_COUNT: int = 2

var _gallery_tag_drawer: VBoxContainer = null
var _gallery_extra_tag_flow: HFlowContainer = null
var _gallery_more_button: Button = null
var _gallery_tag_drawer_open: bool = false
var _gallery_quick_tags: PackedStringArray = PackedStringArray()
var _gallery_hidden_universal_tags: PackedStringArray = PackedStringArray()
var _gallery_remaining_tag_count: int = 0


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
    _gallery_result_label.text = ""
    search_row.add_child(_gallery_result_label)

    _gallery_tag_flow = HFlowContainer.new()
    _gallery_tag_flow.name = "GalleryQuickFilters"
    _gallery_tag_flow.add_theme_constant_override("h_separation", 5)
    _gallery_tag_flow.add_theme_constant_override("v_separation", 4)
    _gallery_filter_panel.add_child(_gallery_tag_flow)

    _gallery_tag_drawer = VBoxContainer.new()
    _gallery_tag_drawer.name = "GalleryTagDrawer"
    _gallery_tag_drawer.visible = false
    _gallery_tag_drawer.add_theme_constant_override("separation", 4)
    _gallery_filter_panel.add_child(_gallery_tag_drawer)

    var drawer_label := Label.new()
    drawer_label.theme_type_variation = &"MicroLabel"
    drawer_label.text = "MORE FILTERS"
    _gallery_tag_drawer.add_child(drawer_label)

    _gallery_extra_tag_flow = HFlowContainer.new()
    _gallery_extra_tag_flow.name = "GalleryExtraFilters"
    _gallery_extra_tag_flow.add_theme_constant_override("h_separation", 5)
    _gallery_extra_tag_flow.add_theme_constant_override("v_separation", 4)
    _gallery_tag_drawer.add_child(_gallery_extra_tag_flow)

    gallery_view.add_child(_gallery_filter_panel)
    # GalleryToolbar stays first, filters second, scroll/content third.
    gallery_view.move_child(_gallery_filter_panel, 1)


func _rebuild_gallery_tag_filters() -> void:
    if not is_instance_valid(_gallery_tag_flow):
        return

    for child: Node in _gallery_tag_flow.get_children():
        child.queue_free()
    if is_instance_valid(_gallery_extra_tag_flow):
        for child: Node in _gallery_extra_tag_flow.get_children():
            child.queue_free()

    _gallery_tag_buttons.clear()
    _gallery_more_button = null
    _gallery_hidden_universal_tags = PackedStringArray()

    var tag_counts: Dictionary = {}
    for definition: Dictionary in _catalog:
        for tag: String in _definition_tags(definition):
            tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1

    var total_count := _catalog.size()
    var filterable_tags: Array[String] = []
    for tag_variant: Variant in tag_counts.keys():
        var tag := str(tag_variant)
        var count := int(tag_counts[tag])
        if total_count > 0 and count >= total_count:
            _gallery_hidden_universal_tags.append(tag)
            continue
        filterable_tags.append(tag)

    _gallery_quick_tags = _pick_quick_tags(tag_counts, total_count)

    # A rare selected tag is promoted into the fixed rail so the current
    # filtering state remains visible after the drawer closes.
    if not _gallery_active_tag.is_empty() \
    and filterable_tags.has(_gallery_active_tag) \
    and not _gallery_quick_tags.has(_gallery_active_tag):
        if _gallery_quick_tags.size() >= MAX_QUICK_TAGS:
            _gallery_quick_tags.resize(MAX_QUICK_TAGS - 1)
        _gallery_quick_tags.append(_gallery_active_tag)

    _add_adaptive_tag_button(_gallery_tag_flow, "ALL", total_count, "")

    for tag: String in _gallery_quick_tags:
        _add_adaptive_tag_button(
            _gallery_tag_flow,
            tag,
            int(tag_counts.get(tag, 0)),
            tag
        )

    var remaining: Array[String] = []
    for tag: String in filterable_tags:
        if not _gallery_quick_tags.has(tag):
            remaining.append(tag)
    remaining.sort_custom(Callable(self, "_drawer_tag_before").bind(tag_counts))

    _gallery_remaining_tag_count = remaining.size()

    if not remaining.is_empty():
        _gallery_more_button = Button.new()
        _gallery_more_button.custom_minimum_size = Vector2(0.0, 24.0)
        _gallery_more_button.focus_mode = Control.FOCUS_NONE
        _gallery_more_button.toggle_mode = true
        _gallery_more_button.theme_type_variation = &"ToolButton"
        _gallery_more_button.pressed.connect(_on_gallery_more_pressed)
        _gallery_tag_flow.add_child(_gallery_more_button)

        for tag: String in remaining:
            _add_adaptive_tag_button(
                _gallery_extra_tag_flow,
                tag,
                int(tag_counts.get(tag, 0)),
                tag
            )

    _sync_adaptive_drawer_state()
    _sync_gallery_tag_button_states()


func _pick_quick_tags(tag_counts: Dictionary, total_count: int) -> PackedStringArray:
    var candidates: Array[Dictionary] = []
    if total_count <= 0:
        return PackedStringArray()

    for tag_variant: Variant in tag_counts.keys():
        var tag := str(tag_variant)
        var count := int(tag_counts[tag])
        if count < MIN_QUICK_TAG_COUNT or count >= total_count:
            continue

        var frequency := float(count) / float(total_count)
        # Prefer tags that are common enough to be useful but not so common
        # that they barely narrow the Gallery.
        var score := float(count) * (1.0 - frequency)
        candidates.append({
            "tag": tag,
            "count": count,
            "score": score,
        })

    candidates.sort_custom(Callable(self, "_quick_tag_candidate_before"))

    var result := PackedStringArray()
    for candidate_variant: Variant in candidates:
        if result.size() >= MAX_QUICK_TAGS:
            break
        var candidate := candidate_variant as Dictionary
        result.append(str(candidate.get("tag", "")))
    return result


func _quick_tag_candidate_before(a: Dictionary, b: Dictionary) -> bool:
    var score_a := float(a.get("score", 0.0))
    var score_b := float(b.get("score", 0.0))
    if not is_equal_approx(score_a, score_b):
        return score_a > score_b

    var count_a := int(a.get("count", 0))
    var count_b := int(b.get("count", 0))
    if count_a != count_b:
        return count_a > count_b
    return str(a.get("tag", "")) < str(b.get("tag", ""))


func _drawer_tag_before(a: String, b: String, tag_counts: Dictionary) -> bool:
    var count_a := int(tag_counts.get(a, 0))
    var count_b := int(tag_counts.get(b, 0))
    if count_a != count_b:
        return count_a > count_b
    return a < b


func _add_adaptive_tag_button(
    parent: Control,
    label_text: String,
    count: int,
    filter_tag: String
) -> void:
    var button := Button.new()
    button.custom_minimum_size = Vector2(0.0, 24.0)
    button.focus_mode = Control.FOCUS_NONE
    button.toggle_mode = true
    button.theme_type_variation = &"ToolButton"
    button.text = "%s  %d" % [label_text, count]
    button.pressed.connect(_on_gallery_tag_pressed.bind(filter_tag))
    parent.add_child(button)
    _gallery_tag_buttons[filter_tag] = button


func _on_gallery_more_pressed() -> void:
    _gallery_tag_drawer_open = not _gallery_tag_drawer_open
    _sync_adaptive_drawer_state()
    _telemetry_event("gallery_tag_drawer_changed", {
        "gallery_adaptive_filter_revision": GALLERY_ADAPTIVE_FILTER_REVISION,
        "open": _gallery_tag_drawer_open,
        "remaining_tag_count": _gallery_remaining_tag_count,
    })


func _sync_adaptive_drawer_state() -> void:
    if is_instance_valid(_gallery_tag_drawer):
        _gallery_tag_drawer.visible = (
            _gallery_tag_drawer_open
            and _gallery_remaining_tag_count > 0
        )
    if is_instance_valid(_gallery_more_button):
        _gallery_more_button.set_pressed_no_signal(_gallery_tag_drawer_open)
        _gallery_more_button.text = "%s  %d" % [
            "LESS" if _gallery_tag_drawer_open else "MORE",
            _gallery_remaining_tag_count,
        ]


func _on_gallery_tag_pressed(tag: String) -> void:
    if _gallery_active_tag == tag and not tag.is_empty():
        _gallery_active_tag = ""
    else:
        _gallery_active_tag = tag

    # Keep the default view compact. If the user selected something from the
    # drawer it is promoted into the quick rail before the drawer closes.
    if not tag.is_empty():
        _gallery_tag_drawer_open = false

    _rebuild_gallery_tag_filters()
    _apply_gallery_filter()
    _telemetry_event("gallery_filter_changed", {
        "gallery_adaptive_filter_revision": GALLERY_ADAPTIVE_FILTER_REVISION,
        "active_tag": _gallery_active_tag,
        "query": _gallery_search_query,
        "visible_count": _visible_gallery_card_count(),
        "quick_tags": Array(_gallery_quick_tags),
        "hidden_universal_tags": Array(_gallery_hidden_universal_tags),
    })


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched := data.duplicate(true)
    enriched["gallery_adaptive_filter_revision"] = GALLERY_ADAPTIVE_FILTER_REVISION
    enriched["gallery_tag_drawer_open"] = _gallery_tag_drawer_open
    enriched["gallery_quick_tag_count"] = _gallery_quick_tags.size()
    enriched["gallery_remaining_tag_count"] = _gallery_remaining_tag_count
    super._telemetry_event(event_name, enriched)
