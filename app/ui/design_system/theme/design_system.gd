extends RefCounted

# Centralized runtime design system for the application shell.
# Visual values live here so screens do not hard-code their own skin.

const COLOR_CANVAS := Color(0.047, 0.055, 0.071, 1.0)
const COLOR_SURFACE := Color(0.078, 0.086, 0.106, 1.0)
const COLOR_SURFACE_HOVER := Color(0.110, 0.122, 0.149, 1.0)
const COLOR_SURFACE_PRESSED := Color(0.137, 0.153, 0.184, 1.0)
const COLOR_BORDER := Color(0.190, 0.208, 0.247, 0.65)
const COLOR_TEXT := Color(0.922, 0.933, 0.957, 1.0)
const COLOR_TEXT_MUTED := Color(0.600, 0.631, 0.690, 1.0)
const COLOR_ACCENT := Color(0.486, 0.596, 1.0, 1.0)
const COLOR_ACCENT_HOVER := Color(0.565, 0.655, 1.0, 1.0)
const COLOR_SUCCESS := Color(0.408, 0.824, 0.612, 1.0)

const FONT_BODY := 16
const FONT_TITLE := 30
const FONT_CAPTION := 13

const RADIUS_SMALL := 7
const RADIUS_MEDIUM := 11
const BORDER_WIDTH := 1

const SPACE_SMALL := 8
const SPACE_MEDIUM := 12
const SPACE_LARGE := 24


static func build_theme() -> Theme:
    var theme := Theme.new()
    theme.default_font_size = FONT_BODY

    theme.set_color("font_color", "Label", COLOR_TEXT)
    theme.set_font_size("font_size", "Label", FONT_BODY)

    theme.set_type_variation("TitleLabel", "Label")
    theme.set_font_size("font_size", "TitleLabel", FONT_TITLE)
    theme.set_color("font_color", "TitleLabel", COLOR_TEXT)

    theme.set_type_variation("MutedLabel", "Label")
    theme.set_font_size("font_size", "MutedLabel", FONT_BODY)
    theme.set_color("font_color", "MutedLabel", COLOR_TEXT_MUTED)

    theme.set_type_variation("CaptionLabel", "Label")
    theme.set_font_size("font_size", "CaptionLabel", FONT_CAPTION)
    theme.set_color("font_color", "CaptionLabel", COLOR_TEXT_MUTED)

    theme.set_color("font_color", "Button", COLOR_TEXT)
    theme.set_color("font_hover_color", "Button", COLOR_TEXT)
    theme.set_color("font_pressed_color", "Button", COLOR_TEXT)
    theme.set_color("font_focus_color", "Button", COLOR_TEXT)
    theme.set_color("font_disabled_color", "Button", COLOR_TEXT_MUTED)
    theme.set_font_size("font_size", "Button", FONT_BODY)
    theme.set_stylebox("normal", "Button", _box(COLOR_SURFACE, COLOR_BORDER, RADIUS_SMALL))
    theme.set_stylebox("hover", "Button", _box(COLOR_SURFACE_HOVER, COLOR_ACCENT, RADIUS_SMALL))
    theme.set_stylebox("pressed", "Button", _box(COLOR_SURFACE_PRESSED, COLOR_ACCENT, RADIUS_SMALL))
    theme.set_stylebox("focus", "Button", _box(COLOR_SURFACE_HOVER, COLOR_ACCENT, RADIUS_SMALL, 2))
    theme.set_stylebox("disabled", "Button", _box(COLOR_CANVAS, COLOR_BORDER, RADIUS_SMALL))

    theme.set_type_variation("PrimaryButton", "Button")
    theme.set_stylebox("normal", "PrimaryButton", _box(COLOR_ACCENT, COLOR_ACCENT, RADIUS_SMALL))
    theme.set_stylebox("hover", "PrimaryButton", _box(COLOR_ACCENT_HOVER, COLOR_ACCENT_HOVER, RADIUS_SMALL))
    theme.set_stylebox("pressed", "PrimaryButton", _box(COLOR_ACCENT_HOVER, COLOR_TEXT, RADIUS_SMALL))

    theme.set_stylebox("panel", "PanelContainer", _box(COLOR_SURFACE, COLOR_BORDER, RADIUS_MEDIUM))

    theme.set_constant("separation", "HBoxContainer", SPACE_MEDIUM)
    theme.set_constant("separation", "VBoxContainer", SPACE_MEDIUM)
    theme.set_constant("margin_left", "MarginContainer", SPACE_LARGE)
    theme.set_constant("margin_top", "MarginContainer", SPACE_LARGE)
    theme.set_constant("margin_right", "MarginContainer", SPACE_LARGE)
    theme.set_constant("margin_bottom", "MarginContainer", SPACE_LARGE)

    return theme


static func _box(
    background: Color,
    border: Color,
    radius: int,
    border_width: int = BORDER_WIDTH
) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = background
    box.border_color = border

    box.border_width_left = border_width
    box.border_width_top = border_width
    box.border_width_right = border_width
    box.border_width_bottom = border_width

    box.corner_radius_top_left = radius
    box.corner_radius_top_right = radius
    box.corner_radius_bottom_right = radius
    box.corner_radius_bottom_left = radius

    box.content_margin_left = 14.0
    box.content_margin_right = 14.0
    box.content_margin_top = 9.0
    box.content_margin_bottom = 9.0

    return box
