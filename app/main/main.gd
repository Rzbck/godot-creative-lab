extends Control

const DesignSystem = preload("res://app/ui/design_system/theme/design_system.gd")
const SignalFieldScene = preload("res://sketches/001_signal_field/runtime/signal_field.tscn")

const MIN_WINDOW_SIZE := Vector2i(760, 460)
const RESIZE_GRAB_PX := 6.0

@onready var background: ColorRect = %Background
@onready var top_bar: PanelContainer = %TopBar
@onready var gallery_button: Button = %GalleryButton
@onready var settings_button: Button = %SettingsButton
@onready var about_button: Button = %AboutButton
@onready var minimize_button: Button = %MinimizeButton
@onready var maximize_button: Button = %MaximizeButton
@onready var close_button: Button = %CloseButton
@onready var page_path: Label = %PagePath
@onready var section_index: Label = %SectionIndex
@onready var page_title: Label = %PageTitle
@onready var page_body: Label = %PageBody
@onready var page_tag: Label = %PageTag
@onready var status_label: Label = %StatusLabel
@onready var fps_state: Label = %FpsState
@onready var gallery_host: HBoxContainer = %GalleryHost
@onready var page_spacer: Control = %PageSpacer
@onready var run_patch_button: Button = %RunPatchButton
@onready var stop_patch_button: Button = %StopPatchButton
@onready var patch_state: Label = %PatchState
@onready var sketch_viewport_container: SubViewportContainer = %SketchViewportContainer
@onready var sketch_viewport: SubViewport = %SketchViewport

var _last_window_mode := -1
var _restore_position := Vector2i.ZERO
var _restore_size := Vector2i(1280, 720)
var _has_restore_rect := false
var _restoring_window := false
var _active_sketch: Node = null
var _last_preview_size := Vector2i.ZERO


func _ready() -> void:
    theme = DesignSystem.build_theme()
    background.color = DesignSystem.COLOR_CANVAS

    var root_window := get_window()
    root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    root_window.content_scale_factor = 1.0
    root_window.min_size = MIN_WINDOW_SIZE

    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
    top_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE

    gallery_button.pressed.connect(_show_gallery)
    settings_button.pressed.connect(_show_settings)
    about_button.pressed.connect(_show_about)

    run_patch_button.pressed.connect(_run_signal_field)
    stop_patch_button.pressed.connect(_stop_signal_field)

    minimize_button.pressed.connect(_minimize_window)
    maximize_button.pressed.connect(_toggle_maximize_window)
    close_button.pressed.connect(_close_window)
    top_bar.gui_input.connect(_on_top_bar_gui_input)

    _remember_windowed_rect()
    _sync_window_controls()
    _show_gallery()
    call_deferred("_sync_preview_resolution")


func _process(_delta: float) -> void:
    var mode := DisplayServer.window_get_mode()

    if mode == DisplayServer.WINDOW_MODE_WINDOWED and not _restoring_window:
        _remember_windowed_rect()

    if mode != _last_window_mode:
        _sync_window_controls()

    fps_state.text = "FPS %d" % Engine.get_frames_per_second()
    _sync_preview_resolution()


func _input(event: InputEvent) -> void:
    if not event is InputEventMouseButton:
        return

    var mouse_event := event as InputEventMouseButton
    if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
        return

    if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
        return

    var edge := _resize_edge_for_position(mouse_event.position)
    if edge == -1:
        return

    DisplayServer.window_start_resize(edge)
    get_viewport().set_input_as_handled()


func _show_gallery() -> void:
    _set_page(
        gallery_button,
        "// 01",
        "res://gallery",
        "GALLERY",
        "001 SIGNAL FIELD IS READY. RUN THE PATCH TO START THE FIRST REALTIME SYSTEM.",
        "[001]",
        "GALLERY / 001 READY"
    )
    gallery_host.visible = true
    page_spacer.visible = false
    _set_sketch_processing(true)
    call_deferred("_sync_preview_resolution")


func _show_settings() -> void:
    _set_page(
        settings_button,
        "// 02",
        "res://settings",
        "SETTINGS",
        "APPLICATION PREFERENCES WILL LIVE HERE. GLOBAL VISUAL TOKENS REMAIN CENTRALIZED IN THE DESIGN SYSTEM.",
        "[SYSTEM]",
        "SETTINGS / ARCHITECTURE READY"
    )
    gallery_host.visible = false
    page_spacer.visible = true
    _set_sketch_processing(false)


func _show_about() -> void:
    _set_page(
        about_button,
        "// 03",
        "res://about",
        "ABOUT",
        "DATAC0RE CREATIVE LAB / GODOT 4.7.1 / REALTIME CREATIVE-CODING WORKSTATION.",
        "[DEV]",
        "SHELL / ONLINE"
    )
    gallery_host.visible = false
    page_spacer.visible = true
    _set_sketch_processing(false)


func _set_page(
    active_button: Button,
    index: String,
    path: String,
    title: String,
    body: String,
    tag: String,
    status: String
) -> void:
    gallery_button.button_pressed = active_button == gallery_button
    settings_button.button_pressed = active_button == settings_button
    about_button.button_pressed = active_button == about_button

    section_index.text = index
    page_path.text = path
    page_title.text = title
    page_body.text = body
    page_tag.text = tag
    status_label.text = status


func _run_signal_field() -> void:
    if is_instance_valid(_active_sketch):
        return

    _active_sketch = SignalFieldScene.instantiate()
    sketch_viewport.add_child(_active_sketch)

    run_patch_button.disabled = true
    stop_patch_button.disabled = false
    patch_state.text = "[RUNNING]"
    page_tag.text = "[LIVE]"
    page_body.text = "001 SIGNAL FIELD / REALTIME POINT NETWORK / ADAPTIVE VIEWPORT"
    status_label.text = "RUN / 001_SIGNAL_FIELD"

    _set_sketch_processing(gallery_host.visible)
    call_deferred("_sync_preview_resolution")


func _stop_signal_field() -> void:
    if is_instance_valid(_active_sketch):
        _active_sketch.queue_free()

    _active_sketch = null
    run_patch_button.disabled = false
    stop_patch_button.disabled = true
    patch_state.text = "[STOPPED]"
    page_tag.text = "[001]"
    page_body.text = "001 SIGNAL FIELD IS READY. RUN THE PATCH TO START THE FIRST REALTIME SYSTEM."
    status_label.text = "GALLERY / 001 READY"


func _set_sketch_processing(enabled: bool) -> void:
    if not is_instance_valid(_active_sketch):
        return

    _active_sketch.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED


func _sync_preview_resolution() -> void:
    if not is_instance_valid(sketch_viewport_container) or not is_instance_valid(sketch_viewport):
        return

    var target := Vector2i(
        maxi(1, roundi(sketch_viewport_container.size.x)),
        maxi(1, roundi(sketch_viewport_container.size.y))
    )

    if target == _last_preview_size:
        return

    sketch_viewport.size = target
    _last_preview_size = target

    if _active_sketch is CanvasItem:
        (_active_sketch as CanvasItem).queue_redraw()


func _on_top_bar_gui_input(event: InputEvent) -> void:
    if not event is InputEventMouseButton:
        return

    var mouse_event := event as InputEventMouseButton
    if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
        return

    if mouse_event.double_click:
        _toggle_maximize_window()
    else:
        DisplayServer.window_start_drag()

    top_bar.accept_event()


func _minimize_window() -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


func _toggle_maximize_window() -> void:
    var mode := DisplayServer.window_get_mode()

    if _is_expanded_mode(mode):
        _restore_window()
        return

    if mode == DisplayServer.WINDOW_MODE_WINDOWED:
        _remember_windowed_rect()

    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
    _sync_window_controls()


func _restore_window() -> void:
    _restoring_window = true
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    call_deferred("_apply_restore_rect")


func _apply_restore_rect() -> void:
    if _has_restore_rect:
        DisplayServer.window_set_position(_restore_position)
        DisplayServer.window_set_size(_restore_size)

    _restoring_window = false
    _remember_windowed_rect()
    _sync_window_controls()


func _remember_windowed_rect() -> void:
    if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
        return

    var size := DisplayServer.window_get_size()
    if size.x < MIN_WINDOW_SIZE.x or size.y < MIN_WINDOW_SIZE.y:
        return

    _restore_position = DisplayServer.window_get_position()
    _restore_size = size
    _has_restore_rect = true


func _is_expanded_mode(mode: int) -> bool:
    return mode == DisplayServer.WINDOW_MODE_MAXIMIZED \
        or mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
        or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _resize_edge_for_position(position: Vector2) -> int:
    var window_size := Vector2(DisplayServer.window_get_size())

    var left := position.x <= RESIZE_GRAB_PX
    var right := position.x >= window_size.x - RESIZE_GRAB_PX
    var top := position.y <= RESIZE_GRAB_PX
    var bottom := position.y >= window_size.y - RESIZE_GRAB_PX

    if top and left:
        return DisplayServer.WINDOW_EDGE_TOP_LEFT
    if top and right:
        return DisplayServer.WINDOW_EDGE_TOP_RIGHT
    if bottom and left:
        return DisplayServer.WINDOW_EDGE_BOTTOM_LEFT
    if bottom and right:
        return DisplayServer.WINDOW_EDGE_BOTTOM_RIGHT
    if top:
        return DisplayServer.WINDOW_EDGE_TOP
    if bottom:
        return DisplayServer.WINDOW_EDGE_BOTTOM
    if left:
        return DisplayServer.WINDOW_EDGE_LEFT
    if right:
        return DisplayServer.WINDOW_EDGE_RIGHT

    return -1


func _close_window() -> void:
    get_tree().quit()


func _sync_window_controls() -> void:
    _last_window_mode = DisplayServer.window_get_mode()
    var expanded := _is_expanded_mode(_last_window_mode)

    maximize_button.text = "▣" if expanded else "□"
    maximize_button.tooltip_text = "Restore" if expanded else "Maximize"
