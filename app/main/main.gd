extends Control

const DesignSystem = preload("res://app/ui/design_system/theme/design_system.gd")

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

var _last_window_mode := -1


func _ready() -> void:
    theme = DesignSystem.build_theme()
    background.color = DesignSystem.COLOR_CANVAS

    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_min_size(Vector2i(760, 460))
    top_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE

    gallery_button.pressed.connect(_show_gallery)
    settings_button.pressed.connect(_show_settings)
    about_button.pressed.connect(_show_about)

    minimize_button.pressed.connect(_minimize_window)
    maximize_button.pressed.connect(_toggle_maximize_window)
    close_button.pressed.connect(_close_window)
    top_bar.gui_input.connect(_on_top_bar_gui_input)

    _sync_window_controls()
    _show_gallery()


func _process(_delta: float) -> void:
    var mode := DisplayServer.window_get_mode()
    if mode != _last_window_mode:
        _sync_window_controls()


func _show_gallery() -> void:
    _set_page(
        gallery_button,
        "// 01",
        "res://gallery",
        "GALLERY",
        "NO CREATIVE PATCH LOADED. THE HOST IS READY FOR THE FIRST REALTIME SYSTEM.",
        "[EMPTY]",
        "READY / AWAITING FIRST PATCH"
    )


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
    if mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

    _sync_window_controls()


func _close_window() -> void:
    get_tree().quit()


func _sync_window_controls() -> void:
    _last_window_mode = DisplayServer.window_get_mode()
    var maximized := _last_window_mode == DisplayServer.WINDOW_MODE_MAXIMIZED

    maximize_button.text = "▣" if maximized else "□"
    maximize_button.tooltip_text = "Restore" if maximized else "Maximize"
