extends "res://app/main/main_runtime_gallery_feedback_trash.gd"

# Compact review UI + consolidated preference telemetry.
# The six rating axes stay available without permanently consuming parameter
# inspector height. Explicit user ratings are published as a complete snapshot
# so future creative work can learn from the current preference state directly.

const REVIEW_UI_REVISION: int = 2

var _review_popup: PopupPanel = null
var _review_popup_summary: Label = null
var _review_popup_sketch_id: String = ""


func _ready() -> void:
    super._ready()
    call_deferred("_emit_preference_snapshot", "startup")


func _append_review_controls(sketch_id: String) -> void:
    _review_score_buttons.clear()
    _review_average_label = null
    _review_popup_summary = null
    _review_popup_sketch_id = sketch_id

    if is_instance_valid(_review_popup):
        _review_popup.queue_free()
        _review_popup = null

    parameter_list.add_child(HSeparator.new())

    var row := HBoxContainer.new()
    row.name = "CompactReviewRow"
    row.add_theme_constant_override("separation", 5)

    var label := Label.new()
    label.theme_type_variation = &"AccentLabel"
    label.text = "REVIEW"
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(label)

    _review_average_label = Label.new()
    _review_average_label.theme_type_variation = &"MicroLabel"
    row.add_child(_review_average_label)

    var rate_button := Button.new()
    rate_button.text = "RATE"
    rate_button.focus_mode = Control.FOCUS_NONE
    rate_button.theme_type_variation = &"ToolButton"
    rate_button.tooltip_text = "Open the six creative rating axes."
    rate_button.pressed.connect(_on_open_review_popup.bind(sketch_id))
    row.add_child(rate_button)

    var trash_button := Button.new()
    trash_button.text = "TRASH"
    trash_button.focus_mode = Control.FOCUS_NONE
    trash_button.theme_type_variation = &"ToolButton"
    trash_button.tooltip_text = "Hide from this workstation Gallery. Source remains versioned in Git."
    trash_button.pressed.connect(_on_move_active_to_trash.bind(sketch_id))
    row.add_child(trash_button)

    parameter_list.add_child(row)
    _build_review_popup(sketch_id)
    _refresh_active_review_summary(sketch_id)


func _build_review_popup(sketch_id: String) -> void:
    _review_popup = PopupPanel.new()
    _review_popup.name = "ReviewPopup"
    add_child(_review_popup)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    _review_popup.add_child(margin)

    var box := VBoxContainer.new()
    box.custom_minimum_size = Vector2(304.0, 0.0)
    box.add_theme_constant_override("separation", 5)
    margin.add_child(box)

    var header := HBoxContainer.new()
    var title := Label.new()
    title.theme_type_variation = &"AccentLabel"
    title.text = "REVIEW"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)

    _review_popup_summary = Label.new()
    _review_popup_summary.theme_type_variation = &"MicroLabel"
    header.add_child(_review_popup_summary)
    box.add_child(header)

    var review := _review_for(sketch_id)
    for criterion: String in REVIEW_CRITERIA:
        var criterion_row := HBoxContainer.new()
        criterion_row.add_theme_constant_override("separation", 4)

        var criterion_label := Label.new()
        criterion_label.theme_type_variation = &"MicroLabel"
        criterion_label.text = criterion.to_upper()
        criterion_label.custom_minimum_size = Vector2(96.0, 0.0)
        criterion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        criterion_row.add_child(criterion_label)

        var row_buttons: Array[Button] = []
        for score: int in range(1, 6):
            var button := Button.new()
            button.text = str(score)
            button.custom_minimum_size = Vector2(27.0, 22.0)
            button.focus_mode = Control.FOCUS_NONE
            button.toggle_mode = true
            button.theme_type_variation = &"ToolButton"
            button.set_pressed_no_signal(int(review.get(criterion, 0)) == score)
            button.pressed.connect(_on_review_score_pressed.bind(sketch_id, criterion, score))
            criterion_row.add_child(button)
            row_buttons.append(button)
        _review_score_buttons[criterion] = row_buttons
        box.add_child(criterion_row)

    var hint := Label.new()
    hint.theme_type_variation = &"MicroLabel"
    hint.text = "CLICK THE ACTIVE SCORE AGAIN TO CLEAR"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    box.add_child(hint)


func _on_open_review_popup(sketch_id: String) -> void:
    if not is_instance_valid(_review_popup):
        _build_review_popup(sketch_id)
    _review_popup_sketch_id = sketch_id
    _refresh_active_review_summary(sketch_id)
    _review_popup.popup_centered(Vector2i(330, 252))


func _on_review_score_pressed(sketch_id: String, criterion: String, score: int) -> void:
    super._on_review_score_pressed(sketch_id, criterion, score)
    _emit_preference_snapshot("rating_change")


func _refresh_active_review_summary(sketch_id: String) -> void:
    var review := _review_for(sketch_id)
    var average := _review_average(review)
    var rated := 0
    for criterion: String in REVIEW_CRITERIA:
        if int(review.get(criterion, 0)) > 0:
            rated += 1

    var compact_text := "—" if rated == 0 else "%.1f/5" % average
    if is_instance_valid(_review_average_label):
        _review_average_label.text = compact_text
    if is_instance_valid(_review_popup_summary):
        _review_popup_summary.text = "%s  %d/6" % [compact_text, rated]


func _emit_preference_snapshot(reason: String) -> void:
    if not _review_loaded:
        return

    var reviews: Dictionary = {}
    var axis_total: Dictionary = {}
    var axis_count: Dictionary = {}
    for criterion: String in REVIEW_CRITERIA:
        axis_total[criterion] = 0.0
        axis_count[criterion] = 0

    for section: String in _review_config.get_sections():
        if not section.begins_with("review_"):
            continue
        var sketch_id := section.trim_prefix("review_")
        var ratings := _review_for(sketch_id)
        var average := _review_average(ratings)
        if average <= 0.0:
            continue

        var entry: Dictionary = {
            "ratings": ratings,
            "average": average,
        }
        var definition_variant: Variant = _all_catalog_definitions.get(sketch_id, {})
        if definition_variant is Dictionary:
            var definition := definition_variant as Dictionary
            entry["title"] = str(definition.get("title", sketch_id))
            entry["tags"] = definition.get("tags", [])
            if definition.has("creative_signature"):
                entry["creative_signature"] = definition.get("creative_signature")
        reviews[sketch_id] = entry

        for criterion: String in REVIEW_CRITERIA:
            var score := int(ratings.get(criterion, 0))
            if score <= 0:
                continue
            axis_total[criterion] = float(axis_total[criterion]) + float(score)
            axis_count[criterion] = int(axis_count[criterion]) + 1

    var axis_averages: Dictionary = {}
    for criterion: String in REVIEW_CRITERIA:
        var count := int(axis_count[criterion])
        axis_averages[criterion] = 0.0 if count <= 0 else float(axis_total[criterion]) / float(count)

    _telemetry_event("creative_preference_snapshot", {
        "reason": reason,
        "review_ui_revision": REVIEW_UI_REVISION,
        "criteria": REVIEW_CRITERIA.duplicate(),
        "reviewed_count": reviews.size(),
        "axis_averages": axis_averages,
        "reviews": reviews,
    })


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched := data.duplicate(true)
    enriched["review_ui_revision"] = REVIEW_UI_REVISION
    super._telemetry_event(event_name, enriched)
