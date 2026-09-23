extends Control

const DesignSystem = preload("res://app/ui/design_system/theme/design_system.gd")

@onready var background: ColorRect = %Background
@onready var gallery_button: Button = %GalleryButton
@onready var settings_button: Button = %SettingsButton
@onready var about_button: Button = %AboutButton
@onready var page_path: Label = %PagePath
@onready var section_index: Label = %SectionIndex
@onready var page_title: Label = %PageTitle
@onready var page_body: Label = %PageBody
@onready var page_tag: Label = %PageTag
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
    theme = DesignSystem.build_theme()
    background.color = DesignSystem.COLOR_CANVAS

    gallery_button.pressed.connect(_show_gallery)
    settings_button.pressed.connect(_show_settings)
    about_button.pressed.connect(_show_about)

    _show_gallery()


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
