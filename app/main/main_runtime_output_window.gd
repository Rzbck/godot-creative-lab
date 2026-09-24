extends "res://app/main/main_runtime_hardened.gd"

const PresentationOutputWindowScript = preload("res://app/main/presentation_output_window.gd")

const OUTPUT_DIAGNOSTIC_REVISION: int = 8

var _presentation_output: Window = null
var _presentation_output_background: ColorRect = null
var _presentation_output_texture: TextureRect = null


func _ready() -> void:
    super._ready()
    call_deferred("_ensure_presentation_output")


func _create_render_window() -> void:
    _ensure_presentation_output()


func _ensure_presentation_output() -> void:
    if is_instance_valid(_presentation_output):
        return

    var output: Window = Window.new()
    output.name = "PresentationOutput"
    output.set_script(PresentationOutputWindowScript)
    output.force_native = true
    output.borderless = true
    output.unresizable = true
    output.always_on_top = true
    output.transient = false
    output.exclusive = false
    output.visible = false
    output.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    output.content_scale_factor = 1.0
    output.size = Vector2i(1280, 720)
    add_child(output)

    _presentation_output = output

    var output_background: ColorRect = ColorRect.new()
    output_background.name = "OutputBackground"
    output_background.color = Color.BLACK
    output_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    output_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    output.add_child(output_background)
    _presentation_output_background = output_background

    var output_texture: TextureRect = TextureRect.new()
    output_texture.name = "OutputTexture"
    output_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    output_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    output_texture.stretch_mode = TextureRect.STRETCH_SCALE
    output_texture.texture = sketch_viewport.get_texture()
    output_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    output.add_child(output_texture)
    _presentation_output_texture = output_texture

    output.connect("exit_requested", Callable(self, "_on_presentation_output_exit_requested"))
    output.connect("input_forwarded", Callable(self, "_on_presentation_output_input_forwarded"))

    _telemetry_event("presentation_output_created")


func _enter_render_fullscreen() -> void:
    if not is_instance_valid(_active_sketch) or _fullscreen_active or _presentation_transition:
        return

    _ensure_presentation_output()
    if not is_instance_valid(_presentation_output) or not is_instance_valid(_presentation_output_texture):
        push_error("Presentation output window could not be created.")
        return

    var root_window: Window = get_window()
    var current_mode: int = DisplayServer.window_get_mode()

    if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
        _remember_windowed_rect()

    _presentation_previous_mode = current_mode
    _presentation_previous_position = root_window.position
    _presentation_previous_size = root_window.size
    _presentation_previous_always_on_top = root_window.always_on_top
    _presentation_previous_unresizable = root_window.unresizable
    _presentation_previous_restore_position = _restore_position
    _presentation_previous_restore_size = _restore_size
    _presentation_previous_has_restore_rect = _has_restore_rect
    _presentation_screen = root_window.current_screen

    _presentation_transition = true
    _restoring_window = true
    _fullscreen_active = true

    # The workstation window is deliberately never resized, hidden or switched
    # to a fullscreen mode. It remains fully laid out behind the native output.
    # Esc therefore only has to hide one native window; there is no intermediate
    # monitor-sized render that can be squeezed into the workstation rectangle.
    fullscreen_overlay.visible = false
    _presentation_output_texture.texture = sketch_viewport.get_texture()
    _presentation_output.current_screen = _presentation_screen
    _presentation_output.mode = Window.MODE_FULLSCREEN

    _telemetry_event("presentation_enter_request", {
        "output_revision": OUTPUT_DIAGNOSTIC_REVISION,
        "root_unchanged": _root_window_matches_entry_state(),
        "root_position_before": _vec2i_array(_presentation_previous_position),
        "root_size_before": _vec2i_array(_presentation_previous_size),
        "output": _presentation_output_snapshot(),
    })

    _presentation_output.show()
    _presentation_output.grab_focus()

    _presentation_transition = false

    _telemetry_event("presentation_output_visible", {
        "output_revision": OUTPUT_DIAGNOSTIC_REVISION,
        "root_unchanged": _root_window_matches_entry_state(),
        "output": _presentation_output_snapshot(),
    })
    _telemetry_event("presentation_enter_complete", {
        "output_revision": OUTPUT_DIAGNOSTIC_REVISION,
        "root_unchanged": _root_window_matches_entry_state(),
        "output": _presentation_output_snapshot(),
    })


func _exit_render_fullscreen() -> void:
    if not _fullscreen_active or _presentation_transition:
        return

    _presentation_transition = true

    _telemetry_event("presentation_exit_request", {
        "output_revision": OUTPUT_DIAGNOSTIC_REVISION,
        "root_unchanged": _root_window_matches_entry_state(),
        "output": _presentation_output_snapshot(),
    })

    # Critical path: no await, no root resize, no root mode change and no main
    # fullscreen overlay. The output disappears and the already-settled UI that
    # was underneath it becomes visible in the same compositor handoff.
    _fullscreen_active = false
    if is_instance_valid(_presentation_output):
        _presentation_output.hide()

    var root_window: Window = get_window()
    root_window.grab_focus()

    _restoring_window = false
    _presentation_transition = false

    _telemetry_event("presentation_output_hidden", {
        "output_revision": OUTPUT_DIAGNOSTIC_REVISION,
        "root_unchanged": _root_window_matches_entry_state(),
        "output": _presentation_output_snapshot(),
    })
    _telemetry_event("presentation_exit_complete", {
        "output_revision": OUTPUT_DIAGNOSTIC_REVISION,
        "root_unchanged": _root_window_matches_entry_state(),
        "output": _presentation_output_snapshot(),
    })


func _sync_preview_resolution(force: bool = false) -> void:
    if _fullscreen_active:
        # Presentation reuses the already-running preview texture. Keeping the
        # SubViewport at its workstation size prevents fullscreen output from
        # exerting any minimum-size pressure on the hidden-behind UI.
        if force:
            preview_resolution.text = "%d×%d" % [sketch_viewport.size.x, sketch_viewport.size.y]
        _ensure_realtime_viewport_updates()
        return

    super._sync_preview_resolution(force)


func _on_presentation_output_exit_requested() -> void:
    _exit_render_fullscreen()


func _on_presentation_output_input_forwarded(event: InputEvent) -> void:
    if not _fullscreen_active or not is_instance_valid(_active_sketch):
        return
    sketch_viewport.push_input(event, true)


func _presentation_output_snapshot() -> Dictionary:
    if not is_instance_valid(_presentation_output):
        return {
            "exists": false,
        }

    return {
        "exists": true,
        "visible": _presentation_output.visible,
        "mode_id": int(_presentation_output.mode),
        "position": _vec2i_array(_presentation_output.position),
        "size": _vec2i_array(_presentation_output.size),
        "screen": _presentation_output.current_screen,
        "force_native": _presentation_output.force_native,
        "borderless": _presentation_output.borderless,
        "unresizable": _presentation_output.unresizable,
        "always_on_top": _presentation_output.always_on_top,
    }


func _root_window_matches_entry_state() -> bool:
    var root_window: Window = get_window()
    return DisplayServer.window_get_mode() == _presentation_previous_mode \
        and root_window.position == _presentation_previous_position \
        and root_window.size == _presentation_previous_size


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched: Dictionary = data.duplicate(true)
    enriched["output_revision"] = OUTPUT_DIAGNOSTIC_REVISION
    enriched["presentation_output"] = _presentation_output_snapshot()
    super._telemetry_event(event_name, enriched)


func _render_telemetry_snapshot() -> Dictionary:
    var snapshot: Dictionary = super._render_telemetry_snapshot()
    snapshot["presentation_output"] = _presentation_output_snapshot()
    snapshot["presentation_output_texture_valid"] = is_instance_valid(_presentation_output_texture)
    if is_instance_valid(_presentation_output_texture):
        snapshot["presentation_output_texture_visible"] = _presentation_output_texture.visible
        snapshot["presentation_output_texture_has_texture"] = _presentation_output_texture.texture != null
        snapshot["presentation_output_texture_size"] = _vec2_array(_presentation_output_texture.size)
    return snapshot


func _frame_probe_snapshot() -> Dictionary:
    var snapshot: Dictionary = super._frame_probe_snapshot()
    if is_instance_valid(_presentation_output_texture):
        snapshot["presentation_output_frame"] = _texture_frame_metrics(_presentation_output_texture.texture)
    return snapshot


func _event_needs_frame_probe(event_name: String) -> bool:
    return super._event_needs_frame_probe(event_name) \
        or event_name == "presentation_output_visible" \
        or event_name == "presentation_output_hidden"
