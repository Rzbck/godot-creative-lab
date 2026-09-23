extends "res://app/main/main_base.gd"

var _presentation_previous_position: Vector2i = Vector2i.ZERO
var _presentation_previous_size: Vector2i = Vector2i(1280, 720)
var _presentation_previous_always_on_top: bool = false
var _presentation_previous_unresizable: bool = false
var _presentation_screen: int = 0
var _presentation_transition: bool = false


func _create_render_window() -> void:
    # Presentation deliberately uses the existing application window in
    # WINDOWED mode. We only move/resize the borderless window so Windows never
    # performs a fullscreen mode transition and the normal UI layout can be
    # restored deterministically.
    pass


func _enter_render_fullscreen() -> void:
    if not is_instance_valid(_active_sketch) or _fullscreen_active or _presentation_transition:
        return

    var root_window: Window = get_window()

    _presentation_transition = true
    _restoring_window = true

    _presentation_previous_position = root_window.position
    _presentation_previous_size = root_window.size
    _presentation_previous_always_on_top = root_window.always_on_top
    _presentation_previous_unresizable = root_window.unresizable
    _presentation_screen = root_window.current_screen

    _fullscreen_active = true
    fullscreen_texture.texture = sketch_viewport.get_texture()
    fullscreen_overlay.visible = true
    fullscreen_overlay.grab_focus()

    # Keep the same native HWND and the same WINDOWED mode. The app is already
    # borderless, so covering the physical monitor gives us presentation output
    # without triggering the layout corruption seen after Windows fullscreen.
    root_window.always_on_top = true
    root_window.unresizable = true
    root_window.position = DisplayServer.screen_get_position(_presentation_screen)
    root_window.size = DisplayServer.screen_get_size(_presentation_screen)
    root_window.grab_focus()

    _last_preview_size = Vector2i.ZERO
    call_deferred("_finish_enter_render_fullscreen")


func _finish_enter_render_fullscreen() -> void:
    # Let Windows apply the physical monitor rectangle, then render at the
    # actual resulting window size. The overlay covers every piece of app UI.
    await get_tree().process_frame
    await get_tree().process_frame

    if not _fullscreen_active:
        _presentation_transition = false
        return

    fullscreen_overlay.grab_focus()
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)
    _presentation_transition = false


func _exit_render_fullscreen() -> void:
    if not _fullscreen_active or _presentation_transition:
        return

    _presentation_transition = true

    var root_window: Window = get_window()

    # Keep the render overlay visible while restoring the old rectangle. This
    # prevents the normal UI from ever being shown at monitor size. Containers
    # get two frames to relayout at the restored dimensions before we reveal it.
    root_window.position = _presentation_previous_position
    root_window.size = _presentation_previous_size
    root_window.always_on_top = _presentation_previous_always_on_top
    root_window.unresizable = _presentation_previous_unresizable

    call_deferred("_finish_exit_render_fullscreen")


func _finish_exit_render_fullscreen() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame

    # Only reveal the application after the window and all Containers are back
    # at their original dimensions.
    _fullscreen_active = false
    fullscreen_overlay.visible = false
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)

    _restoring_window = false
    _remember_windowed_rect()
    _sync_window_controls()
    get_window().grab_focus()
    _presentation_transition = false


func _sync_preview_resolution(force: bool = false) -> void:
    if not is_instance_valid(sketch_viewport):
        return

    var target_size: Vector2
    if _fullscreen_active:
        target_size = fullscreen_overlay.size
    else:
        target_size = sketch_viewport_container.size

    var target: Vector2i = Vector2i(
        maxi(1, roundi(target_size.x)),
        maxi(1, roundi(target_size.y))
    )

    if not force and target == _last_preview_size:
        return

    sketch_viewport.size = target
    _last_preview_size = target
    preview_resolution.text = "%d×%d" % [target.x, target.y]

    if _active_sketch is CanvasItem:
        (_active_sketch as CanvasItem).queue_redraw()
