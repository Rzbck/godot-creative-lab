extends "res://app/main/main_base.gd"

var _presentation_previous_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
var _presentation_previous_position: Vector2i = Vector2i.ZERO
var _presentation_previous_size: Vector2i = Vector2i(1280, 720)
var _presentation_transition: bool = false


func _create_render_window() -> void:
    # True presentation fullscreen uses the main application window.
    # No secondary/windowed output is created.
    pass


func _enter_render_fullscreen() -> void:
    if not is_instance_valid(_active_sketch) or _fullscreen_active or _presentation_transition:
        return

    _presentation_transition = true
    _restoring_window = true
    _presentation_previous_mode = DisplayServer.window_get_mode()

    if _presentation_previous_mode == DisplayServer.WINDOW_MODE_WINDOWED:
        _presentation_previous_position = DisplayServer.window_get_position()
        _presentation_previous_size = DisplayServer.window_get_size()

    _fullscreen_active = true
    fullscreen_texture.texture = sketch_viewport.get_texture()
    fullscreen_overlay.visible = true
    fullscreen_overlay.grab_focus()
    _last_preview_size = Vector2i.ZERO

    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
    DisplayServer.window_move_to_foreground()
    call_deferred("_finish_enter_render_fullscreen")


func _finish_enter_render_fullscreen() -> void:
    await get_tree().process_frame
    await get_tree().process_frame

    if not _fullscreen_active:
        _presentation_transition = false
        _restoring_window = false
        return

    _sync_preview_resolution(true)
    fullscreen_overlay.grab_focus()
    _presentation_transition = false


func _exit_render_fullscreen() -> void:
    if not _fullscreen_active or _presentation_transition:
        return

    _presentation_transition = true

    if _presentation_previous_mode == DisplayServer.WINDOW_MODE_WINDOWED:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(_presentation_previous_mode)

    call_deferred("_finish_exit_render_fullscreen")


func _finish_exit_render_fullscreen() -> void:
    await get_tree().process_frame

    if _presentation_previous_mode == DisplayServer.WINDOW_MODE_WINDOWED:
        DisplayServer.window_set_position(_presentation_previous_position)
        DisplayServer.window_set_size(_presentation_previous_size)

    await get_tree().process_frame
    await get_tree().process_frame

    _fullscreen_active = false
    fullscreen_overlay.visible = false
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)
    get_window().grab_focus()

    _restoring_window = false
    _presentation_transition = false
    _remember_windowed_rect()
    _sync_window_controls()
