extends "res://app/main/main_runtime_atomic_exit.gd"

# Persistent live-output workstation layer.
#
# Presentation is now a real second render surface rather than a temporary
# fullscreen state of the workstation window. The control UI never moves,
# resizes, hides or changes native mode. A second native borderless Window owns
# its own sketch instance, so Windows/Godot does not have to sample the preview
# SubViewport across native windows (the path that previously produced a gray
# output on this GPU).
#
# While LIVE OUT is active the normal preview stays interactive but is rendered
# at half linear resolution and 15 Hz. Parameter changes are mirrored to the
# output renderer immediately. This keeps the control surface useful while the
# full-resolution output continues at the normal application frame rate.

const LIVE_OUTPUT_REVISION: int = 12
const LIVE_PREVIEW_FPS: float = 15.0
const LIVE_PREVIEW_SHRINK: int = 2
const LIVE_OUTPUT_OVERSCAN: Vector2i = Vector2i(2, 2)

var _live_output_active: bool = false
var _live_output_sketch: Node = null
var _live_output_screen: int = -1
var _live_preview_accumulator: float = 0.0


func _ready() -> void:
    super._ready()
    fullscreen_button.tooltip_text = "Start / stop LIVE OUT. The workstation stays open for parameters and preview."


func _process(delta: float) -> void:
    super._process(delta)

    if not _live_output_active:
        return

    _live_preview_accumulator += delta
    var preview_interval: float = 1.0 / LIVE_PREVIEW_FPS
    if _live_preview_accumulator >= preview_interval:
        _live_preview_accumulator = fmod(_live_preview_accumulator, preview_interval)
        sketch_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
        if is_instance_valid(_active_sketch) and _active_sketch is CanvasItem:
            (_active_sketch as CanvasItem).queue_redraw()

    if is_instance_valid(preview_resolution):
        preview_resolution.text = "%d×%d / LIVE PREVIEW %d FPS" % [
            sketch_viewport.size.x,
            sketch_viewport.size.y,
            int(LIVE_PREVIEW_FPS),
        ]


func _ensure_realtime_viewport_updates() -> void:
    if _live_output_active:
        # The output renderer is native and realtime. The workstation preview is
        # deliberately budgeted; UPDATE_ONCE is armed by _process at 15 Hz.
        if sketch_viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS:
            sketch_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
        return

    super._ensure_realtime_viewport_updates()


func _enter_render_fullscreen() -> void:
    # The old button/F11 name is retained for compatibility, but the behavior is
    # now a persistent LIVE OUT toggle. There is no fullscreen transition of the
    # workstation itself.
    if _live_output_active:
        _stop_live_output("toggle")
        return

    if not is_instance_valid(_active_sketch) or _presentation_transition:
        return

    _ensure_presentation_output()
    if not is_instance_valid(_presentation_output):
        push_error("Live output window could not be created.")
        return

    var scene_path: String = str(_active_definition.get("scene", ""))
    var scene_resource: Resource = load(scene_path)
    if not scene_resource is PackedScene:
        push_error("Cannot load live output sketch scene: %s" % scene_path)
        return

    _presentation_transition = true
    _live_output_screen = _resolve_output_screen()

    _destroy_live_output_sketch()
    _live_output_sketch = (scene_resource as PackedScene).instantiate()
    _presentation_output.add_child(_live_output_sketch)
    _sync_all_live_output_parameters()

    if is_instance_valid(_presentation_output_texture):
        # Important: do not sample the root preview SubViewport in a native
        # secondary window. The output sketch renders locally in this Window.
        _presentation_output_texture.visible = false
        _presentation_output_texture.texture = null
    if is_instance_valid(_presentation_output_background):
        _presentation_output_background.visible = true

    var screen_position: Vector2i = DisplayServer.screen_get_position(_live_output_screen)
    var screen_size: Vector2i = DisplayServer.screen_get_size(_live_output_screen)
    var target_position: Vector2i = screen_position - Vector2i.ONE
    var target_size: Vector2i = screen_size + LIVE_OUTPUT_OVERSCAN

    _presentation_output.hide()
    _presentation_output.mode = Window.MODE_WINDOWED
    _presentation_output.current_screen = _live_output_screen
    _presentation_output.position = target_position
    _presentation_output.size = target_size
    _presentation_output.borderless = true
    _presentation_output.unresizable = true
    _presentation_output.always_on_top = true
    _presentation_output.transient = false
    _presentation_output.exclusive = false

    _live_output_active = true
    _live_preview_accumulator = 0.0
    sketch_viewport_container.stretch = true
    sketch_viewport_container.stretch_shrink = LIVE_PREVIEW_SHRINK
    sketch_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

    _presentation_output.show()

    # A second display should never steal the control surface. Re-focus the
    # workstation immediately; the output stays visible because it is native and
    # always-on-top on its own monitor.
    get_window().grab_focus()

    page_tag.text = "[LIVE OUT]"
    status_label.text = "LIVE OUT / SCREEN %d / PREVIEW %d FPS / F11 OR ESC=STOP" % [
        _live_output_screen + 1,
        int(LIVE_PREVIEW_FPS),
    ]

    _presentation_transition = false

    _telemetry_event("live_output_started", {
        "live_output_revision": LIVE_OUTPUT_REVISION,
        "screen": _live_output_screen,
        "screen_position": _vec2i_array(screen_position),
        "screen_size": _vec2i_array(screen_size),
        "output_position": _vec2i_array(target_position),
        "output_size": _vec2i_array(target_size),
        "preview_fps": LIVE_PREVIEW_FPS,
        "preview_shrink": LIVE_PREVIEW_SHRINK,
        "separate_renderer": true,
        "root_mode": DisplayServer.window_get_mode(),
        "root_position": _vec2i_array(DisplayServer.window_get_position()),
        "root_size": _vec2i_array(DisplayServer.window_get_size()),
    })
    _publish_telemetry_to_github("live_output_started")


func _exit_render_fullscreen() -> void:
    if _live_output_active:
        _stop_live_output("exit")
        return

    if _fullscreen_active:
        super._exit_render_fullscreen()


func _stop_live_output(reason: String) -> void:
    if not _live_output_active and not is_instance_valid(_live_output_sketch):
        return

    _presentation_transition = true

    # The visual handoff is intentionally one operation: hide the independent
    # output Window. The workstation has remained untouched and is already fully
    # laid out, so there is nothing to restore or animate.
    if is_instance_valid(_presentation_output):
        _presentation_output.hide()

    _live_output_active = false
    _live_preview_accumulator = 0.0
    sketch_viewport_container.stretch_shrink = 1
    sketch_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

    _destroy_live_output_sketch()

    if is_instance_valid(_presentation_output_texture):
        _presentation_output_texture.texture = sketch_viewport.get_texture()
        _presentation_output_texture.visible = false

    page_tag.text = "[LIVE]"
    if is_instance_valid(_active_sketch):
        status_label.text = "ACTIVE / %s / ESC=GALLERY / F11=LIVE OUT" % str(
            _active_definition.get("id", "unknown")
        ).to_upper()

    get_window().grab_focus()
    _presentation_transition = false

    _telemetry_event("live_output_stopped", {
        "live_output_revision": LIVE_OUTPUT_REVISION,
        "reason": reason,
        "screen": _live_output_screen,
        "preview_update_mode": int(sketch_viewport.render_target_update_mode),
        "root_mode": DisplayServer.window_get_mode(),
        "root_position": _vec2i_array(DisplayServer.window_get_position()),
        "root_size": _vec2i_array(DisplayServer.window_get_size()),
    })
    _publish_telemetry_to_github("live_output_stopped")


func _destroy_live_output_sketch() -> void:
    if not is_instance_valid(_live_output_sketch):
        _live_output_sketch = null
        return

    var parent: Node = _live_output_sketch.get_parent()
    if is_instance_valid(parent):
        parent.remove_child(_live_output_sketch)
    _live_output_sketch.queue_free()
    _live_output_sketch = null


func _sync_all_live_output_parameters() -> void:
    if not is_instance_valid(_active_sketch) or not is_instance_valid(_live_output_sketch):
        return
    if not _active_sketch.has_method("get_parameter_schema") \
    or not _active_sketch.has_method("get_parameter_value") \
    or not _live_output_sketch.has_method("set_parameter_value"):
        return

    var schema_variant: Variant = _active_sketch.call("get_parameter_schema")
    if not schema_variant is Array:
        return

    for item: Variant in schema_variant as Array:
        if not item is Dictionary:
            continue
        var parameter_id: String = str((item as Dictionary).get("id", ""))
        if parameter_id.is_empty():
            continue
        _sync_live_output_parameter(parameter_id)


func _sync_live_output_parameter(parameter_id: String) -> void:
    if not _live_output_active and not is_instance_valid(_live_output_sketch):
        return
    if not is_instance_valid(_active_sketch) or not is_instance_valid(_live_output_sketch):
        return
    if not _active_sketch.has_method("get_parameter_value") \
    or not _live_output_sketch.has_method("set_parameter_value"):
        return

    var value: Variant = _active_sketch.call("get_parameter_value", parameter_id)
    _live_output_sketch.call("set_parameter_value", parameter_id, value)


func _on_numeric_parameter_changed(
    value: float,
    parameter_id: String,
    value_label: Label,
    is_integer: bool
) -> void:
    super._on_numeric_parameter_changed(value, parameter_id, value_label, is_integer)
    _sync_live_output_parameter(parameter_id)


func _on_bool_parameter_changed(enabled: bool, parameter_id: String) -> void:
    super._on_bool_parameter_changed(enabled, parameter_id)
    _sync_live_output_parameter(parameter_id)


func _on_presentation_output_input_forwarded(_event: InputEvent) -> void:
    # The output sketch is a direct child of the native output Window, so Godot
    # already dispatches that Window's input to it. Do not mirror output input
    # back into the workstation preview.
    pass


func _input(event: InputEvent) -> void:
    if _live_output_active and event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_F11:
                _stop_live_output("keyboard")
                get_viewport().set_input_as_handled()
                return

    # LIVE OUT deliberately leaves _fullscreen_active false, so the inherited
    # workstation input path keeps parameter controls, custom resize and normal
    # UI interaction alive while the output is running.
    super._input(event)


func _unload_active_sketch() -> void:
    if _live_output_active or is_instance_valid(_live_output_sketch):
        _stop_live_output("project_unload")
    super._unload_active_sketch()


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched: Dictionary = data.duplicate(true)
    enriched["live_output_revision"] = LIVE_OUTPUT_REVISION
    enriched["live_output_active"] = _live_output_active
    enriched["live_output_screen"] = _live_output_screen
    enriched["live_output_renderer_valid"] = is_instance_valid(_live_output_sketch)
    super._telemetry_event(event_name, enriched)
