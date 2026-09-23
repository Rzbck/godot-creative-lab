extends Control

const DesignSystem = preload("res://app/ui/design_system/theme/design_system.gd")

const SKETCHES_ROOT: String = "res://sketches"
const MIN_WINDOW_SIZE: Vector2i = Vector2i(760, 460)
const RESIZE_GRAB_PX: float = 6.0

@onready var background: ColorRect = %Background
@onready var margin: MarginContainer = %Margin
@onready var top_bar: PanelContainer = %TopBar
@onready var rail: PanelContainer = %Rail
@onready var status_bar: PanelContainer = %StatusBar
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

@onready var gallery_view: VBoxContainer = %GalleryView
@onready var gallery_scroll: ScrollContainer = %GalleryScroll
@onready var gallery_grid: GridContainer = %GalleryGrid

@onready var project_view: HBoxContainer = %ProjectView
@onready var project_back_button: Button = %ProjectBackButton
@onready var fullscreen_button: Button = %FullscreenButton
@onready var project_index: Label = %ProjectIndex
@onready var project_title: Label = %ProjectTitle
@onready var project_meta: Label = %ProjectMeta
@onready var preview_resolution: Label = %PreviewResolution
@onready var sketch_viewport_container: SubViewportContainer = %SketchViewportContainer
@onready var sketch_viewport: SubViewport = %SketchViewport
@onready var parameter_list: VBoxContainer = %ParameterList
@onready var page_spacer: Control = %PageSpacer
@onready var fullscreen_overlay: Control = %FullscreenOverlay
@onready var fullscreen_texture: TextureRect = %FullscreenTexture

var _catalog: Array[Dictionary] = []
var _active_definition: Dictionary = {}
var _active_sketch: Node = null
var _fullscreen_active: bool = false
var _last_preview_size: Vector2i = Vector2i.ZERO

var _last_window_mode: int = -1
var _restore_position: Vector2i = Vector2i.ZERO
var _restore_size: Vector2i = Vector2i(1280, 720)
var _has_restore_rect: bool = false
var _restoring_window: bool = false


func _ready() -> void:
    theme = DesignSystem.build_theme()
    background.color = DesignSystem.COLOR_CANVAS

    var root_window: Window = get_window()
    root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    root_window.content_scale_factor = 1.0
    root_window.min_size = MIN_WINDOW_SIZE

    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
    top_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE

    gallery_button.pressed.connect(_show_gallery)
    settings_button.pressed.connect(_show_settings)
    about_button.pressed.connect(_show_about)
    project_back_button.pressed.connect(_show_gallery)
    fullscreen_button.pressed.connect(_enter_render_fullscreen)

    project_back_button.text = "< ALL PROJECTS"
    project_back_button.custom_minimum_size = Vector2(118, 24)
    project_back_button.tooltip_text = "Back to Gallery / Esc"
    gallery_button.tooltip_text = "Gallery / all projects / Esc"
    fullscreen_button.tooltip_text = "Fill Creative Lab with render / F11 / Esc to return"

    minimize_button.pressed.connect(_minimize_window)
    maximize_button.pressed.connect(_toggle_maximize_window)
    close_button.pressed.connect(_close_window)
    top_bar.gui_input.connect(_on_top_bar_gui_input)

    fullscreen_texture.texture = sketch_viewport.get_texture()

    _remember_windowed_rect()
    _sync_window_controls()
    _load_catalog()
    _build_gallery()
    _show_gallery()
    call_deferred("_sync_preview_resolution", true)


func _process(_delta: float) -> void:
    var mode: int = DisplayServer.window_get_mode()

    if mode == DisplayServer.WINDOW_MODE_WINDOWED and not _restoring_window:
        _remember_windowed_rect()

    if mode != _last_window_mode:
        _sync_window_controls()

    fps_state.text = "FPS %d" % Engine.get_frames_per_second()
    _sync_gallery_columns()
    _sync_preview_resolution(false)


func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_ESCAPE:
                if _fullscreen_active:
                    _exit_render_fullscreen()
                    get_viewport().set_input_as_handled()
                    return
                if project_view.visible and is_instance_valid(_active_sketch):
                    _show_gallery()
                    get_viewport().set_input_as_handled()
                    return

            if key_event.keycode == KEY_F11 and is_instance_valid(_active_sketch):
                if _fullscreen_active:
                    _exit_render_fullscreen()
                else:
                    _enter_render_fullscreen()
                get_viewport().set_input_as_handled()
                return

    if _fullscreen_active:
        if is_instance_valid(_active_sketch):
            sketch_viewport.push_input(event, true)
        get_viewport().set_input_as_handled()
        return

    if not event is InputEventMouseButton:
        return

    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
    if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
        return

    if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
        return

    var edge: int = _resize_edge_for_position(mouse_event.position)
    if edge == -1:
        return

    DisplayServer.window_start_resize(edge)
    get_viewport().set_input_as_handled()


func _load_catalog() -> void:
    _catalog.clear()

    var directories: PackedStringArray = DirAccess.get_directories_at(SKETCHES_ROOT)
    directories.sort()

    for directory_name: String in directories:
        var definition_path: String = "%s/%s/definition.json" % [SKETCHES_ROOT, directory_name]
        if not FileAccess.file_exists(definition_path):
            continue

        var json_text: String = FileAccess.get_file_as_string(definition_path)
        var parsed: Variant = JSON.parse_string(json_text)
        if not parsed is Dictionary:
            push_warning("Invalid sketch definition: %s" % definition_path)
            continue

        var definition: Dictionary = parsed
        if not definition.has("id") or not definition.has("title") or not definition.has("scene"):
            push_warning("Incomplete sketch definition: %s" % definition_path)
            continue

        _catalog.append(definition)


func _build_gallery() -> void:
    for child: Node in gallery_grid.get_children():
        child.queue_free()

    for definition: Dictionary in _catalog:
        var card: Button = Button.new()
        var index_text: String = str(definition.get("index", "---"))
        var title_text: String = str(definition.get("title", "UNTITLED"))
        var engine_text: String = str(definition.get("engine", "GODOT"))
        var description_text: String = str(definition.get("description", ""))
        var tag_text: String = _definition_tags_text(definition)

        card.custom_minimum_size = Vector2(250, 150)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.focus_mode = Control.FOCUS_NONE
        card.alignment = HORIZONTAL_ALIGNMENT_LEFT
        card.theme_type_variation = &"GalleryCardButton"
        card.text = "%s\n%s\n%s\n%s" % [index_text, title_text, engine_text, tag_text]
        card.tooltip_text = description_text
        card.pressed.connect(_open_sketch.bind(definition))
        gallery_grid.add_child(card)


func _definition_tags_text(definition: Dictionary) -> String:
    var tags_variant: Variant = definition.get("tags", [])
    if not tags_variant is Array:
        return ""

    var tag_parts: PackedStringArray = PackedStringArray()
    var tags: Array = tags_variant
    for tag: Variant in tags:
        tag_parts.append(str(tag))
    return " / ".join(tag_parts)


func _sync_gallery_columns() -> void:
    if not gallery_view.visible:
        return

    var available_width: float = gallery_scroll.size.x
    var columns: int = maxi(1, int(floor(available_width / 270.0)))
    if gallery_grid.columns != columns:
        gallery_grid.columns = columns


func _open_sketch(definition: Dictionary) -> void:
    _unload_active_sketch()

    var scene_path: String = str(definition.get("scene", ""))
    var scene_resource: Resource = load(scene_path)
    if not scene_resource is PackedScene:
        push_error("Cannot load sketch scene: %s" % scene_path)
        status_label.text = "ERROR / SKETCH LOAD FAILED"
        return

    _active_definition = definition.duplicate(true)
    _active_sketch = (scene_resource as PackedScene).instantiate()
    sketch_viewport.add_child(_active_sketch)

    gallery_view.visible = false
    project_view.visible = true
    page_spacer.visible = false

    _set_nav_state(gallery_button)

    var index_text: String = str(definition.get("index", "---"))
    var title_text: String = str(definition.get("title", "UNTITLED"))
    var engine_text: String = str(definition.get("engine", "GODOT"))
    var description_text: String = str(definition.get("description", ""))

    section_index.text = "// %s" % index_text
    page_title.text = title_text
    page_path.text = "res://gallery/%s" % str(definition.get("id", "unknown"))
    page_tag.text = "[LIVE]"
    page_body.text = description_text
    status_label.text = "ACTIVE / %s / ESC=GALLERY / F11=FULLSCREEN" % str(definition.get("id", "unknown")).to_upper()

    project_index.text = index_text
    project_title.text = title_text
    project_meta.text = "%s / %s" % [engine_text, _definition_tags_text(definition)]

    _build_parameter_inspector(_active_sketch)
    call_deferred("_sync_preview_resolution", true)


func _unload_active_sketch() -> void:
    if _fullscreen_active:
        _exit_render_fullscreen()

    if is_instance_valid(_active_sketch):
        sketch_viewport.remove_child(_active_sketch)
        _active_sketch.queue_free()

    _active_sketch = null
    _active_definition.clear()
    _clear_parameter_inspector()


func _build_parameter_inspector(sketch: Node) -> void:
    _clear_parameter_inspector()

    if not sketch.has_method("get_parameter_schema"):
        var no_parameters: Label = Label.new()
        no_parameters.theme_type_variation = &"MicroLabel"
        no_parameters.text = "NO EXPOSED PARAMETERS"
        parameter_list.add_child(no_parameters)
        return

    var schema_variant: Variant = sketch.call("get_parameter_schema")
    if not schema_variant is Array:
        return

    var schema: Array = schema_variant
    for item: Variant in schema:
        if not item is Dictionary:
            continue
        var parameter: Dictionary = item
        _add_parameter_control(parameter)


func _clear_parameter_inspector() -> void:
    for child: Node in parameter_list.get_children():
        child.queue_free()


func _add_parameter_control(parameter: Dictionary) -> void:
    var parameter_id: String = str(parameter.get("id", ""))
    var parameter_label: String = str(parameter.get("label", parameter_id.to_upper()))
    var parameter_type: String = str(parameter.get("type", "float"))

    if parameter_type == "bool":
        var toggle: CheckBox = CheckBox.new()
        toggle.text = parameter_label
        toggle.focus_mode = Control.FOCUS_NONE
        var current_bool: Variant = _active_sketch.call("get_parameter_value", parameter_id)
        toggle.button_pressed = bool(current_bool)
        toggle.toggled.connect(_on_bool_parameter_changed.bind(parameter_id))
        parameter_list.add_child(toggle)
        return

    var block: VBoxContainer = VBoxContainer.new()
    var header: HBoxContainer = HBoxContainer.new()
    var label: Label = Label.new()
    var value_label: Label = Label.new()
    var slider: HSlider = HSlider.new()

    label.theme_type_variation = &"MicroLabel"
    label.text = parameter_label
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    value_label.theme_type_variation = &"AccentLabel"

    slider.min_value = float(parameter.get("min", 0.0))
    slider.max_value = float(parameter.get("max", 1.0))
    slider.step = float(parameter.get("step", 0.01))
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.focus_mode = Control.FOCUS_NONE

    var current_value: Variant = _active_sketch.call("get_parameter_value", parameter_id)
    var numeric_value: float = float(current_value)
    var is_integer: bool = parameter_type == "int"
    slider.value = numeric_value
    value_label.text = _format_numeric_value(numeric_value, is_integer)
    slider.value_changed.connect(_on_numeric_parameter_changed.bind(parameter_id, value_label, is_integer))

    header.add_child(label)
    header.add_child(value_label)
    block.add_child(header)
    block.add_child(slider)
    parameter_list.add_child(block)


func _on_numeric_parameter_changed(value: float, parameter_id: String, value_label: Label, is_integer: bool) -> void:
    if not is_instance_valid(_active_sketch):
        return

    var parameter_value: Variant = int(round(value)) if is_integer else value
    _active_sketch.call("set_parameter_value", parameter_id, parameter_value)
    value_label.text = _format_numeric_value(value, is_integer)


func _on_bool_parameter_changed(enabled: bool, parameter_id: String) -> void:
    if not is_instance_valid(_active_sketch):
        return
    _active_sketch.call("set_parameter_value", parameter_id, enabled)


func _format_numeric_value(value: float, is_integer: bool) -> String:
    if is_integer:
        return str(int(round(value)))
    return "%.2f" % value


func _show_gallery() -> void:
    _unload_active_sketch()
    gallery_view.visible = true
    project_view.visible = false
    page_spacer.visible = false
    _set_nav_state(gallery_button)

    section_index.text = "// 01"
    page_title.text = "GALLERY"
    page_path.text = "res://gallery"
    page_tag.text = "[%03d]" % _catalog.size()
    page_body.text = "SELECT A PATCH. IT LOADS IMMEDIATELY. ESC RETURNS HERE FROM ANY OPEN PROJECT."
    status_label.text = "GALLERY / %d PATCHES / CLICK TO OPEN" % _catalog.size()


func _show_settings() -> void:
    _unload_active_sketch()
    gallery_view.visible = false
    project_view.visible = false
    page_spacer.visible = true
    _set_nav_state(settings_button)

    section_index.text = "// 02"
    page_title.text = "SETTINGS"
    page_path.text = "res://settings"
    page_tag.text = "[SYSTEM]"
    page_body.text = "GLOBAL OUTPUT ADAPTERS, DEFAULT RESOLUTION, FRAME RATE AND APPLICATION PREFERENCES WILL LIVE HERE."
    status_label.text = "SETTINGS / READY"


func _show_about() -> void:
    _unload_active_sketch()
    gallery_view.visible = false
    project_view.visible = false
    page_spacer.visible = true
    _set_nav_state(about_button)

    section_index.text = "// 03"
    page_title.text = "ABOUT"
    page_path.text = "res://about"
    page_tag.text = "[DEV]"
    page_body.text = "DATAC0RE CREATIVE LAB / GODOT 4.7.1 / REALTIME CREATIVE-CODING WORKSTATION."
    status_label.text = "SHELL / ONLINE"


func _set_nav_state(active_button: Button) -> void:
    gallery_button.button_pressed = active_button == gallery_button
    settings_button.button_pressed = active_button == settings_button
    about_button.button_pressed = active_button == about_button


func _enter_render_fullscreen() -> void:
    if not is_instance_valid(_active_sketch) or _fullscreen_active:
        return

    _fullscreen_active = true
    fullscreen_texture.texture = sketch_viewport.get_texture()
    fullscreen_overlay.visible = true
    fullscreen_overlay.grab_focus()
    _last_preview_size = Vector2i.ZERO
    call_deferred("_finish_enter_render_fullscreen")


func _finish_enter_render_fullscreen() -> void:
    await get_tree().process_frame
    if not _fullscreen_active:
        return
    _sync_preview_resolution(true)
    fullscreen_overlay.grab_focus()


func _exit_render_fullscreen() -> void:
    if not _fullscreen_active:
        return

    _fullscreen_active = false
    fullscreen_overlay.visible = false
    _last_preview_size = Vector2i.ZERO
    call_deferred("_finish_exit_render_fullscreen")


func _finish_exit_render_fullscreen() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    _sync_preview_resolution(true)
    get_window().grab_focus()


func _sync_preview_resolution(force: bool = false) -> void:
    if not is_instance_valid(sketch_viewport):
        return

    var target_size: Vector2 = fullscreen_overlay.size if _fullscreen_active else sketch_viewport_container.size
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


func _on_top_bar_gui_input(event: InputEvent) -> void:
    if not event is InputEventMouseButton:
        return

    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
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
    var mode: int = DisplayServer.window_get_mode()

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

    var window_size: Vector2i = DisplayServer.window_get_size()
    if window_size.x < MIN_WINDOW_SIZE.x or window_size.y < MIN_WINDOW_SIZE.y:
        return

    _restore_position = DisplayServer.window_get_position()
    _restore_size = window_size
    _has_restore_rect = true


func _is_expanded_mode(mode: int) -> bool:
    return mode == DisplayServer.WINDOW_MODE_MAXIMIZED \
        or mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
        or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _resize_edge_for_position(position: Vector2) -> int:
    var window_size: Vector2 = Vector2(DisplayServer.window_get_size())

    var left: bool = position.x <= RESIZE_GRAB_PX
    var right: bool = position.x >= window_size.x - RESIZE_GRAB_PX
    var top: bool = position.y <= RESIZE_GRAB_PX
    var bottom: bool = position.y >= window_size.y - RESIZE_GRAB_PX

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
    var expanded: bool = _is_expanded_mode(_last_window_mode)

    maximize_button.text = "▣" if expanded else "□"
    maximize_button.tooltip_text = "Restore" if expanded else "Maximize"
