extends "res://app/main/main_runtime_workstation.gd"

# Root-window presentation layer.
#
# The native secondary output window is intentionally not used for fullscreen
# presentation on Windows. Runtime telemetry proved that the source SubViewport
# contains a valid moving frame while the secondary native Window is promoted by
# Windows/Godot to mode 4 (exclusive fullscreen) and can present as a flat gray
# swapchain. The already-validated root-window overlay does not have that cross-
# window render-target problem.
#
# Presentation therefore moves the existing borderless root window to the
# selected display, covers the workstation with the render overlay, and restores
# the exact previous workstation state on Esc. A tiny overscan prevents Windows
# from classifying the borderless client as exclusive fullscreen.

const ROOT_PRESENTATION_REVISION: int = 10
const ROOT_PRESENTATION_OVERSCAN: Vector2i = Vector2i(2, 2)
const ROOT_PRESENTATION_ATTEMPTS: int = 8
const ROOT_PRESENTATION_RECT_TOLERANCE: int = 3

var _root_presentation_generation: int = 0


func _enter_render_fullscreen() -> void:
    if not is_instance_valid(_active_sketch) or _fullscreen_active or _presentation_transition:
        return

    var root_window: Window = get_window()
    var current_mode: int = DisplayServer.window_get_mode()

    if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
        _remember_windowed_rect()

    _presentation_previous_mode = current_mode
    _presentation_previous_position = DisplayServer.window_get_position()
    _presentation_previous_size = DisplayServer.window_get_size()
    _presentation_previous_always_on_top = root_window.always_on_top
    _presentation_previous_unresizable = root_window.unresizable
    _presentation_previous_restore_position = _restore_position
    _presentation_previous_restore_size = _restore_size
    _presentation_previous_has_restore_rect = _has_restore_rect
    _presentation_screen = _resolve_output_screen()

    _root_presentation_generation += 1
    var generation: int = _root_presentation_generation

    _presentation_transition = true
    _restoring_window = true
    _fullscreen_active = true

    var screen_position: Vector2i = DisplayServer.screen_get_position(_presentation_screen)
    var screen_size: Vector2i = DisplayServer.screen_get_size(_presentation_screen)
    var target_position: Vector2i = screen_position
    var target_size: Vector2i = screen_size + ROOT_PRESENTATION_OVERSCAN

    # The secondary native output remains hidden. Render the already-running
    # SubViewport through the root overlay that is known to work on this GPU.
    if is_instance_valid(_presentation_output):
        _presentation_output.hide()

    fullscreen_texture.texture = sketch_viewport.get_texture()
    fullscreen_overlay.visible = true
    fullscreen_overlay.grab_focus()

    root_window.unresizable = false
    root_window.always_on_top = true
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

    _telemetry_event("root_presentation_enter_request", {
        "root_presentation_revision": ROOT_PRESENTATION_REVISION,
        "selected_screen": _presentation_screen,
        "screen_preference": _output_screen_preference,
        "target_position": _vec2i_array(target_position),
        "target_size": _vec2i_array(target_size),
        "previous_mode": current_mode,
        "previous_position": _vec2i_array(_presentation_previous_position),
        "previous_size": _vec2i_array(_presentation_previous_size),
    })

    call_deferred(
        "_finish_root_presentation_enter",
        generation,
        target_position,
        target_size
    )


func _finish_root_presentation_enter(
    generation: int,
    target_position: Vector2i,
    target_size: Vector2i
) -> void:
    var root_window: Window = get_window()

    # Release maximize/fullscreen state before applying a monitor rectangle.
    if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
        await _release_to_windowed("root_presentation_release_to_windowed")

    await get_tree().process_frame

    var matched: bool = false
    for attempt: int in range(ROOT_PRESENTATION_ATTEMPTS):
        if generation != _root_presentation_generation or not _fullscreen_active:
            return

        root_window.unresizable = false
        DisplayServer.window_set_position(target_position)
        DisplayServer.window_set_size(target_size)
        await get_tree().process_frame

        var actual_position: Vector2i = DisplayServer.window_get_position()
        var actual_size: Vector2i = DisplayServer.window_get_size()
        var mode_ok: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
        var rect_ok: bool = _root_rect_matches(
            actual_position,
            actual_size,
            target_position,
            target_size
        )
        matched = mode_ok and rect_ok

        _telemetry_event("root_presentation_enter_apply", {
            "root_presentation_revision": ROOT_PRESENTATION_REVISION,
            "attempt": attempt + 1,
            "mode_ok": mode_ok,
            "rect_ok": rect_ok,
            "matched": matched,
            "actual_position": _vec2i_array(actual_position),
            "actual_size": _vec2i_array(actual_size),
            "target_position": _vec2i_array(target_position),
            "target_size": _vec2i_array(target_size),
        })

        if matched:
            break

    fullscreen_overlay.visible = true
    fullscreen_overlay.grab_focus()
    _last_preview_size = Vector2i.ZERO
    _ensure_realtime_viewport_updates()
    root_window.grab_focus()
    _presentation_transition = false

    _telemetry_event("presentation_enter_complete", {
        "root_presentation_revision": ROOT_PRESENTATION_REVISION,
        "presentation_backend": "root_overlay",
        "selected_screen": _presentation_screen,
        "matched": matched,
        "root_mode": DisplayServer.window_get_mode(),
        "root_position": _vec2i_array(DisplayServer.window_get_position()),
        "root_size": _vec2i_array(DisplayServer.window_get_size()),
    })


func _exit_render_fullscreen() -> void:
    if not _fullscreen_active or _presentation_transition:
        return

    _root_presentation_generation += 1
    var generation: int = _root_presentation_generation
    _presentation_transition = true

    _telemetry_event("presentation_exit_request", {
        "root_presentation_revision": ROOT_PRESENTATION_REVISION,
        "presentation_backend": "root_overlay",
        "restore_mode": _presentation_previous_mode,
        "restore_position": _vec2i_array(_presentation_previous_position),
        "restore_size": _vec2i_array(_presentation_previous_size),
    })

    call_deferred("_finish_root_presentation_exit", generation)


func _finish_root_presentation_exit(generation: int) -> void:
    var root_window: Window = get_window()

    # Keep the render cover visible until the workstation has fully settled.
    fullscreen_overlay.visible = true
    root_window.unresizable = false
    root_window.always_on_top = _presentation_previous_always_on_top

    if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
        await _release_to_windowed("root_presentation_exit_release")

    if generation != _root_presentation_generation or not _fullscreen_active:
        return

    var restore_position: Vector2i = _presentation_previous_position
    var restore_size: Vector2i = _presentation_previous_size

    # For a previously maximized/fullscreen workstation, use its saved normal
    # rect only to put Windows back on the original monitor before restoring the
    # original native mode.
    if _presentation_previous_mode != DisplayServer.WINDOW_MODE_WINDOWED \
    and _presentation_previous_has_restore_rect:
        restore_position = _presentation_previous_restore_position
        restore_size = _presentation_previous_restore_size

    var rect_matched: bool = false
    for attempt: int in range(ROOT_PRESENTATION_ATTEMPTS):
        DisplayServer.window_set_size(restore_size)
        DisplayServer.window_set_position(restore_position)
        await get_tree().process_frame

        var actual_position: Vector2i = DisplayServer.window_get_position()
        var actual_size: Vector2i = DisplayServer.window_get_size()
        rect_matched = _root_rect_matches(
            actual_position,
            actual_size,
            restore_position,
            restore_size
        )

        _telemetry_event("root_presentation_exit_rect_apply", {
            "root_presentation_revision": ROOT_PRESENTATION_REVISION,
            "attempt": attempt + 1,
            "matched": rect_matched,
            "actual_position": _vec2i_array(actual_position),
            "actual_size": _vec2i_array(actual_size),
            "target_position": _vec2i_array(restore_position),
            "target_size": _vec2i_array(restore_size),
        })

        if rect_matched:
            break

    if _presentation_previous_mode != DisplayServer.WINDOW_MODE_WINDOWED:
        DisplayServer.window_set_mode(_presentation_previous_mode)
        for attempt: int in range(ROOT_PRESENTATION_ATTEMPTS):
            await get_tree().process_frame
            var mode_ok: bool = DisplayServer.window_get_mode() == _presentation_previous_mode
            _telemetry_event("root_presentation_exit_mode_apply", {
                "root_presentation_revision": ROOT_PRESENTATION_REVISION,
                "attempt": attempt + 1,
                "target_mode": _presentation_previous_mode,
                "actual_mode": DisplayServer.window_get_mode(),
                "matched": mode_ok,
            })
            if mode_ok:
                break
            DisplayServer.window_set_mode(_presentation_previous_mode)

    _restore_position = _presentation_previous_restore_position
    _restore_size = _presentation_previous_restore_size
    _has_restore_rect = _presentation_previous_has_restore_rect

    # Give containers two frames to settle behind the cover before revealing.
    await get_tree().process_frame
    await get_tree().process_frame

    _fullscreen_active = false
    fullscreen_overlay.visible = false
    root_window.unresizable = _presentation_previous_unresizable
    root_window.always_on_top = _presentation_previous_always_on_top
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)
    _sync_window_controls()
    root_window.grab_focus()

    await get_tree().process_frame
    _restoring_window = false
    _presentation_transition = false

    _telemetry_event("presentation_exit_complete", {
        "root_presentation_revision": ROOT_PRESENTATION_REVISION,
        "presentation_backend": "root_overlay",
        "rect_matched": rect_matched,
        "restored_mode": DisplayServer.window_get_mode(),
        "restored_position": _vec2i_array(DisplayServer.window_get_position()),
        "restored_size": _vec2i_array(DisplayServer.window_get_size()),
    })


func _root_rect_matches(
    actual_position: Vector2i,
    actual_size: Vector2i,
    target_position: Vector2i,
    target_size: Vector2i
) -> bool:
    return absi(actual_position.x - target_position.x) <= ROOT_PRESENTATION_RECT_TOLERANCE \
        and absi(actual_position.y - target_position.y) <= ROOT_PRESENTATION_RECT_TOLERANCE \
        and absi(actual_size.x - target_size.x) <= ROOT_PRESENTATION_RECT_TOLERANCE \
        and absi(actual_size.y - target_size.y) <= ROOT_PRESENTATION_RECT_TOLERANCE


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched: Dictionary = data.duplicate(true)
    enriched["root_presentation_revision"] = ROOT_PRESENTATION_REVISION
    enriched["presentation_backend"] = "root_overlay"
    super._telemetry_event(event_name, enriched)
