extends Control

const DesignSystem = preload("res://app/ui/design_system/theme/design_system.gd")

@onready var gallery_button: Button = %GalleryButton
@onready var settings_button: Button = %SettingsButton
@onready var about_button: Button = %AboutButton
@onready var page_title: Label = %PageTitle
@onready var page_body: Label = %PageBody
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
    theme = DesignSystem.build_theme()

    gallery_button.pressed.connect(_show_gallery)
    settings_button.pressed.connect(_show_settings)
    about_button.pressed.connect(_show_about)

    _show_gallery()


func _show_gallery() -> void:
    _set_page(
        "Gallery",
        "Aucun projet créatif n'est encore défini. Le shell de Creative Lab fonctionne, mais aucun sketch n'a été créé.",
        "Shell ready · no creative project loaded"
    )


func _show_settings() -> void:
    _set_page(
        "Settings",
        "Le système de réglages sera branché ici. Les préférences utilisateur resteront séparées de project.godot.",
        "Settings architecture ready · implementation pending"
    )


func _show_about() -> void:
    _set_page(
        "About",
        "DataC0re Creative Lab · Godot 4.7.1 · architecture, CI et design system centralisé en place.",
        "Application shell · no sketch selected"
    )


func _set_page(title: String, body: String, status: String) -> void:
    page_title.text = title
    page_body.text = body
    status_label.text = status
