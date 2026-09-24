extends "res://app/main/main_runtime_hardened.gd"

# Seamless presentation layer.
#
# The diagnostic session from 3382628 showed that the remaining visible
# "extra step" on Esc was not a layout failure: the root window went through
# EXCLUSIVE_FULLSCREEN -> FULLSCREEN -> WINDOWED while the render overlay was
# still visible. That native bridge is robust, but it is visibly dirty.
#
# For the common WINDOWED -> presentation -> WINDOWED path, keep the root HWND
# in WINDOWED mode for the whole presentation. A tiny overscan makes the
# borderless window cover the physical monitor without its client rect matching
# the monitor exactly, which avoids Windows/Godot classifying it as exclusive
# fullscreen. Exit can then restore the saved rect directly in a few frames,
# with the render overlay hiding the reflow until the workstation is ready.

const SEAMLESS_DIAGNOSTIC_REVISION: int = 7
const PRESENTATION_OVERSCAN_PX: Vector2i = Vector2i(2, 2)
const SEAMLESS_RECT_ATTEMPTS: int = 4


func _finish_enter_render_fullscreen() -> void:
    var root_window: Window = get_window()
    var screen_position: Vector2i = DisplayServer.screen_get_position(_presentation_screen)
    var screen_size: Vector2i = DisplayServer.screen_get_size(_presentation_screen)
    var target_position: Vector2i = screen_position
    var target_size: Vector2i = screen_size + PRESENTATION_OVERSCAN_PX

    await get_tree().process_frame

    var matched: bool = false
    for attempt: int in range(SEAMLESS_RECT_ATTEMPTS):
        if not _fullscreen_active:
            _presentation_transition = false
            return

        if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            await get_tree().process_frame

        root_window.unresizable = false
        DisplayServer.window_set_position(target_position)
        DisplayServer.window_set_size(target_size)
        await get_tree().process_frame

        var mode_ok: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
        var rect_ok: bool = _window_rect_matches(
            DisplayServer.window_get_position(),
            DisplayServer.window_get_size(),
            target_position,
            target_size
        )
        matched = mode_ok and rect_ok

        _telemetry_event("presentation_enter_apply", {
            "diagnostic_revision": SEAMLESS_DIAGNOSTIC_REVISION,
            "attempt": attempt + 1,
            "target_mode": "windowed",
            "target_position": _vec2i_array(target_position),
            "target_size": _vec2i_array(target_size),
            "mode_ok": mode_ok,
            "rect_ok": rect_ok,
            "matched": matched,
            "overscan_x": PRESENTATION_OVERSCAN_PX.x,
            "overscan_y": PRESENTATION_OVERSCAN_PX.y,
        })

        if matched:
            break

    _force_root_full_rect()
    fullscreen_overlay.visible = true
    fullscreen_overlay.grab_focus()
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)
    _ensure_realtime_viewport_updates()
    root_window.grab_focus()
    _presentation_transition = false

    _telemetry_event("presentation_enter_complete", {
        "diagnostic_revision": SEAMLESS_DIAGNOSTIC_REVISION,
        "matched": matched,
        "layout": _layout_telemetry_snapshot(),
    })


func _finish_exit_render_fullscreen() -> void:
    # The seamless path is deliberately narrow: it is used only when the app
    # entered presentation from a normal window and Windows kept the overscanned
    # presentation window in WINDOWED mode. All other cases keep the hardened
    # fallback below this layer.
    if _presentation_previous_mode != DisplayServer.WINDOW_MODE_WINDOWED \
    or DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
        await super._finish_exit_render_fullscreen()
        return

    var root_window: Window = get_window()
    var restore_position: Vector2i = _presentation_previous_position
    var restore_size: Vector2i = _presentation_previous_size
    if _presentation_previous_has_restore_rect:
        restore_position = _presentation_previous_restore_position
        restore_size = _presentation_previous_restore_size

    # Keep the render cover visible while releasing the SubViewport's fullscreen
    # minimum-size pressure. One frame is sufficient because no native mode
    # transition is needed on this path.
    margin.visible = false
    fullscreen_overlay.visible = true
    root_window.unresizable = false
    root_window.always_on_top = _presentation_previous_always_on_top

    _suspend_preview_resolution_sync = true
    sketch_viewport.size = PREVIEW_LAYOUT_RELEASE_SIZE
    _last_preview_size = PREVIEW_LAYOUT_RELEASE_SIZE
    _force_workstation_layout()
    await get_tree().process_frame

    _telemetry_event("presentation_exit_preview_released", {
        "diagnostic_revision": SEAMLESS_DIAGNOSTIC_REVISION,
        "layout": _layout_telemetry_snapshot(),
    })

    var matched: bool = false
    for attempt: int in range(SEAMLESS_RECT_ATTEMPTS):
        DisplayServer.window_set_position(restore_position)
        DisplayServer.window_set_size(restore_size)
        await get_tree().process_frame

        var mode_ok: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
        var rect_ok: bool = _window_rect_matches(
            DisplayServer.window_get_position(),
            DisplayServer.window_get_size(),
            restore_position,
            restore_size
        )
        matched = mode_ok and rect_ok

        _telemetry_event("presentation_exit_apply", {
            "diagnostic_revision": SEAMLESS_DIAGNOSTIC_REVISION,
            "attempt": attempt + 1,
            "target_mode": "windowed",
            "target_position": _vec2i_array(restore_position),
            "target_size": _vec2i_array(restore_size),
            "mode_ok": mode_ok,
            "rect_ok": rect_ok,
            "matched": matched,
        })

        if matched:
            break

    if not matched:
        # Keep the known-good robust recovery available if a driver/Windows
        # update ever stops accepting the direct overscan restore.
        await super._finish_exit_render_fullscreen()
        return

    _restore_position = _presentation_previous_restore_position
    _restore_size = _presentation_previous_restore_size
    _has_restore_rect = _presentation_previous_has_restore_rect

    # Rebuild the workstation behind the still-visible cover, then reveal it on
    # the very next settled frame. This removes the previous 10+ frame visible
    # presentation-in-a-window stage.
    _force_root_full_rect()
    margin.visible = true
    top_bar.visible = true
    rail.visible = true
    status_bar.visible = true
    gallery_view.visible = false
    project_view.visible = true
    page_spacer.visible = false
    _force_workstation_layout()
    await get_tree().process_frame

    _fullscreen_active = false
    _suspend_preview_resolution_sync = false
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)
    _force_workstation_layout()
    await get_tree().process_frame

    fullscreen_overlay.visible = false
    root_window.unresizable = _presentation_previous_unresizable
    _sync_window_controls()
    root_window.grab_focus()

    _restoring_window = false
    _presentation_transition = false

    _telemetry_event("presentation_exit_complete", {
        "diagnostic_revision": SEAMLESS_DIAGNOSTIC_REVISION,
        "matched": true,
        "layout": _layout_telemetry_snapshot(),
    })
