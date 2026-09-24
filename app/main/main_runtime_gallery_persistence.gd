extends "res://app/main/main_runtime_live_output.gd"

# Gallery + persistence workstation layer.
#
# Gallery cards own a small render surface showing the actual sketch. The surface
# is frozen by default (a cheap still preview) and only the card under the pointer
# is allowed to process and render continuously. This keeps the gallery visual
# without running every generative patch in the background.
#
# Exposed sketch parameters are persisted locally with ConfigFile under user://.
# They are restored before the parameter inspector is built, so sliders/toggles,
# preview and LIVE OUT all begin from the same saved state on the next session.

const GALLERY_RUNTIME_REVISION: int = 1
const GALLERY_PREVIEW_SIZE: Vector2i = Vector2i(384, 216)
const SETTINGS_PATH: String = "user://creative_lab_sketch_settings.cfg"
const SETTINGS_SAVE_DELAY: float = 0.35

var _sketch_settings: ConfigFile = ConfigFile.new()
var _settings_loaded: bool = false
var _settings_save_pending: bool = false
var _settings_save_countdown: float = 0.0
var _settings_dirty_count: int = 0

# sketch_id -> { card, viewport, sketch }
var _gallery_previews: Dictionary = {}
var _gallery_live_preview_id: String = ""


func _ready() -> void:
    _load_sketch_settings()
    super._ready()

    _telemetry_event("gallery_persistence_ready", {
        "gallery_runtime_revision": GALLERY_RUNTIME_REVISION,
        "gallery_preview_count": _gallery_previews.size(),
        "settings_loaded": _settings_loaded,
    })


func _process(delta: float) -> void:
    super._process(delta)

    if not _settings_save_pending:
        return

    _settings_save_countdown -= delta
    if _settings_save_countdown <= 0.0:
        _flush_sketch_settings()


func _load_sketch_settings() -> void:
    _sketch_settings = ConfigFile.new()
    var load_error: Error = _sketch_settings.load(SETTINGS_PATH)
    if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
        push_warning("Could not load sketch settings: error %d" % int(load_error))
    _settings_loaded = load_error == OK or load_error == ERR_FILE_NOT_FOUND


func _settings_section(sketch_id: String) -> String:
    return "sketch_%s" % sketch_id


func _apply_saved_parameters_to(sketch: Node, sketch_id: String) -> int:
    if not _settings_loaded or not is_instance_valid(sketch):
        return 0
    if not sketch.has_method("get_parameter_schema") or not sketch.has_method("set_parameter_value"):
        return 0

    var schema_variant: Variant = sketch.call("get_parameter_schema")
    if not schema_variant is Array:
        return 0

    var section: String = _settings_section(sketch_id)
    var restored_count: int = 0

    for item: Variant in schema_variant as Array:
        if not item is Dictionary:
            continue
        var parameter_id: String = str((item as Dictionary).get("id", ""))
        if parameter_id.is_empty() or not _sketch_settings.has_section_key(section, parameter_id):
            continue

        sketch.call(
            "set_parameter_value",
            parameter_id,
            _sketch_settings.get_value(section, parameter_id)
        )
        restored_count += 1

    return restored_count


func _persist_active_parameter(parameter_id: String) -> void:
    if not _settings_loaded or not is_instance_valid(_active_sketch):
        return
    if not _active_sketch.has_method("get_parameter_value"):
        return

    var sketch_id: String = str(_active_definition.get("id", ""))
    if sketch_id.is_empty():
        return

    var actual_value: Variant = _active_sketch.call("get_parameter_value", parameter_id)
    _sketch_settings.set_value(_settings_section(sketch_id), parameter_id, actual_value)
    _settings_dirty_count += 1
    _settings_save_pending = true
    _settings_save_countdown = SETTINGS_SAVE_DELAY

    _sync_gallery_preview_parameter(sketch_id, parameter_id, actual_value)


func _flush_sketch_settings() -> void:
    if not _settings_loaded or not _settings_save_pending:
        return

    var dirty_count: int = _settings_dirty_count
    var save_error: Error = _sketch_settings.save(SETTINGS_PATH)
    if save_error != OK:
        push_warning("Could not save sketch settings: error %d" % int(save_error))
        _settings_save_countdown = SETTINGS_SAVE_DELAY
        return

    _settings_save_pending = false
    _settings_save_countdown = 0.0
    _settings_dirty_count = 0

    _telemetry_event("sketch_settings_saved", {
        "gallery_runtime_revision": GALLERY_RUNTIME_REVISION,
        "saved_change_count": dirty_count,
        "save_ok": true,
    })


func _build_gallery() -> void:
    _destroy_gallery_previews()

    for child: Node in gallery_grid.get_children():
        child.queue_free()

    for definition: Dictionary in _catalog:
        _build_gallery_preview_card(definition)


func _build_gallery_preview_card(definition: Dictionary) -> void:
    var sketch_id: String = str(definition.get("id", "unknown"))
    var index_text: String = str(definition.get("index", "---"))
    var title_text: String = str(definition.get("title", "UNTITLED"))
    var engine_text: String = str(definition.get("engine", "GODOT"))
    var description_text: String = str(definition.get("description", ""))
    var tag_text: String = _definition_tags_text(definition)

    var card: Button = Button.new()
    card.custom_minimum_size = Vector2(250.0, 218.0)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.focus_mode = Control.FOCUS_NONE
    card.theme_type_variation = &"GalleryCardButton"
    card.text = ""
    card.tooltip_text = description_text
    card.clip_contents = true

    var content_margin: MarginContainer = MarginContainer.new()
    content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    content_margin.add_theme_constant_override("margin_left", 10)
    content_margin.add_theme_constant_override("margin_top", 10)
    content_margin.add_theme_constant_override("margin_right", 10)
    content_margin.add_theme_constant_override("margin_bottom", 10)
    content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(content_margin)

    var stack: VBoxContainer = VBoxContainer.new()
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation", 7)
    stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    content_margin.add_child(stack)

    var viewport: SubViewport = SubViewport.new()
    viewport.size = GALLERY_PREVIEW_SIZE
    viewport.disable_3d = true
    viewport.handle_input_locally = false
    viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    card.add_child(viewport)

    var preview: TextureRect = TextureRect.new()
    preview.custom_minimum_size = Vector2(0.0, 140.0)
    preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    preview.texture = viewport.get_texture()
    preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(preview)

    var index_label: Label = Label.new()
    index_label.theme_type_variation = &"MicroLabel"
    index_label.text = index_text
    index_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(index_label)

    var title_label: Label = Label.new()
    title_label.theme_type_variation = &"AccentLabel"
    title_label.text = title_text
    title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(title_label)

    var meta_label: Label = Label.new()
    meta_label.theme_type_variation = &"MicroLabel"
    meta_label.text = "%s / %s" % [engine_text, tag_text]
    meta_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(meta_label)

    var scene_path: String = str(definition.get("scene", ""))
    var scene_resource: Resource = load(scene_path)
    var preview_sketch: Node = null
    if scene_resource is PackedScene:
        preview_sketch = (scene_resource as PackedScene).instantiate()
        viewport.add_child(preview_sketch)
        _apply_saved_parameters_to(preview_sketch, sketch_id)
        preview_sketch.set_process_input(false)

    _gallery_previews[sketch_id] = {
        "card": card,
        "viewport": viewport,
        "sketch": preview_sketch,
    }

    card.pressed.connect(_open_sketch.bind(definition))
    card.mouse_entered.connect(_on_gallery_card_hover.bind(sketch_id, true))
    card.mouse_exited.connect(_on_gallery_card_hover.bind(sketch_id, false))
    gallery_grid.add_child(card)

    # One rendered frame becomes the static thumbnail. No preview simulation is
    # left running after that frame unless the pointer is over this card.
    call_deferred("_freeze_gallery_preview", sketch_id)


func _on_gallery_card_hover(sketch_id: String, active: bool) -> void:
    if active:
        _activate_gallery_preview(sketch_id)
        return

    if _gallery_live_preview_id == sketch_id:
        _freeze_gallery_preview(sketch_id)
        _gallery_live_preview_id = ""


func _activate_gallery_preview(sketch_id: String) -> void:
    if _gallery_live_preview_id == sketch_id:
        return

    if not _gallery_live_preview_id.is_empty():
        _freeze_gallery_preview(_gallery_live_preview_id)

    if not _gallery_previews.has(sketch_id):
        return

    var entry: Dictionary = _gallery_previews[sketch_id]
    var viewport: SubViewport = entry.get("viewport") as SubViewport
    var sketch: Node = entry.get("sketch") as Node
    if not is_instance_valid(viewport) or not is_instance_valid(sketch):
        return

    _apply_saved_parameters_to(sketch, sketch_id)
    sketch.process_mode = Node.PROCESS_MODE_INHERIT
    sketch.set_process(true)
    sketch.set_process_input(false)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    if sketch is CanvasItem:
        (sketch as CanvasItem).queue_redraw()

    _gallery_live_preview_id = sketch_id


func _freeze_gallery_preview(sketch_id: String) -> void:
    if not _gallery_previews.has(sketch_id):
        return

    var entry: Dictionary = _gallery_previews[sketch_id]
    var viewport: SubViewport = entry.get("viewport") as SubViewport
    var sketch: Node = entry.get("sketch") as Node
    if is_instance_valid(sketch):
        sketch.set_process_input(false)
        sketch.process_mode = Node.PROCESS_MODE_DISABLED
    if is_instance_valid(viewport):
        viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _freeze_all_gallery_previews() -> void:
    for sketch_id_variant: Variant in _gallery_previews.keys():
        _freeze_gallery_preview(str(sketch_id_variant))
    _gallery_live_preview_id = ""


func _refresh_gallery_preview(sketch_id: String) -> void:
    if not _gallery_previews.has(sketch_id):
        return

    var entry: Dictionary = _gallery_previews[sketch_id]
    var viewport: SubViewport = entry.get("viewport") as SubViewport
    var sketch: Node = entry.get("sketch") as Node
    if not is_instance_valid(viewport) or not is_instance_valid(sketch):
        return

    _apply_saved_parameters_to(sketch, sketch_id)
    if sketch is CanvasItem:
        (sketch as CanvasItem).queue_redraw()

    if _gallery_live_preview_id == sketch_id:
        sketch.process_mode = Node.PROCESS_MODE_INHERIT
        viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    else:
        viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _sync_gallery_preview_parameter(sketch_id: String, parameter_id: String, value: Variant) -> void:
    if not _gallery_previews.has(sketch_id):
        return

    var entry: Dictionary = _gallery_previews[sketch_id]
    var viewport: SubViewport = entry.get("viewport") as SubViewport
    var sketch: Node = entry.get("sketch") as Node
    if not is_instance_valid(sketch) or not sketch.has_method("set_parameter_value"):
        return

    sketch.call("set_parameter_value", parameter_id, value)
    if sketch is CanvasItem:
        (sketch as CanvasItem).queue_redraw()
    if is_instance_valid(viewport) and _gallery_live_preview_id != sketch_id:
        viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _destroy_gallery_previews() -> void:
    _gallery_live_preview_id = ""
    for entry_variant: Variant in _gallery_previews.values():
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant as Dictionary
        var sketch: Node = entry.get("sketch") as Node
        if is_instance_valid(sketch):
            sketch.process_mode = Node.PROCESS_MODE_DISABLED
    _gallery_previews.clear()


func _build_parameter_inspector(sketch: Node) -> void:
    var sketch_id: String = str(_active_definition.get("id", ""))
    var restored_count: int = _apply_saved_parameters_to(sketch, sketch_id)

    super._build_parameter_inspector(sketch)

    _telemetry_event("sketch_settings_restored", {
        "gallery_runtime_revision": GALLERY_RUNTIME_REVISION,
        "restored_count": restored_count,
        "had_saved_values": restored_count > 0,
    })


func _on_numeric_parameter_changed(
    value: float,
    parameter_id: String,
    value_label: Label,
    is_integer: bool
) -> void:
    super._on_numeric_parameter_changed(value, parameter_id, value_label, is_integer)
    _persist_active_parameter(parameter_id)


func _on_bool_parameter_changed(enabled: bool, parameter_id: String) -> void:
    super._on_bool_parameter_changed(enabled, parameter_id)
    _persist_active_parameter(parameter_id)


func _open_sketch(definition: Dictionary) -> void:
    _freeze_all_gallery_previews()
    super._open_sketch(definition)


func _show_gallery() -> void:
    _freeze_all_gallery_previews()
    super._show_gallery()

    for definition: Dictionary in _catalog:
        _refresh_gallery_preview(str(definition.get("id", "")))

    status_label.text = "GALLERY / %d PATCHES / HOVER=LIVE PREVIEW / CLICK=OPEN" % _catalog.size()


func _show_settings() -> void:
    _freeze_all_gallery_previews()
    super._show_settings()


func _show_about() -> void:
    _freeze_all_gallery_previews()
    super._show_about()


func _unload_active_sketch() -> void:
    _flush_sketch_settings()
    super._unload_active_sketch()


func _close_window() -> void:
    _flush_sketch_settings()
    super._close_window()


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched: Dictionary = data.duplicate(true)
    enriched["gallery_runtime_revision"] = GALLERY_RUNTIME_REVISION
    enriched["gallery_preview_count"] = _gallery_previews.size()
    enriched["gallery_preview_live"] = not _gallery_live_preview_id.is_empty()
    enriched["settings_loaded"] = _settings_loaded
    enriched["settings_save_pending"] = _settings_save_pending
    super._telemetry_event(event_name, enriched)
