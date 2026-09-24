extends "res://app/main/main_runtime_atomic_exit.gd"

# Persistent live-output workstation layer.
#
# The workstation preview and the physical output are two render surfaces, but
# they share one simulation authority. Parameters and runtime state flow from the
# workstation source sketch to the native output renderer every frame.
#
# Input can originate from EITHER surface. Mouse/touch events received by the
# native output window are mapped into the shared 1280x720 design space and sent
# back to the workstation source sketch. The synchronized output renderer then
# receives the resulting state, so a touchscreen used as SCREEN 2/3/4 behaves as
# a real interactive installation surface rather than a passive display.

const LIVE_OUTPUT_REVISION: int = 14
const LIVE_PREVIEW_FPS: float = 15.0
const LIVE_PREVIEW_SHRINK: int = 2
const LIVE_OUTPUT_OVERSCAN: Vector2i = Vector2i(2, 2)
const LIVE_DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)
const LIVE_INPUT_SAMPLE_MSEC: int = 120
const TOUCH_MOUSE_SUPPRESSION_MSEC: int = 180

var _live_output_active: bool = false
var _live_output_sketch: Node = null
var _live_output_screen: int = -1
var _live_preview_accumulator: float = 0.0
var _live_state_sync_supported: bool = false
var _live_state_sync_count: int = 0

var _live_output_pointer_down: bool = false
var _live_output_input_count: int = 0
var _live_output_touch_event_count: int = 0
var _live_output_mouse_event_count: int = 0
var _live_output_last_input_kind: String = "none"
var _live_output_last_surface_position: Vector2 = Vector2.ZERO
var _live_output_last_design_position: Vector2 = LIVE_DESIGN_SIZE * 0.5
var _live_output_last_touch_index: int = -1
var _live_output_last_input_forwarded: bool = false
var _live_output_last_input_msec: int = 0
var _live_output_last_sample_msec: int = 0
var _live_output_last_touch_msec: int = -10000


func _ready() -> void:
    super._ready()
    fullscreen_button.text = "LIVE OUT"
    fullscreen_button.tooltip_text = "Start / stop LIVE OUT. Workstation, parameters and preview stay available."


func _process(delta: float) -> void:
    super._process(delta)

    if not _live_output_active:
        return

    _sync_live_output_runtime_state()

    _live_preview_accumulator += delta
    var preview_interval: float = 1.0 / LIVE_PREVIEW_FPS
    if _live_preview_accumulator >= preview_interval:
        _live_preview_accumulator = fmod(_live_preview_accumulator, preview_interval)
        sketch_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
        if is_instance_valid(_active_sketch) and _active_sketch is CanvasItem:
            (_active_sketch as CanvasItem).queue_redraw()

    # Keep the toolbar compact. The previous long "LIVE PREVIEW 15 FPS" label
    # increased ProjectView's minimum width enough to push the 1280 px shell into
    # negative coordinates while LIVE OUT was running (visible in telemetry).
    if is_instance_valid(preview_resolution):
        preview_resolution.text = "%d×%d" % [
            sketch_viewport.size.x,
            sketch_viewport.size.y,
        ]
        preview_resolution.tooltip_text = "LIVE preview budget: %d FPS / output: realtime" % int(LIVE_PREVIEW_FPS)


func _ensure_realtime_viewport_updates() -> void:
    if _live_output_active:
        if sketch_viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS:
            sketch_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
        return

    super._ensure_realtime_viewport_updates()


func _enter_render_fullscreen() -> void:
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

    if _live_output_sketch.has_method("set_live_sync_follower"):
        _live_output_sketch.call("set_live_sync_follower", true)

    _sync_all_live_output_parameters()
    _live_state_sync_supported = _has_live_state_sync_contract()
    _live_state_sync_count = 0
    _live_output_pointer_down = false
    _live_output_input_count = 0
    _live_output_touch_event_count = 0
    _live_output_mouse_event_count = 0
    _live_output_last_input_kind = "none"
    _live_output_last_touch_index = -1
    _live_output_last_input_forwarded = false
    _live_output_last_touch_msec = -10000
    _sync_live_output_runtime_state(true)

    if is_instance_valid(_presentation_output_texture):
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
    get_window().grab_focus()

    page_tag.text = "[LIVE OUT]"
    status_label.text = "LIVE OUT / SCREEN %d / TOUCH+POINTER ACTIVE / F11 OR ESC=STOP" % [
        _live_output_screen + 1,
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
        "single_simulation_authority": true,
        "state_sync_supported": _live_state_sync_supported,
        "external_pointer_supported": _active_sketch.has_method("apply_external_pointer"),
        "source_sync_state": _live_sync_debug_state(_active_sketch),
        "output_sync_state": _live_sync_debug_state(_live_output_sketch),
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

    if is_instance_valid(_presentation_output):
        _presentation_output.hide()

    _live_output_active = false
    _live_preview_accumulator = 0.0
    _live_output_pointer_down = false
    sketch_viewport_container.stretch_shrink = 1
    sketch_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

    _destroy_live_output_sketch()
    _live_state_sync_supported = false

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
        "state_sync_count": _live_state_sync_count,
        "input_count": _live_output_input_count,
        "touch_event_count": _live_output_touch_event_count,
        "mouse_event_count": _live_output_mouse_event_count,
        "last_input_forwarded": _live_output_last_input_forwarded,
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


func _has_live_state_sync_contract() -> bool:
    return is_instance_valid(_active_sketch) \
        and is_instance_valid(_live_output_sketch) \
        and _active_sketch.has_method("get_live_sync_state") \
        and _live_output_sketch.has_method("apply_live_sync_state")


func _sync_live_output_runtime_state(force: bool = false) -> void:
    if not is_instance_valid(_active_sketch) or not is_instance_valid(_live_output_sketch):
        return

    _live_state_sync_supported = _has_live_state_sync_contract()
    if not _live_state_sync_supported:
        if force:
            push_warning(
                "Sketch %s has no live synchronization contract; output cannot be guaranteed identical to preview."
                % str(_active_definition.get("id", "unknown"))
            )
        return

    var state_variant: Variant = _active_sketch.call("get_live_sync_state")
    if not state_variant is Dictionary:
        if force:
            push_warning("Live synchronization state must be a Dictionary.")
        return

    _live_output_sketch.call("apply_live_sync_state", state_variant as Dictionary)
    _live_state_sync_count += 1


func _live_sync_debug_state(sketch: Node) -> Dictionary:
    if not is_instance_valid(sketch):
        return {"valid": false}
    if not sketch.has_method("get_live_sync_debug_state"):
        return {
            "valid": true,
            "debug_contract": false,
        }

    var state_variant: Variant = sketch.call("get_live_sync_debug_state")
    if state_variant is Dictionary:
        var state: Dictionary = (state_variant as Dictionary).duplicate(true)
        state["valid"] = true
        state["debug_contract"] = true
        return state

    return {
        "valid": true,
        "debug_contract": false,
    }


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
    _sync_live_output_runtime_state()


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


func _on_presentation_output_input_forwarded(event: InputEvent) -> void:
    if not _live_output_active \
    or not is_instance_valid(_active_sketch) \
    or not is_instance_valid(_presentation_output):
        return

    var now_msec: int = Time.get_ticks_msec()
    var surface_size: Vector2 = Vector2(_presentation_output.size)

    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        _live_output_last_touch_msec = now_msec
        _live_output_pointer_down = touch.pressed
        _forward_live_output_pointer(
            "touch_down" if touch.pressed else "touch_up",
            touch.position,
            surface_size,
            touch.pressed,
            touch.index,
            true
        )
        if not touch.pressed:
            _publish_telemetry_to_github("live_output_touch_complete")
        return

    if event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        _live_output_last_touch_msec = now_msec
        _live_output_pointer_down = true
        var emit_touch_sample: bool = now_msec - _live_output_last_sample_msec >= LIVE_INPUT_SAMPLE_MSEC
        _forward_live_output_pointer(
            "touch_drag",
            drag.position,
            surface_size,
            true,
            drag.index,
            emit_touch_sample
        )
        return

    # Windows can synthesize mouse events from a touchscreen. Ignore those for a
    # short period after native touch activity so one finger does not generate a
    # duplicate press/drag stream.
    if now_msec - _live_output_last_touch_msec <= TOUCH_MOUSE_SUPPRESSION_MSEC:
        return

    if event is InputEventMouseButton:
        var button: InputEventMouseButton = event as InputEventMouseButton
        if button.button_index != MOUSE_BUTTON_LEFT:
            return
        _live_output_pointer_down = button.pressed
        _forward_live_output_pointer(
            "mouse_down" if button.pressed else "mouse_up",
            button.position,
            surface_size,
            button.pressed,
            -1,
            true
        )
        if not button.pressed:
            _publish_telemetry_to_github("live_output_pointer_complete")
        return

    if event is InputEventMouseMotion:
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        var emit_mouse_sample: bool = now_msec - _live_output_last_sample_msec >= LIVE_INPUT_SAMPLE_MSEC
        _forward_live_output_pointer(
            "mouse_move",
            motion.position,
            surface_size,
            _live_output_pointer_down,
            -1,
            emit_mouse_sample
        )


func _forward_live_output_pointer(
    input_kind: String,
    surface_position: Vector2,
    surface_size: Vector2,
    pressed: bool,
    touch_index: int,
    emit_telemetry_sample: bool
) -> void:
    _live_output_input_count += 1
    if input_kind.begins_with("touch"):
        _live_output_touch_event_count += 1
    elif input_kind.begins_with("mouse"):
        _live_output_mouse_event_count += 1

    _live_output_last_input_kind = input_kind
    _live_output_last_surface_position = surface_position
    _live_output_last_design_position = _live_surface_to_design(surface_position, surface_size)
    _live_output_last_touch_index = touch_index
    _live_output_last_input_msec = Time.get_ticks_msec()
    _live_output_last_input_forwarded = false

    if _active_sketch.has_method("apply_external_pointer"):
        _active_sketch.call(
            "apply_external_pointer",
            surface_position,
            surface_size,
            pressed,
            true
        )
        _live_output_last_input_forwarded = true

    # Apply to the follower immediately instead of waiting for the next process
    # frame. Touch feedback on an installation screen should feel direct.
    _sync_live_output_runtime_state()

    if emit_telemetry_sample:
        _live_output_last_sample_msec = _live_output_last_input_msec
        _telemetry_event("live_output_pointer_input", {
            "input_kind": input_kind,
            "touch_index": touch_index,
            "pressed": pressed,
            "forwarded": _live_output_last_input_forwarded,
            "surface_position": _vec2_array(surface_position),
            "surface_size": _vec2_array(surface_size),
            "design_position": _vec2_array(_live_output_last_design_position),
            "input_count": _live_output_input_count,
            "touch_event_count": _live_output_touch_event_count,
            "mouse_event_count": _live_output_mouse_event_count,
            "source_sync_state": _live_sync_debug_state(_active_sketch),
            "output_sync_state": _live_sync_debug_state(_live_output_sketch),
        })


func _live_surface_to_design(point: Vector2, surface_size: Vector2) -> Vector2:
    var safe_x: float = maxf(1.0, surface_size.x)
    var safe_y: float = maxf(1.0, surface_size.y)
    var scale_value: float = minf(safe_x / LIVE_DESIGN_SIZE.x, safe_y / LIVE_DESIGN_SIZE.y)
    scale_value = maxf(0.0001, scale_value)
    var fitted_size: Vector2 = LIVE_DESIGN_SIZE * scale_value
    var origin: Vector2 = (surface_size - fitted_size) * 0.5
    return (point - origin) / scale_value


func _input(event: InputEvent) -> void:
    if _live_output_active and event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_F11:
                _stop_live_output("keyboard")
                get_viewport().set_input_as_handled()
                return

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
    enriched["live_state_sync_supported"] = _live_state_sync_supported
    enriched["live_state_sync_count"] = _live_state_sync_count
    enriched["live_output_input_count"] = _live_output_input_count
    enriched["live_output_touch_event_count"] = _live_output_touch_event_count
    enriched["live_output_mouse_event_count"] = _live_output_mouse_event_count
    enriched["live_output_last_input_kind"] = _live_output_last_input_kind
    enriched["live_output_last_input_forwarded"] = _live_output_last_input_forwarded
    enriched["live_output_last_surface_position"] = _vec2_array(_live_output_last_surface_position)
    enriched["live_output_last_design_position"] = _vec2_array(_live_output_last_design_position)
    enriched["live_output_last_touch_index"] = _live_output_last_touch_index
    super._telemetry_event(event_name, enriched)
