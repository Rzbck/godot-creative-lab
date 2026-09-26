extends "res://app/main/main_runtime_gallery_feedback_trash.gd"

# Compact review UI + consolidated preference telemetry.
# Numeric axes stay quick, while an optional free-text note captures WHY a score
# is low/high. Review changes are checkpoint-published shortly after editing so
# useful feedback does not depend on a successful application shutdown.

const ReviewDesignSystem = preload("res://app/ui/design_system/theme/design_system.gd")

const REVIEW_UI_REVISION: int = 4
const REVIEW_MODAL_WIDTH: float = 520.0
const REVIEW_NOTE_MAX_CHARS: int = 2000
const REVIEW_CHECKPOINT_DELAY: float = 0.8

var _review_modal: Control = null
var _review_modal_summary: Label = null
var _review_modal_sketch_id: String = ""
var _review_note_edit: TextEdit = null
var _review_note_dirty: bool = false
var _review_checkpoint_pending: bool = false
var _review_checkpoint_countdown: float = 0.0
var _review_checkpoint_reason: String = ""


func _ready() -> void:
    super._ready()
    _enter_startup_workstation_fullscreen()
    call_deferred("_emit_preference_snapshot", "startup")


func _process(delta: float) -> void:
    super._process(delta)
    if not _review_checkpoint_pending:
        return
    _review_checkpoint_countdown -= delta
    if _review_checkpoint_countdown > 0.0:
        return
    _review_checkpoint_pending = false
    _emit_preference_snapshot("review_checkpoint_%s" % _review_checkpoint_reason)
    call_deferred("_publish_telemetry_to_github", "review_checkpoint")


func _input(event: InputEvent) -> void:
    if is_instance_valid(_review_modal) and _review_modal.visible:
        if event is InputEventKey:
            var key_event := event as InputEventKey
            if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
                _close_review_modal()
                get_viewport().set_input_as_handled()
                return
    super._input(event)


func _enter_startup_workstation_fullscreen() -> void:
    if DisplayServer.get_name().to_lower() == "headless":
        return
    if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    _sync_window_controls()
    call_deferred("_report_startup_workstation_fullscreen")


func _report_startup_workstation_fullscreen() -> void:
    await get_tree().process_frame
    _telemetry_event("workstation_startup_fullscreen", {
        "requested_mode": DisplayServer.WINDOW_MODE_FULLSCREEN,
        "actual_mode": DisplayServer.window_get_mode(),
        "matched": DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
        "window_size": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
    })


func _append_review_controls(sketch_id: String) -> void:
    _review_score_buttons.clear()
    _review_average_label = null
    _review_modal_summary = null
    _review_modal_sketch_id = sketch_id
    _review_note_edit = null
    _review_note_dirty = false

    if is_instance_valid(_review_modal):
        _review_modal.queue_free()
        _review_modal = null

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
    rate_button.tooltip_text = "Rate six axes and leave a written review."
    rate_button.pressed.connect(_on_open_review_modal.bind(sketch_id))
    row.add_child(rate_button)

    var trash_button := Button.new()
    trash_button.text = "TRASH"
    trash_button.focus_mode = Control.FOCUS_NONE
    trash_button.theme_type_variation = &"ToolButton"
    trash_button.tooltip_text = "Hide from this workstation Gallery. Source remains versioned in Git."
    trash_button.pressed.connect(_on_move_active_to_trash.bind(sketch_id))
    row.add_child(trash_button)

    parameter_list.add_child(row)
    _build_review_modal(sketch_id)
    _refresh_active_review_summary(sketch_id)


func _build_review_modal(sketch_id: String) -> void:
    _review_modal = Control.new()
    _review_modal.name = "ReviewModal"
    _review_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _review_modal.mouse_filter = Control.MOUSE_FILTER_STOP
    _review_modal.z_index = 4096
    _review_modal.visible = false
    add_child(_review_modal)

    var backdrop := ColorRect.new()
    backdrop.name = "Backdrop"
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var backdrop_color := ReviewDesignSystem.COLOR_CANVAS
    backdrop_color.a = 0.86
    backdrop.color = backdrop_color
    backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    backdrop.gui_input.connect(_on_review_backdrop_input)
    _review_modal.add_child(backdrop)

    var center := CenterContainer.new()
    center.name = "Center"
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _review_modal.add_child(center)

    var card := PanelContainer.new()
    card.name = "ReviewCard"
    card.custom_minimum_size = Vector2(REVIEW_MODAL_WIDTH, 0.0)
    card.mouse_filter = Control.MOUSE_FILTER_STOP
    card.add_theme_stylebox_override("panel", _review_card_style())
    center.add_child(card)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_bottom", 16)
    card.add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    margin.add_child(box)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 8)

    var title := Label.new()
    title.theme_type_variation = &"AccentLabel"
    var definition_variant: Variant = _all_catalog_definitions.get(sketch_id, {})
    var visible_title := sketch_id
    if definition_variant is Dictionary:
        visible_title = str((definition_variant as Dictionary).get("title", sketch_id))
    title.text = "RATE / %s" % visible_title.to_upper()
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    header.add_child(title)

    _review_modal_summary = Label.new()
    _review_modal_summary.theme_type_variation = &"MicroLabel"
    _review_modal_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(_review_modal_summary)

    var close_button := Button.new()
    close_button.text = "×"
    close_button.custom_minimum_size = Vector2(28.0, 26.0)
    close_button.focus_mode = Control.FOCUS_NONE
    close_button.theme_type_variation = &"ToolButton"
    close_button.tooltip_text = "Save note and close"
    close_button.pressed.connect(_close_review_modal)
    header.add_child(close_button)
    box.add_child(header)

    box.add_child(HSeparator.new())

    var review := _review_for(sketch_id)
    for criterion: String in REVIEW_CRITERIA:
        var criterion_row := HBoxContainer.new()
        criterion_row.add_theme_constant_override("separation", 5)

        var criterion_label := Label.new()
        criterion_label.theme_type_variation = &"CaptionLabel"
        criterion_label.text = criterion.to_upper()
        criterion_label.custom_minimum_size = Vector2(124.0, 28.0)
        criterion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        criterion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        criterion_row.add_child(criterion_label)

        var row_buttons: Array[Button] = []
        for score: int in range(1, 6):
            var button := Button.new()
            button.text = str(score)
            button.custom_minimum_size = Vector2(38.0, 28.0)
            button.focus_mode = Control.FOCUS_NONE
            button.toggle_mode = true
            button.theme_type_variation = &"ToolButton"
            button.set_pressed_no_signal(int(review.get(criterion, 0)) == score)
            button.pressed.connect(_on_review_score_pressed.bind(sketch_id, criterion, score))
            criterion_row.add_child(button)
            row_buttons.append(button)
        _review_score_buttons[criterion] = row_buttons
        box.add_child(criterion_row)

    box.add_child(HSeparator.new())

    var note_label := Label.new()
    note_label.theme_type_variation = &"CaptionLabel"
    note_label.text = "WHY / NOTES"
    box.add_child(note_label)

    _review_note_edit = TextEdit.new()
    _review_note_edit.custom_minimum_size = Vector2(0.0, 104.0)
    _review_note_edit.placeholder_text = "WHAT WORKS? WHAT BREAKS? WHY IS INTERACTION / VISUAL / ALIVENESS LOW? WHAT IS MISSING?"
    _review_note_edit.text = _review_note_for(sketch_id)
    _review_note_edit.text_changed.connect(_on_review_note_changed)
    box.add_child(_review_note_edit)

    var footer := HBoxContainer.new()
    footer.add_theme_constant_override("separation", 8)

    var hint := Label.new()
    hint.theme_type_variation = &"MicroLabel"
    hint.text = "1 LOW · 5 HIGH · NOTE IS SENT WITH YOUR RATINGS"
    hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer.add_child(hint)

    var save_button := Button.new()
    save_button.text = "SAVE REVIEW"
    save_button.focus_mode = Control.FOCUS_NONE
    save_button.theme_type_variation = &"ToolButton"
    save_button.pressed.connect(_on_save_review_pressed)
    footer.add_child(save_button)
    box.add_child(footer)


func _review_card_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = ReviewDesignSystem.COLOR_SURFACE_RAISED
    style.border_color = ReviewDesignSystem.COLOR_BORDER
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_right = 4
    style.corner_radius_bottom_left = 4
    return style


func _on_open_review_modal(sketch_id: String) -> void:
    if not is_instance_valid(_review_modal):
        _build_review_modal(sketch_id)
    _review_modal_sketch_id = sketch_id
    if is_instance_valid(_review_note_edit):
        _review_note_edit.text = _review_note_for(sketch_id)
        _review_note_dirty = false
    _refresh_active_review_summary(sketch_id)
    _review_modal.visible = true
    _telemetry_event("review_modal_changed", {"open": true, "sketch_id": sketch_id})


func _close_review_modal() -> void:
    if not is_instance_valid(_review_modal) or not _review_modal.visible:
        return
    _save_review_note(_review_modal_sketch_id)
    _review_modal.visible = false
    _telemetry_event("review_modal_changed", {"open": false, "sketch_id": _review_modal_sketch_id})


func _on_review_backdrop_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
            _close_review_modal()
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch:
        var touch_event := event as InputEventScreenTouch
        if touch_event.pressed:
            _close_review_modal()
            get_viewport().set_input_as_handled()


func _on_review_note_changed() -> void:
    _review_note_dirty = true


func _on_save_review_pressed() -> void:
    _save_review_note(_review_modal_sketch_id)


func _review_note_for(sketch_id: String) -> String:
    if not _review_loaded or sketch_id.is_empty():
        return ""
    return str(_review_config.get_value(_review_section(sketch_id), "note", ""))


func _save_review_note(sketch_id: String) -> void:
    if not _review_loaded or sketch_id.is_empty() or not is_instance_valid(_review_note_edit):
        return
    var note := _review_note_edit.text.strip_edges()
    if note.length() > REVIEW_NOTE_MAX_CHARS:
        note = note.left(REVIEW_NOTE_MAX_CHARS)
        _review_note_edit.text = note
    var current := _review_note_for(sketch_id)
    if not _review_note_dirty and current == note:
        return
    _review_config.set_value(_review_section(sketch_id), "note", note)
    var error := _review_config.save(REVIEW_PATH)
    if error != OK:
        push_warning("Could not save written sketch review: error %d" % int(error))
        return
    _review_note_dirty = false
    _telemetry_event("sketch_review_note_changed", {
        "sketch_id": sketch_id,
        "note": note,
        "note_length": note.length(),
    })
    _schedule_review_checkpoint("note")


func _on_review_score_pressed(sketch_id: String, criterion: String, score: int) -> void:
    super._on_review_score_pressed(sketch_id, criterion, score)
    _refresh_active_review_summary(sketch_id)
    _schedule_review_checkpoint("rating")


func _schedule_review_checkpoint(reason: String) -> void:
    _review_checkpoint_reason = reason
    _review_checkpoint_pending = true
    _review_checkpoint_countdown = REVIEW_CHECKPOINT_DELAY


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
    if is_instance_valid(_review_modal_summary):
        var note_flag := " +NOTE" if not _review_note_for(sketch_id).is_empty() else ""
        _review_modal_summary.text = "%s · %d/6%s" % [compact_text, rated, note_flag]


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
        var note := _review_note_for(sketch_id)
        if average <= 0.0 and note.is_empty():
            continue

        var entry: Dictionary = {
            "ratings": ratings,
            "average": average,
        }
        if not note.is_empty():
            entry["note"] = note
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
