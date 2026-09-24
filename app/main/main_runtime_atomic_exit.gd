extends "res://app/main/main_runtime_root_presentation.gd"

# Atomic presentation-exit layer.
#
# Online telemetry proved the remaining visual artifact was self-inflicted:
# the root window was restored to its workstation rectangle while the fullscreen
# overlay was still visible for one or more rendered frames. That visibly made
# the presentation shrink into the application before the UI was revealed.
#
# This layer commits geometry + overlay removal in the same main-thread turn.
# There is no await between the Esc request and dropping the presentation cover.
# Any Windows geometry correction happens afterwards with the normal UI already
# visible, so the presentation can never be rendered inside the restored window.

const ATOMIC_EXIT_REVISION: int = 11
const ATOMIC_EXIT_ATTEMPTS: int = 8
const ATOMIC_EXIT_RECT_TOLERANCE: int = 6


func _exit_render_fullscreen() -> void:
    if not _fullscreen_active or _presentation_transition:
        return

    _root_presentation_generation += 1
    var generation: int = _root_presentation_generation
    _presentation_transition = true

    _telemetry_event("presentation_exit_request", {
        "atomic_exit_revision": ATOMIC_EXIT_REVISION,
        "exit_strategy": "atomic_overlay_drop",
        "restore_mode": _presentation_previous_mode,
        "restore_position": _vec2i_array(_presentation_previous_position),
        "restore_size": _vec2i_array(_presentation_previous_size),
        "overlay_visible_before_commit": fullscreen_overlay.visible,
    })

    # Intentionally NOT deferred: Esc must commit the workstation handoff before
    # Godot renders another frame of the fullscreen presentation.
    _commit_atomic_root_exit(generation)


func _commit_atomic_root_exit(generation: int) -> void:
    if generation != _root_presentation_generation or not _fullscreen_active:
        return

    var root_window: Window = get_window()
    var restore_position: Vector2i = _presentation_previous_position
    var restore_size: Vector2i = _presentation_previous_size

    if _presentation_previous_mode != DisplayServer.WINDOW_MODE_WINDOWED \
    and _presentation_previous_has_restore_rect:
        restore_position = _presentation_previous_restore_position
        restore_size = _presentation_previous_restore_size

    root_window.unresizable = false
    root_window.always_on_top = _presentation_previous_always_on_top
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

    # Presentation itself is windowed+borderless. Reassert WINDOWED before the
    # restore rectangle so Windows cannot inject an exclusive/fullscreen bridge.
    if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

    # Geometry and visual handoff are one atomic main-thread transaction. There
    # is deliberately no process_frame await between these calls and hiding the
    # overlay.
    DisplayServer.window_set_size(restore_size)
    DisplayServer.window_set_position(restore_position)

    if _presentation_previous_mode != DisplayServer.WINDOW_MODE_WINDOWED:
        DisplayServer.window_set_mode(_presentation_previous_mode)

    _restore_position = _presentation_previous_restore_position
    _restore_size = _presentation_previous_restore_size
    _has_restore_rect = _presentation_previous_has_restore_rect

    _fullscreen_active = false
    fullscreen_overlay.visible = false
    root_window.unresizable = _presentation_previous_unresizable
    root_window.always_on_top = _presentation_previous_always_on_top
    _last_preview_size = Vector2i.ZERO
    _sync_window_controls()
    root_window.grab_focus()

    _telemetry_event("presentation_exit_atomic_handoff", {
        "atomic_exit_revision": ATOMIC_EXIT_REVISION,
        "exit_strategy": "atomic_overlay_drop",
        "overlay_visible_after_commit": fullscreen_overlay.visible,
        "actual_mode": DisplayServer.window_get_mode(),
        "actual_position": _vec2i_array(DisplayServer.window_get_position()),
        "actual_size": _vec2i_array(DisplayServer.window_get_size()),
        "target_mode": _presentation_previous_mode,
        "target_position": _vec2i_array(restore_position),
        "target_size": _vec2i_array(restore_size),
    })

    call_deferred(
        "_settle_atomic_root_exit",
        generation,
        restore_position,
        restore_size
    )


func _settle_atomic_root_exit(
    generation: int,
    restore_position: Vector2i,
    restore_size: Vector2i
) -> void:
    var root_window: Window = get_window()
    var rect_matched: bool = false
    var mode_matched: bool = false

    for attempt: int in range(ATOMIC_EXIT_ATTEMPTS):
        await get_tree().process_frame

        if generation != _root_presentation_generation or _fullscreen_active:
            return

        var actual_mode: int = DisplayServer.window_get_mode()
        var actual_position: Vector2i = DisplayServer.window_get_position()
        var actual_size: Vector2i = DisplayServer.window_get_size()

        if _presentation_previous_mode == DisplayServer.WINDOW_MODE_WINDOWED:
            mode_matched = actual_mode == DisplayServer.WINDOW_MODE_WINDOWED
            rect_matched = _atomic_rect_matches(
                actual_position,
                actual_size,
                restore_position,
                restore_size
            )

            if not mode_matched:
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            if not rect_matched:
                DisplayServer.window_set_size(restore_size)
                DisplayServer.window_set_position(restore_position)
        else:
            mode_matched = actual_mode == _presentation_previous_mode
            rect_matched = true
            if not mode_matched:
                DisplayServer.window_set_mode(_presentation_previous_mode)

        # The overlay must stay OFF throughout every settle attempt. This is the
        # invariant that prevents the old two-stage visual artifact.
        fullscreen_overlay.visible = false
        _last_preview_size = Vector2i.ZERO
        _sync_preview_resolution(true)

        _telemetry_event("presentation_exit_atomic_settle", {
            "atomic_exit_revision": ATOMIC_EXIT_REVISION,
            "attempt": attempt + 1,
            "overlay_visible": fullscreen_overlay.visible,
            "mode_matched": mode_matched,
            "rect_matched": rect_matched,
            "actual_mode": actual_mode,
            "actual_position": _vec2i_array(actual_position),
            "actual_size": _vec2i_array(actual_size),
            "target_mode": _presentation_previous_mode,
            "target_position": _vec2i_array(restore_position),
            "target_size": _vec2i_array(restore_size),
        })

        if mode_matched and rect_matched:
            break

    root_window.unresizable = _presentation_previous_unresizable
    root_window.always_on_top = _presentation_previous_always_on_top
    fullscreen_overlay.visible = false
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)
    _sync_window_controls()
    root_window.grab_focus()

    _restoring_window = false
    _presentation_transition = false

    _telemetry_event("presentation_exit_complete", {
        "atomic_exit_revision": ATOMIC_EXIT_REVISION,
        "presentation_backend": "root_overlay_atomic_exit",
        "exit_strategy": "atomic_overlay_drop",
        "overlay_visible": fullscreen_overlay.visible,
        "rect_matched": rect_matched,
        "mode_matched": mode_matched,
        "restored_mode": DisplayServer.window_get_mode(),
        "restored_position": _vec2i_array(DisplayServer.window_get_position()),
        "restored_size": _vec2i_array(DisplayServer.window_get_size()),
    })


func _atomic_rect_matches(
    actual_position: Vector2i,
    actual_size: Vector2i,
    target_position: Vector2i,
    target_size: Vector2i
) -> bool:
    return absi(actual_position.x - target_position.x) <= ATOMIC_EXIT_RECT_TOLERANCE \
        and absi(actual_position.y - target_position.y) <= ATOMIC_EXIT_RECT_TOLERANCE \
        and absi(actual_size.x - target_size.x) <= ATOMIC_EXIT_RECT_TOLERANCE \
        and absi(actual_size.y - target_size.y) <= ATOMIC_EXIT_RECT_TOLERANCE


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched: Dictionary = data.duplicate(true)
    enriched["atomic_exit_revision"] = ATOMIC_EXIT_REVISION
    enriched["presentation_backend"] = "root_overlay_atomic_exit"
    super._telemetry_event(event_name, enriched)
