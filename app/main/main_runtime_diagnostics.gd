extends "res://app/main/main_runtime_window_state.gd"

# Diagnostic runtime layer. It does not change fullscreen/window behavior.
# It enriches every telemetry event with enough state to distinguish:
# - native window state failures,
# - Control/container layout failures,
# - SubViewport sizing/update failures,
# - fullscreen TextureRect wiring/visibility failures,
# - and genuinely blank/flat rendered frames.
#
# Pixel telemetry is numeric only. No screenshots or raw pixels are published.

const DIAGNOSTIC_VERSION: int = 4
const DIAGNOSTIC_STATE_POLL_MSEC: int = 50
const FRAME_SAMPLE_COLUMNS: int = 20
const FRAME_SAMPLE_ROWS: int = 12

var _diagnostic_last_poll_msec: int = 0
var _diagnostic_last_state_signature: String = ""
var _diagnostic_git_head: String = ""
var _fullscreen_probe_generation: int = 0
var _post_exit_probe_generation: int = 0


func _ready() -> void:
    super._ready()
    call_deferred("_emit_diagnostics_ready")


func _process(delta: float) -> void:
    super._process(delta)

    if DisplayServer.get_name() == "headless":
        return

    var now_msec: int = Time.get_ticks_msec()
    if now_msec - _diagnostic_last_poll_msec < DIAGNOSTIC_STATE_POLL_MSEC:
        return
    _diagnostic_last_poll_msec = now_msec

    if not (_fullscreen_active or _presentation_transition or _restoring_window):
        return

    var signature: String = _diagnostic_state_signature()
    if signature == _diagnostic_last_state_signature:
        return

    _diagnostic_last_state_signature = signature
    _telemetry_event("runtime_state_change")


func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo \
        and (key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_F11):
            _telemetry_event("input_key", {
                "keycode": int(key_event.keycode),
                "fullscreen_before_input": _fullscreen_active,
            })

    super._input(event)


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched: Dictionary = data.duplicate(true)
    enriched["diagnostic_version"] = DIAGNOSTIC_VERSION
    enriched["runtime"] = _runtime_telemetry_snapshot()
    enriched["render"] = _render_telemetry_snapshot()

    if not enriched.has("layout"):
        enriched["layout"] = _layout_telemetry_snapshot()

    if _event_needs_frame_probe(event_name):
        enriched["frame_probe"] = _frame_probe_snapshot()

    super._telemetry_event(event_name, enriched)

    if event_name == "presentation_enter_complete":
        _fullscreen_probe_generation += 1
        call_deferred("_collect_fullscreen_probe_series", _fullscreen_probe_generation)
    elif event_name == "presentation_exit_complete":
        _post_exit_probe_generation += 1
        call_deferred("_collect_post_exit_probe_series", _post_exit_probe_generation)


func _emit_diagnostics_ready() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    _diagnostic_last_state_signature = _diagnostic_state_signature()
    _telemetry_event("diagnostics_ready")


func _collect_fullscreen_probe_series(generation: int) -> void:
    var frame_offsets: Array[int] = [1, 6, 30, 90]
    var previous_offset: int = 0

    for probe_index: int in range(frame_offsets.size()):
        var frame_offset: int = frame_offsets[probe_index]
        for _frame: int in range(frame_offset - previous_offset):
            await get_tree().process_frame
        previous_offset = frame_offset

        if generation != _fullscreen_probe_generation or not _fullscreen_active:
            return

        _telemetry_event("render_probe_fullscreen", {
            "probe_index": probe_index,
            "frame_offset": frame_offset,
        })


func _collect_post_exit_probe_series(generation: int) -> void:
    var frame_offsets: Array[int] = [1, 12, 60]
    var previous_offset: int = 0

    for probe_index: int in range(frame_offsets.size()):
        var frame_offset: int = frame_offsets[probe_index]
        for _frame: int in range(frame_offset - previous_offset):
            await get_tree().process_frame
        previous_offset = frame_offset

        if generation != _post_exit_probe_generation or _fullscreen_active:
            return

        _telemetry_event("render_probe_post_exit", {
            "probe_index": probe_index,
            "frame_offset": frame_offset,
        })

    # presentation_exit_complete already publishes once. Publish a second time
    # after the delayed probes so GitHub also contains the final settled state.
    if generation == _post_exit_probe_generation and not _fullscreen_active:
        _publish_telemetry_to_github("post_exit_diagnostics")


func _event_needs_frame_probe(event_name: String) -> bool:
    return event_name == "presentation_enter_request" \
        or event_name == "presentation_enter_complete" \
        or event_name == "presentation_exit_request" \
        or event_name == "presentation_exit_preview_released" \
        or event_name == "presentation_exit_native_restored" \
        or event_name == "presentation_exit_complete" \
        or event_name == "input_key" \
        or event_name.begins_with("render_probe_")


func _runtime_telemetry_snapshot() -> Dictionary:
    return {
        "diagnostic_version": DIAGNOSTIC_VERSION,
        "process_frame": Engine.get_process_frames(),
        "physics_frame": Engine.get_physics_frames(),
        "frames_drawn": Engine.get_frames_drawn(),
        "fps": Engine.get_frames_per_second(),
        "git_head": _get_diagnostic_git_head(),
    }


func _get_diagnostic_git_head() -> String:
    if not _diagnostic_git_head.is_empty():
        return _diagnostic_git_head
    if DisplayServer.get_name() == "headless":
        return "headless"

    var output: Array = []
    var repo_root: String = ProjectSettings.globalize_path("res://")
    var exit_code: int = OS.execute(
        "git",
        PackedStringArray(["-C", repo_root, "rev-parse", "--short=12", "HEAD"]),
        output,
        true,
        false
    )

    if exit_code == 0 and not output.is_empty():
        var candidate: String = str(output[0]).strip_edges()
        if candidate.is_valid_hex_number() and candidate.length() <= 40:
            _diagnostic_git_head = candidate.to_lower()

    if _diagnostic_git_head.is_empty():
        _diagnostic_git_head = "unknown"
    return _diagnostic_git_head


func _window_telemetry_snapshot() -> Dictionary:
    var snapshot: Dictionary = super._window_telemetry_snapshot()
    var root_window: Window = get_window()
    var screen_index: int = root_window.current_screen
    var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_index)

    snapshot["display_position"] = _vec2i_array(DisplayServer.window_get_position())
    snapshot["display_size"] = _vec2i_array(DisplayServer.window_get_size())
    snapshot["root_position"] = _vec2i_array(root_window.position)
    snapshot["root_size"] = _vec2i_array(root_window.size)
    snapshot["screen_position"] = _vec2i_array(DisplayServer.screen_get_position(screen_index))
    snapshot["screen_usable_position"] = _vec2i_array(usable_rect.position)
    snapshot["screen_usable_size"] = _vec2i_array(usable_rect.size)
    snapshot["min_size"] = _vec2i_array(root_window.min_size)
    snapshot["borderless"] = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
    snapshot["resize_disabled"] = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED)
    snapshot["always_on_top"] = root_window.always_on_top
    snapshot["unresizable"] = root_window.unresizable
    snapshot["content_scale_factor"] = root_window.content_scale_factor
    return snapshot


func _control_telemetry_snapshot(control: Control) -> Dictionary:
    var snapshot: Dictionary = super._control_telemetry_snapshot(control)
    snapshot["visible_in_tree"] = control.is_visible_in_tree()
    snapshot["minimum_size"] = _vec2_array(control.get_combined_minimum_size())
    snapshot["custom_minimum_size"] = _vec2_array(control.custom_minimum_size)
    snapshot["anchors"] = [
        control.anchor_left,
        control.anchor_top,
        control.anchor_right,
        control.anchor_bottom,
    ]
    snapshot["offsets"] = [
        control.offset_left,
        control.offset_top,
        control.offset_right,
        control.offset_bottom,
    ]
    snapshot["size_flags_horizontal"] = control.size_flags_horizontal
    snapshot["size_flags_vertical"] = control.size_flags_vertical
    return snapshot


func _render_telemetry_snapshot() -> Dictionary:
    var source_texture: Texture2D = sketch_viewport.get_texture()
    var assigned_texture: Texture2D = fullscreen_texture.texture
    var active_valid: bool = is_instance_valid(_active_sketch)
    var active_visible: bool = false
    var active_in_tree: bool = false
    var active_can_process: bool = false
    var active_process_mode: int = -1

    if active_valid:
        active_in_tree = _active_sketch.is_inside_tree()
        active_can_process = _active_sketch.can_process()
        active_process_mode = int(_active_sketch.process_mode)
        if _active_sketch is CanvasItem:
            active_visible = (_active_sketch as CanvasItem).is_visible_in_tree()

    var fullscreen_background: ColorRect = fullscreen_overlay.get_node_or_null("FullscreenBackground") as ColorRect
    var background_visible: bool = false
    var background_visible_in_tree: bool = false
    var background_color: Array[float] = [0.0, 0.0, 0.0, 0.0]
    if fullscreen_background != null:
        background_visible = fullscreen_background.visible
        background_visible_in_tree = fullscreen_background.is_visible_in_tree()
        background_color = [
            fullscreen_background.color.r,
            fullscreen_background.color.g,
            fullscreen_background.color.b,
            fullscreen_background.color.a,
        ]

    var assigned_size: Vector2 = Vector2.ZERO
    if assigned_texture != null:
        assigned_size = assigned_texture.get_size()

    return {
        "suspend_preview_resolution_sync": _suspend_preview_resolution_sync,
        "last_preview_size": _vec2i_array(_last_preview_size),
        "viewport_size": _vec2i_array(sketch_viewport.size),
        "viewport_texture_size": _vec2_array(source_texture.get_size()),
        "viewport_update_mode": int(sketch_viewport.render_target_update_mode),
        "viewport_clear_mode": int(sketch_viewport.render_target_clear_mode),
        "viewport_disable_3d": sketch_viewport.disable_3d,
        "viewport_handle_input_locally": sketch_viewport.handle_input_locally,
        "viewport_child_count": sketch_viewport.get_child_count(),
        "preview_container_size": _vec2_array(sketch_viewport_container.size),
        "preview_container_minimum_size": _vec2_array(sketch_viewport_container.get_combined_minimum_size()),
        "active_sketch_valid": active_valid,
        "active_sketch_in_tree": active_in_tree,
        "active_sketch_can_process": active_can_process,
        "active_sketch_process_mode": active_process_mode,
        "active_sketch_visible_in_tree": active_visible,
        "fullscreen_overlay_visible": fullscreen_overlay.visible,
        "fullscreen_overlay_visible_in_tree": fullscreen_overlay.is_visible_in_tree(),
        "fullscreen_background_visible": background_visible,
        "fullscreen_background_visible_in_tree": background_visible_in_tree,
        "fullscreen_background_color": background_color,
        "fullscreen_texture_visible": fullscreen_texture.visible,
        "fullscreen_texture_visible_in_tree": fullscreen_texture.is_visible_in_tree(),
        "fullscreen_texture_has_texture": assigned_texture != null,
        "fullscreen_texture_matches_source": assigned_texture == source_texture,
        "fullscreen_texture_size": _vec2_array(assigned_size),
        "fullscreen_texture_expand_mode": int(fullscreen_texture.expand_mode),
        "fullscreen_texture_stretch_mode": int(fullscreen_texture.stretch_mode),
        "fullscreen_texture_modulate": [
            fullscreen_texture.modulate.r,
            fullscreen_texture.modulate.g,
            fullscreen_texture.modulate.b,
            fullscreen_texture.modulate.a,
        ],
        "fullscreen_texture_self_modulate": [
            fullscreen_texture.self_modulate.r,
            fullscreen_texture.self_modulate.g,
            fullscreen_texture.self_modulate.b,
            fullscreen_texture.self_modulate.a,
        ],
    }


func _frame_probe_snapshot() -> Dictionary:
    var source_texture: Texture2D = sketch_viewport.get_texture()
    var assigned_texture: Texture2D = fullscreen_texture.texture
    var composite_texture: Texture2D = get_viewport().get_texture()

    return {
        "source_frame": _texture_frame_metrics(source_texture),
        "assigned_frame": _texture_frame_metrics(assigned_texture),
        "composite_frame": _texture_frame_metrics(composite_texture),
    }


func _texture_frame_metrics(texture: Texture2D) -> Dictionary:
    if texture == null:
        return {
            "image_available": false,
        }

    var image: Image = texture.get_image()
    if image == null or image.is_empty():
        return {
            "image_available": false,
            "texture_size": _vec2_array(texture.get_size()),
        }

    var width: int = image.get_width()
    var height: int = image.get_height()
    if width <= 0 or height <= 0:
        return {
            "image_available": false,
            "width": width,
            "height": height,
        }

    var columns: int = mini(FRAME_SAMPLE_COLUMNS, width)
    var rows: int = mini(FRAME_SAMPLE_ROWS, height)
    var sample_count: int = columns * rows
    var sum_r: float = 0.0
    var sum_g: float = 0.0
    var sum_b: float = 0.0
    var sum_luma: float = 0.0
    var sum_luma_sq: float = 0.0
    var min_luma: float = 999.0
    var max_luma: float = -999.0
    var non_black_count: int = 0
    var alpha_count: int = 0
    var fingerprint: int = 17

    for row: int in range(rows):
        var y: int = 0
        if rows > 1:
            y = int(round(float(row) * float(height - 1) / float(rows - 1)))

        for column: int in range(columns):
            var x: int = 0
            if columns > 1:
                x = int(round(float(column) * float(width - 1) / float(columns - 1)))

            var color: Color = image.get_pixel(x, y)
            var r: float = clampf(color.r, 0.0, 1.0)
            var g: float = clampf(color.g, 0.0, 1.0)
            var b: float = clampf(color.b, 0.0, 1.0)
            var a: float = clampf(color.a, 0.0, 1.0)
            var luma: float = r * 0.2126 + g * 0.7152 + b * 0.0722

            sum_r += r
            sum_g += g
            sum_b += b
            sum_luma += luma
            sum_luma_sq += luma * luma
            min_luma = minf(min_luma, luma)
            max_luma = maxf(max_luma, luma)

            if maxf(r, maxf(g, b)) > 0.02:
                non_black_count += 1
            if a > 0.01:
                alpha_count += 1

            var qr: int = int(round(r * 255.0))
            var qg: int = int(round(g * 255.0))
            var qb: int = int(round(b * 255.0))
            var qa: int = int(round(a * 255.0))
            fingerprint = int((fingerprint * 131 + qr * 3 + qg * 5 + qb * 7 + qa * 11) % 2147483647)

    var count_f: float = float(maxi(1, sample_count))
    var avg_luma: float = sum_luma / count_f
    var variance: float = maxf(0.0, sum_luma_sq / count_f - avg_luma * avg_luma)
    var luma_range: float = max_luma - min_luma

    return {
        "image_available": true,
        "width": width,
        "height": height,
        "format": int(image.get_format()),
        "sample_count": sample_count,
        "avg_rgb": [sum_r / count_f, sum_g / count_f, sum_b / count_f],
        "avg_luma": avg_luma,
        "min_luma": min_luma,
        "max_luma": max_luma,
        "luma_range": luma_range,
        "luma_variance": variance,
        "non_black_ratio": float(non_black_count) / count_f,
        "alpha_ratio": float(alpha_count) / count_f,
        "fingerprint": fingerprint,
        "likely_black": max_luma < 0.01,
        "likely_flat": luma_range < 0.002 and variance < 0.000001,
    }


func _diagnostic_state_signature() -> String:
    return JSON.stringify({
        "mode": DisplayServer.window_get_mode(),
        "display_position": _vec2i_array(DisplayServer.window_get_position()),
        "display_size": _vec2i_array(DisplayServer.window_get_size()),
        "root_position": _vec2i_array(get_window().position),
        "root_size": _vec2i_array(get_window().size),
        "fullscreen": _fullscreen_active,
        "transition": _presentation_transition,
        "restoring": _restoring_window,
        "margin_position": _vec2_array(margin.position),
        "margin_size": _vec2_array(margin.size),
        "project_position": _vec2_array(project_view.position),
        "project_size": _vec2_array(project_view.size),
        "preview_position": _vec2_array(sketch_viewport_container.position),
        "preview_size": _vec2_array(sketch_viewport_container.size),
        "viewport_size": _vec2i_array(sketch_viewport.size),
        "overlay_visible": fullscreen_overlay.visible,
        "overlay_size": _vec2_array(fullscreen_overlay.size),
    })
