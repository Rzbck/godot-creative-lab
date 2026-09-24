extends "res://app/main/main_runtime_publish.gd"

# Windows can keep a borderless monitor-sized root window in
# EXCLUSIVE_FULLSCREEN even after a WINDOWED request. In addition, the
# SubViewportContainer uses the SubViewport size as layout pressure while
# stretch is disabled. A fullscreen-sized SubViewport therefore prevents the
# workstation shell from shrinking back to its pre-presentation geometry.
#
# This layer treats exit as an ordered state transition:
#   1. release the fullscreen SubViewport minimum size,
#   2. leave fullscreen mode,
#   3. restore the native window rect,
#   4. rebuild the workstation layout,
#   5. resize the SubViewport to the rebuilt preview,
#   6. reveal the workstation only after all of the above has settled.

const WINDOW_MODE_TRANSITION_ATTEMPTS: int = 24
const PREVIEW_LAYOUT_RELEASE_SIZE: Vector2i = Vector2i(640, 360)

var _suspend_preview_resolution_sync: bool = false


func _sync_preview_resolution(force: bool = false) -> void:
    if _suspend_preview_resolution_sync:
        return
    super._sync_preview_resolution(force)


func _finish_exit_render_fullscreen() -> void:
    var root_window: Window = get_window()

    margin.visible = false
    fullscreen_overlay.visible = true
    root_window.unresizable = false
    root_window.always_on_top = _presentation_previous_always_on_top

    # The telemetry proved that the fullscreen 1920x1080 SubViewport was keeping
    # ProjectView wider/taller than the restored 1280x720 root. Stop the regular
    # preview synchronizer and release that minimum-size pressure before touching
    # the native window state.
    _suspend_preview_resolution_sync = true
    sketch_viewport.size = PREVIEW_LAYOUT_RELEASE_SIZE
    _last_preview_size = PREVIEW_LAYOUT_RELEASE_SIZE
    _force_workstation_layout()
    await get_tree().process_frame

    _telemetry_event("presentation_exit_preview_released", {
        "layout": _layout_telemetry_snapshot(),
    })

    var restore_position: Vector2i = _presentation_previous_position
    var restore_size: Vector2i = _presentation_previous_size
    if _presentation_previous_has_restore_rect:
        restore_position = _presentation_previous_restore_position
        restore_size = _presentation_previous_restore_size

    var windowed_ok: bool = await _force_windowed_rect(
        restore_position,
        restore_size,
        "presentation_exit_apply"
    )

    if not windowed_ok:
        _telemetry_event("presentation_exit_mode_release_failed", {
            "target_mode": "windowed",
            "target_position": _vec2i_array(restore_position),
            "target_size": _vec2i_array(restore_size),
        })

    _restore_position = _presentation_previous_restore_position
    _restore_size = _presentation_previous_restore_size
    _has_restore_rect = _presentation_previous_has_restore_rect

    # Rebuild the UI only after the SubViewport no longer imposes fullscreen
    # dimensions and the root window has been released from fullscreen mode.
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
    await get_tree().process_frame
    await get_tree().process_frame

    # A visible Control tree can cause Windows to perform one final client-area
    # adjustment. Reassert the original rect after the workstation has settled.
    if _presentation_previous_mode == DisplayServer.WINDOW_MODE_WINDOWED:
        windowed_ok = await _force_windowed_rect(
            restore_position,
            restore_size,
            "presentation_exit_post_layout_apply"
        ) and windowed_ok
    elif _presentation_previous_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
        for attempt: int in range(WINDOW_MODE_TRANSITION_ATTEMPTS):
            await get_tree().process_frame
            var maximized_ok: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED
            _telemetry_event("presentation_exit_restore_mode_apply", {
                "attempt": attempt + 1,
                "target_mode": "maximized",
                "matched": maximized_ok,
            })
            if maximized_ok:
                break

    _telemetry_event("presentation_exit_native_restored", {
        "matched": windowed_ok,
        "layout": _layout_telemetry_snapshot(),
    })

    # From this point the normal preview may follow its actual container again.
    _fullscreen_active = false
    _suspend_preview_resolution_sync = false
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)
    _force_workstation_layout()

    await get_tree().process_frame
    await get_tree().process_frame

    # The SubViewport now matches the rebuilt preview instead of driving it.
    # Reassert a windowed rect once more so the final state is byte-for-byte the
    # geometry saved before presentation.
    if _presentation_previous_mode == DisplayServer.WINDOW_MODE_WINDOWED:
        windowed_ok = await _force_windowed_rect(
            restore_position,
            restore_size,
            "presentation_exit_final_rect_apply"
        ) and windowed_ok

    fullscreen_overlay.visible = false
    root_window.unresizable = _presentation_previous_unresizable
    _sync_window_controls()
    root_window.grab_focus()

    await get_tree().process_frame
    await get_tree().process_frame

    _restoring_window = false
    _presentation_transition = false
    _telemetry_event("presentation_exit_complete", {
        "matched": windowed_ok,
        "layout": _layout_telemetry_snapshot(),
    })


func _apply_restore_rect() -> void:
    var target_position: Vector2i = _restore_position
    var target_size: Vector2i = _restore_size
    var has_target: bool = _has_restore_rect

    var restore_ok: bool = true
    if has_target:
        restore_ok = await _force_windowed_rect(
            target_position,
            target_size,
            "window_restore_apply"
        )
    else:
        restore_ok = await _release_to_windowed("window_restore_apply")

    if has_target:
        _restore_position = target_position
        _restore_size = target_size
        _has_restore_rect = true

    _force_root_full_rect()
    _force_workstation_layout()
    _sync_window_controls()
    await get_tree().process_frame
    await get_tree().process_frame

    # Containers may have changed minimum sizes during maximize. Give the native
    # rect one final deterministic settle pass after the UI has reflowed.
    if has_target:
        restore_ok = await _settle_windowed_rect(
            target_position,
            target_size,
            "window_restore_post_layout_apply"
        ) and restore_ok

    _restoring_window = false
    _telemetry_event("window_restore_complete", {
        "matched": restore_ok,
        "layout": _layout_telemetry_snapshot(),
    })


func _force_windowed_rect(
    target_position: Vector2i,
    target_size: Vector2i,
    telemetry_event_name: String
) -> bool:
    var mode_ok: bool = await _release_to_windowed(telemetry_event_name)
    if not mode_ok:
        return false

    return await _settle_windowed_rect(
        target_position,
        target_size,
        telemetry_event_name
    )


func _release_to_windowed(telemetry_event_name: String) -> bool:
    var root_window: Window = get_window()
    root_window.unresizable = false

    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

    var current_mode: int = DisplayServer.window_get_mode()

    # On this Windows setup, direct EXCLUSIVE_FULLSCREEN -> WINDOWED requests
    # were ignored for many frames. MAXIMIZED reliably breaks the fullscreen
    # state first, while the render overlay hides the transition.
    if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
    or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

        for attempt: int in range(WINDOW_MODE_TRANSITION_ATTEMPTS):
            await get_tree().process_frame
            current_mode = DisplayServer.window_get_mode()
            var released: bool = current_mode != DisplayServer.WINDOW_MODE_FULLSCREEN \
                and current_mode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

            _telemetry_event("window_mode_release_step", {
                "attempt": attempt + 1,
                "matched": released,
            })

            if released:
                break

    if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
        return true

    for attempt: int in range(WINDOW_MODE_TRANSITION_ATTEMPTS):
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        await get_tree().process_frame

        var mode_ok: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
        _telemetry_event(telemetry_event_name, {
            "attempt": attempt + 1,
            "target_mode": "windowed",
            "mode_ok": mode_ok,
            "rect_ok": false,
            "matched": false,
        })

        if mode_ok:
            return true

    return false


func _settle_windowed_rect(
    target_position: Vector2i,
    target_size: Vector2i,
    telemetry_event_name: String
) -> bool:
    var root_window: Window = get_window()

    for attempt: int in range(WINDOW_MODE_TRANSITION_ATTEMPTS):
        if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
            if not await _release_to_windowed(telemetry_event_name):
                return false

        root_window.unresizable = false
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
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
        var matched: bool = mode_ok and rect_ok

        _telemetry_event(telemetry_event_name, {
            "attempt": attempt + 1,
            "target_mode": "windowed",
            "target_position": _vec2i_array(target_position),
            "target_size": _vec2i_array(target_size),
            "mode_ok": mode_ok,
            "rect_ok": rect_ok,
            "matched": matched,
        })

        if matched:
            # Require two stable frames. The previous implementation matched for
            # one frame and Windows snapped back immediately afterwards.
            await get_tree().process_frame
            await get_tree().process_frame

            var stable: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED \
                and _window_rect_matches(
                    DisplayServer.window_get_position(),
                    DisplayServer.window_get_size(),
                    target_position,
                    target_size
                )
            if stable:
                return true

    return false
