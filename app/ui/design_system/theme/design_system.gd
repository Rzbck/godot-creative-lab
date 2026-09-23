extends RefCounted

# Compact workstation skin for DataC0re Creative Lab.
# Every reusable visual value lives here: screens should consume the theme,
# not invent their own colours, radii, spacing or typography.

const COLOR_CANVAS := Color(0.035, 0.043, 0.055, 1.0)
const COLOR_SURFACE := Color(0.052, 0.063, 0.078, 1.0)
const COLOR_SURFACE_RAISED := Color(0.070, 0.082, 0.102, 1.0)
const COLOR_SURFACE_HOVER := Color(0.090, 0.106, 0.129, 1.0)
const COLOR_SURFACE_PRESSED := Color(0.118, 0.125, 0.137, 1.0)
const COLOR_BORDER := Color(0.165, 0.188, 0.224, 0.68)
const COLOR_BORDER_SOFT := Color(0.145, 0.165, 0.196, 0.42)
const COLOR_TEXT := Color(0.910, 0.925, 0.945, 1.0)
const COLOR_TEXT_MUTED := Color(0.545, 0.584, 0.647, 1.0)
const COLOR_TEXT_DIM := Color(0.390, 0.431, 0.494, 1.0)
const COLOR_ACCENT := Color(0.941, 0.651, 0.357, 1.0)
const COLOR_ACCENT_SOFT := Color(0.941, 0.651, 0.357, 0.14)
const COLOR_ACCENT_HOVER := Color(1.0, 0.714, 0.431, 1.0)
const COLOR_DANGER := Color(0.886, 0.376, 0.376, 1.0)

const FONT_MICRO := 10
const FONT_CAPTION := 11
const FONT_BODY := 12
const FONT_TITLE := 17
const FONT_BRAND := 13

const SPACE_1 := 4
const SPACE_2 := 6
const SPACE_3 := 8
const SPACE_4 := 12
const SPACE_5 := 16

const RADIUS_NONE := 0
const RADIUS_SMALL := 2
const RADIUS_MEDIUM := 3


static func build_theme() -> Theme:
    var theme := Theme.new()
    theme.default_font = _mono_font()
    theme.default_font_size = FONT_BODY

    _define_labels(theme)
    _define_buttons(theme)
    _define_panels(theme)
    _define_margins(theme)
    _define_containers(theme)
    _define_separators(theme)

    return theme


static func _define_labels(theme: Theme) -> void:
    theme.set_color("font_color", "Label", COLOR_TEXT)
    theme.set_font_size("font_size", "Label", FONT_BODY)

    theme.set_type_variation("BrandLabel", "Label")
    theme.set_font_size("font_size", "BrandLabel", FONT_BRAND)
    theme.set_color("font_color", "BrandLabel", COLOR_ACCENT)

    theme.set_type_variation("PageTitleLabel", "Label")
    theme.set_font_size("font_size", "PageTitleLabel", FONT_TITLE)
    theme.set_color("font_color", "PageTitleLabel", COLOR_TEXT)

    theme.set_type_variation("BodyMutedLabel", "Label")
    theme.set_font_size("font_size", "BodyMutedLabel", FONT_BODY)
    theme.set_color("font_color", "BodyMutedLabel", COLOR_TEXT_MUTED)

    theme.set_type_variation("CaptionLabel", "Label")
    theme.set_font_size("font_size", "CaptionLabel", FONT_CAPTION)
    theme.set_color("font_color", "CaptionLabel", COLOR_TEXT_MUTED)

    theme.set_type_variation("MicroLabel", "Label")
    theme.set_font_size("font_size", "MicroLabel", FONT_MICRO)
    theme.set_color("font_color", "MicroLabel", COLOR_TEXT_DIM)

    theme.set_type_variation("PathLabel", "Label")
    theme.set_font_size("font_size", "PathLabel", FONT_CAPTION)
    theme.set_color("font_color", "PathLabel", COLOR_TEXT_MUTED)

    theme.set_type_variation("AccentLabel", "Label")
    theme.set_font_size("font_size", "AccentLabel", FONT_CAPTION)
    theme.set_color("font_color", "AccentLabel", COLOR_ACCENT)

    theme.set_type_variation("TagLabel", "Label")
    theme.set_font_size("font_size", "TagLabel", FONT_MICRO)
    theme.set_color("font_color", "TagLabel", COLOR_ACCENT)


static func _define_buttons(theme: Theme) -> void:
    theme.set_color("font_color", "Button", COLOR_TEXT_MUTED)
    theme.set_color("font_hover_color", "Button", COLOR_TEXT)
    theme.set_color("font_pressed_color", "Button", COLOR_ACCENT)
    theme.set_color("font_focus_color", "Button", COLOR_TEXT)
    theme.set_color("font_disabled_color", "Button", COLOR_TEXT_DIM)
    theme.set_color("icon_normal_color", "Button", COLOR_TEXT_MUTED)
    theme.set_color("icon_hover_color", "Button", COLOR_TEXT)
    theme.set_color("icon_pressed_color", "Button", COLOR_ACCENT)
    theme.set_color("icon_focus_color", "Button", COLOR_TEXT)
    theme.set_color("icon_disabled_color", "Button", COLOR_TEXT_DIM)
    theme.set_font_size("font_size", "Button", FONT_BODY)

    theme.set_stylebox("normal", "Button", _box(COLOR_SURFACE, COLOR_BORDER_SOFT, RADIUS_SMALL, 1, 8.0, 5.0))
    theme.set_stylebox("hover", "Button", _box(COLOR_SURFACE_HOVER, COLOR_BORDER, RADIUS_SMALL, 1, 8.0, 5.0))
    theme.set_stylebox("pressed", "Button", _box(COLOR_ACCENT_SOFT, COLOR_ACCENT, RADIUS_SMALL, 1, 8.0, 5.0))
    theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), COLOR_ACCENT, RADIUS_SMALL, 1, 8.0, 5.0))
    theme.set_stylebox("disabled", "Button", _box(COLOR_CANVAS, COLOR_BORDER_SOFT, RADIUS_SMALL, 1, 8.0, 5.0))

    theme.set_type_variation("NavButton", "Button")
    theme.set_stylebox("normal", "NavButton", _box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), RADIUS_SMALL, 0, 6.0, 6.0))
    theme.set_stylebox("hover", "NavButton", _box(COLOR_SURFACE_HOVER, COLOR_BORDER_SOFT, RADIUS_SMALL, 1, 6.0, 6.0))
    theme.set_stylebox("pressed", "NavButton", _box(COLOR_ACCENT_SOFT, COLOR_ACCENT, RADIUS_SMALL, 1, 6.0, 6.0))
    theme.set_stylebox("focus", "NavButton", _box(Color(0, 0, 0, 0), COLOR_ACCENT, RADIUS_SMALL, 1, 6.0, 6.0))

    theme.set_type_variation("ToolButton", "Button")
    theme.set_font_size("font_size", "ToolButton", FONT_CAPTION)
    theme.set_stylebox("normal", "ToolButton", _box(COLOR_SURFACE, COLOR_BORDER_SOFT, RADIUS_SMALL, 1, 7.0, 3.0))
    theme.set_stylebox("hover", "ToolButton", _box(COLOR_SURFACE_HOVER, COLOR_BORDER, RADIUS_SMALL, 1, 7.0, 3.0))
    theme.set_stylebox("pressed", "ToolButton", _box(COLOR_ACCENT_SOFT, COLOR_ACCENT, RADIUS_SMALL, 1, 7.0, 3.0))


static func _define_panels(theme: Theme) -> void:
    theme.set_stylebox("panel", "PanelContainer", _box(COLOR_SURFACE, COLOR_BORDER_SOFT, RADIUS_SMALL, 1, 0.0, 0.0))

    theme.set_type_variation("TopBarPanel", "PanelContainer")
    theme.set_stylebox("panel", "TopBarPanel", _box(COLOR_SURFACE, COLOR_BORDER_SOFT, RADIUS_SMALL, 1, 8.0, 5.0))

    theme.set_type_variation("RailPanel", "PanelContainer")
    theme.set_stylebox("panel", "RailPanel", _box(COLOR_SURFACE, COLOR_BORDER_SOFT, RADIUS_SMALL, 1, 4.0, 4.0))

    theme.set_type_variation("WorkspacePanel", "PanelContainer")
    theme.set_stylebox("panel", "WorkspacePanel", _box(COLOR_SURFACE, COLOR_BORDER_SOFT, RADIUS_SMALL, 1, 0.0, 0.0))

    theme.set_type_variation("StatusPanel", "PanelContainer")
    theme.set_stylebox("panel", "StatusPanel", _box(COLOR_SURFACE_RAISED, COLOR_BORDER_SOFT, RADIUS_SMALL, 1, 8.0, 3.0))


static func _define_margins(theme: Theme) -> void:
    theme.set_type_variation("ShellMargin", "MarginContainer")
    _set_margin_constants(theme, "ShellMargin", 8)

    theme.set_type_variation("WorkspaceMargin", "MarginContainer")
    _set_margin_constants(theme, "WorkspaceMargin", 14)


static func _define_containers(theme: Theme) -> void:
    theme.set_constant("separation", "HBoxContainer", SPACE_2)
    theme.set_constant("separation", "VBoxContainer", SPACE_2)


static func _define_separators(theme: Theme) -> void:
    var horizontal := StyleBoxLine.new()
    horizontal.color = COLOR_BORDER_SOFT
    horizontal.thickness = 1
    theme.set_stylebox("separator", "HSeparator", horizontal)

    var vertical := StyleBoxLine.new()
    vertical.color = COLOR_BORDER_SOFT
    vertical.thickness = 1
    vertical.vertical = true
    theme.set_stylebox("separator", "VSeparator", vertical)


static func _mono_font() -> Font:
    var font := SystemFont.new()
    font.font_names = PackedStringArray([
        "JetBrains Mono",
        "Cascadia Mono",
        "IBM Plex Mono",
        "Consolas",
        "DejaVu Sans Mono"
    ])
    return font


static func _set_margin_constants(theme: Theme, type_name: StringName, amount: int) -> void:
    theme.set_constant("margin_left", type_name, amount)
    theme.set_constant("margin_top", type_name, amount)
    theme.set_constant("margin_right", type_name, amount)
    theme.set_constant("margin_bottom", type_name, amount)


static func _box(
    background: Color,
    border: Color,
    radius: int,
    border_width: int,
    horizontal_margin: float,
    vertical_margin: float
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

    box.content_margin_left = horizontal_margin
    box.content_margin_right = horizontal_margin
    box.content_margin_top = vertical_margin
    box.content_margin_bottom = vertical_margin

    return box
