extends "res://app/main/main_base.gd"

var _render_window: Window = null
var _render_window_texture: TextureRect = null
var _presentation_transition: bool = false


func _create_render_window() -> void:
    if is_instance_valid(_render_window):
        return

    get_viewport().gui_embed_subwindows = false

    _render_window = Window.new()
    _render_window.name = "RenderFullscreenWindow"
    _render_window.title = "DataC0re Creative Lab / Output"
    _render_window.visible = false
    _render_window.borderless = true
    _render_window.unresizable = true
    _render_window.transient = false
    _render_window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    _render_window.content_scale_factor = 1.0
    add_child(_render_window)

    var render_background: ColorRect = ColorRect.new()
    render_background.name = "Background"
    render_background.color = Color.BLACK
    render_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    render_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _render_window.add_child(render_background)

    _render_window_texture = TextureRect.new()
    _render_window_texture.name = "RenderTexture"
    _render_window_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _render_window_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _render_window_texture.stretch_mode = TextureRect.STRETCH_SCALE
    _render_window_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _render_window.add_child(_render_window_texture)

    _render_window.close_requested.connect(_exit_render_fullscreen)
    _render_window.window_input.connect(_on_render_window_input)
    _render_window.size_changed.connect(_on_render_window_size_changed)


func _enter_render_fullscreen() -> void:
    if not is_instance_valid(_active_sketch) or _fullscreen_active or _presentation_transition:
        return

    _create_render_window()
    if not is_instance_valid(_render_window) or not is_instance_valid(_render_window_texture):
        return

    _presentation_transition = true
    _fullscreen_active = true
    _render_window_texture.texture = sketch_viewport.get_texture()
    _render_window.current_screen = get_window().current_screen
    _render_window.mode = Window.MODE_WINDOWED
    _render_window.show()
    _last_preview_size = Vector2i.ZERO
    call_deferred("_finish_enter_render_fullscreen")


func _finish_enter_render_fullscreen() -> void:
    await get_tree().process_frame

    if not _fullscreen_active or not is_instance_valid(_render_window):
        _presentation_transition = false
        return

    _render_window.current_screen = get_window().current_screen
    _render_window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN

    await get_tree().process_frame
    await get_tree().process_frame

    if not _fullscreen_active:
        _presentation_transition = false
        return

    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)
    _render_window.grab_focus()
    _presentation_transition = false


func _exit_render_fullscreen() -> void:
    if not _fullscreen_active or _presentation_transition:
        return

    _presentation_transition = true

    if is_instance_valid(_render_window):
        _render_window.mode = Window.MODE_WINDOWED

    call_deferred("_finish_exit_render_fullscreen")


func _finish_exit_render_fullscreen() -> void:
    await get_tree().process_frame

    if is_instance_valid(_render_window):
        _render_window.hide()

    _fullscreen_active = false
    _last_preview_size = Vector2i.ZERO

    await get_tree().process_frame
    await get_tree().process_frame

    _sync_preview_resolution(true)
    get_window().grab_focus()
    _presentation_transition = false


func _on_render_window_input(event: InputEvent) -> void:
    if not _fullscreen_active:
        return

    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_F11:
                _exit_render_fullscreen()
                if is_instance_valid(_render_window):
                    _render_window.set_input_as_handled()
                return

    if is_instance_valid(_active_sketch):
        sketch_viewport.push_input(event, true)


func _on_render_window_size_changed() -> void:
    if not _fullscreen_active:
        return

    _last_preview_size = Vector2i.ZERO
    call_deferred("_sync_preview_resolution", true)


func _sync_preview_resolution(force: bool = false) -> void:
    if not is_instance_valid(sketch_viewport):
        return

    var target_size: Vector2
    if _fullscreen_active and is_instance_valid(_render_window) and _render_window.visible:
        target_size = Vector2(_render_window.size)
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


func _close_window() -> void:
    if is_instance_valid(_render_window):
        _render_window.hide()
    get_tree().quit()
