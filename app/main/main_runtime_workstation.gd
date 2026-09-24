extends "res://app/main/main_runtime_output_window.gd"

# Workstation integration layer.
# - keeps the project preview responsive while the root window is resized,
# - exposes the presentation monitor in Settings,
# - and publishes a settled resize diagnostic so the exact broken layout can be
#   inspected remotely without waiting for the application to close.

const WORKSTATION_DIAGNOSTIC_REVISION: int = 9
const SETTINGS_PATH: String = "user://creative_lab_settings.cfg"
const RESPONSIVE_PREVIEW_MIN_SIZE: Vector2 = Vector2(320.0, 180.0)
const RESIZE_SETTLE_MSEC: int = 350
const OUTPUT_STABILIZE_FRAMES: int = 4

var _output_screen_preference: int = -1
var _settings_root: VBoxContainer = null
var _screen_selector: OptionButton = null

var _geometry_initialized: bool = false
var _last_geometry_position: Vector2i = Vector2i.ZERO
var _last_geometry_size: Vector2i = Vector2i.ZERO
var _resize_active: bool = false
var _resize_start_position: Vector2i = Vector2i.ZERO
var _resize_start_size: Vector2i = Vector2i.ZERO
var _resize_last_change_msec: int = 0
var _resize_change_count: int = 0
var _output_generation: int = 0


func _ready() -> void:
    super._ready()

    # With stretch disabled, the SubViewport's current pixel size becomes layout
    # pressure. After a large window, that prevents the HBox from shrinking and
    # makes the whole shell slide into negative coordinates. The output window
    # no longer needs the root viewport to become fullscreen-sized, so the
    # preview can safely follow its container instead of driving its minimum.
    sketch_viewport_container.stretch = true
    sketch_viewport_container.custom_minimum_size = RESPONSIVE_PREVIEW_MIN_SIZE

    _load_workstation_settings()
    _initialize_geometry_observer()
    call_deferred("_apply_responsive_layout")

    _telemetry_event("workstation_runtime_ready", {
        "workstation_revision": WORKSTATION_DIAGNOSTIC_REVISION,
        "responsive": _responsive_layout_snapshot(),
        "output_screen_preference": _output_screen_preference,
        "resolved_output_screen": _resolve_output_screen(),
    })


func _process(delta: float) -> void:
    super._process(delta)
    _apply_responsive_layout()
    _observe_window_geometry()


func _show_settings() -> void:
    super._show_settings()
    _ensure_settings_ui()
    _refresh_screen_selector()
    if is_instance_valid(_settings_root):
        _settings_root.visible = true

    page_body.text = "PRESENTATION OUTPUT, DISPLAY ROUTING AND APPLICATION PREFERENCES."
    status_label.text = "SETTINGS / OUTPUT DISPLAY READY"


func _show_gallery() -> void:
    _hide_runtime_settings_ui()
    super._show_gallery()


func _show_about() -> void:
    _hide_runtime_settings_ui()
    super._show_about()


func _open_sketch(definition: Dictionary) -> void:
    _hide_runtime_settings_ui()
    super._open_sketch(definition)


func _sync_preview_resolution(force: bool = false) -> void:
    # The container owns layout. The SubViewport follows it, never the reverse.
    sketch_viewport_container.custom_minimum_size = RESPONSIVE_PREVIEW_MIN_SIZE
    super._sync_preview_resolution(force)


func _apply_responsive_layout() -> void:
    if not is_instance_valid(sketch_viewport_container):
        return

    sketch_viewport_container.stretch = true
    sketch_viewport_container.custom_minimum_size = RESPONSIVE_PREVIEW_MIN_SIZE

    # Keep nonessential toolbar metadata from establishing an oversized minimum
    # width when the user deliberately makes the workstation narrow.
    var root_width: float = float(get_window().size.x)
    if is_instance_valid(project_meta):
        project_meta.visible = root_width >= 1080.0
    if is_instance_valid(preview_resolution):
        preview_resolution.visible = root_width >= 900.0


func _initialize_geometry_observer() -> void:
    _last_geometry_position = DisplayServer.window_get_position()
    _last_geometry_size = DisplayServer.window_get_size()
    _geometry_initialized = true


func _observe_window_geometry() -> void:
    if not _geometry_initialized:
        _initialize_geometry_observer()
        return

    if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED \
    or _fullscreen_active \
    or _presentation_transition \
    or _restoring_window:
        _last_geometry_position = DisplayServer.window_get_position()
        _last_geometry_size = DisplayServer.window_get_size()
        return

    var now_msec: int = Time.get_ticks_msec()
    var current_position: Vector2i = DisplayServer.window_get_position()
    var current_size: Vector2i = DisplayServer.window_get_size()
    var position_changed: bool = current_position != _last_geometry_position
    var size_changed: bool = current_size != _last_geometry_size

    if position_changed or size_changed:
        if size_changed and not _resize_active:
            _resize_active = true
            _resize_start_position = _last_geometry_position
            _resize_start_size = _last_geometry_size
            _resize_change_count = 0
            _telemetry_event("window_resize_begin", {
                "start_position": _vec2i_array(_resize_start_position),
                "start_size": _vec2i_array(_resize_start_size),
                "responsive": _responsive_layout_snapshot(),
            })

        if size_changed:
            _resize_change_count += 1
            _resize_last_change_msec = now_msec

        _telemetry_event("window_geometry_change", {
            "position_changed": position_changed,
            "size_changed": size_changed,
            "previous_position": _vec2i_array(_last_geometry_position),
            "previous_size": _vec2i_array(_last_geometry_size),
            "current_position": _vec2i_array(current_position),
            "current_size": _vec2i_array(current_size),
            "resize_change_count": _resize_change_count,
            "responsive": _responsive_layout_snapshot(),
        })

        _last_geometry_position = current_position
        _last_geometry_size = current_size
        return

    if _resize_active and now_msec - _resize_last_change_msec >= RESIZE_SETTLE_MSEC:
        _resize_active = false
        _telemetry_event("window_resize_settled", {
            "start_position": _vec2i_array(_resize_start_position),
            "start_size": _vec2i_array(_resize_start_size),
            "final_position": _vec2i_array(current_position),
            "final_size": _vec2i_array(current_size),
            "resize_change_count": _resize_change_count,
            "responsive": _responsive_layout_snapshot(),
        })
        _publish_telemetry_to_github("window_resize_settled")


func _responsive_layout_snapshot() -> Dictionary:
    var root_size: Vector2i = get_window().size
    var margin_min: Vector2 = margin.get_combined_minimum_size()
    var project_min: Vector2 = project_view.get_combined_minimum_size()
    var preview_min: Vector2 = sketch_viewport_container.get_combined_minimum_size()

    return {
        "root_size": _vec2i_array(root_size),
        "margin_min": _vec2_array(margin_min),
        "project_min": _vec2_array(project_min),
        "preview_min": _vec2_array(preview_min),
        "preview_size": _vec2_array(sketch_viewport_container.size),
        "viewport_size": _vec2i_array(sketch_viewport.size),
        "viewport_container_stretch": sketch_viewport_container.stretch,
        "margin_overflow_x": margin_min.x > float(root_size.x) + 0.5,
        "margin_overflow_y": margin_min.y > float(root_size.y) + 0.5,
        "project_overflow_x": project_view.visible and project_min.x > float(root_size.x) + 0.5,
        "project_overflow_y": project_view.visible and project_min.y > float(root_size.y) + 0.5,
    }


func _ensure_settings_ui() -> void:
    if is_instance_valid(_settings_root):
        return

    var root: VBoxContainer = VBoxContainer.new()
    root.name = "RuntimeSettings"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 10)
    page_spacer.add_child(root)
    _settings_root = root

    var title: Label = Label.new()
    title.theme_type_variation = &"AccentLabel"
    title.text = "PRESENTATION OUTPUT"
    root.add_child(title)

    var separator: HSeparator = HSeparator.new()
    root.add_child(separator)

    var row: HBoxContainer = HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(row)

    var label: Label = Label.new()
    label.theme_type_variation = &"MicroLabel"
    label.text = "FULLSCREEN DISPLAY"
    label.custom_minimum_size = Vector2(180.0, 0.0)
    row.add_child(label)

    var selector: OptionButton = OptionButton.new()
    selector.name = "OutputScreenSelector"
    selector.custom_minimum_size = Vector2(360.0, 30.0)
    selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    selector.item_selected.connect(_on_output_screen_selected)
    row.add_child(selector)
    _screen_selector = selector

    var hint: Label = Label.new()
    hint.theme_type_variation = &"MicroLabel"
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.text = "SAME AS APP follows the monitor containing the workstation. Explicit SCREEN entries stay pinned to that monitor."
    root.add_child(hint)

    var telemetry_title: Label = Label.new()
    telemetry_title.theme_type_variation = &"AccentLabel"
    telemetry_title.text = "DIAGNOSTICS"
    root.add_child(telemetry_title)

    var telemetry_hint: Label = Label.new()
    telemetry_hint.theme_type_variation = &"MicroLabel"
    telemetry_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    telemetry_hint.text = "Window resize begin/change/settled events include layout minimums and overflow flags. Settled resize sessions are published to telemetry/runtime/latest.jsonl."
    root.add_child(telemetry_hint)

    var spacer: Control = Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer)


func _hide_runtime_settings_ui() -> void:
    if is_instance_valid(_settings_root):
        _settings_root.visible = false


func _refresh_screen_selector() -> void:
    if not is_instance_valid(_screen_selector):
        return

    _screen_selector.clear()
    var app_screen: int = get_window().current_screen
    var app_size: Vector2i = DisplayServer.screen_get_size(app_screen)
    _screen_selector.add_item(
        "SAME AS APP / SCREEN %d / %d×%d" % [app_screen + 1, app_size.x, app_size.y]
    )
    _screen_selector.set_item_metadata(0, -1)

    var screen_count: int = DisplayServer.get_screen_count()
    for screen_index: int in range(screen_count):
        var screen_size: Vector2i = DisplayServer.screen_get_size(screen_index)
        var screen_position: Vector2i = DisplayServer.screen_get_position(screen_index)
        var item_index: int = _screen_selector.item_count
        _screen_selector.add_item(
            "SCREEN %d / %d×%d / %d,%d" % [
                screen_index + 1,
                screen_size.x,
                screen_size.y,
                screen_position.x,
                screen_position.y,
            ]
        )
        _screen_selector.set_item_metadata(item_index, screen_index)

    var selected_item: int = 0
    if _output_screen_preference >= 0:
        for item_index: int in range(_screen_selector.item_count):
            if int(_screen_selector.get_item_metadata(item_index)) == _output_screen_preference:
                selected_item = item_index
                break
    _screen_selector.select(selected_item)


func _on_output_screen_selected(item_index: int) -> void:
    if not is_instance_valid(_screen_selector):
        return

    _output_screen_preference = int(_screen_selector.get_item_metadata(item_index))
    _save_workstation_settings()
    var resolved_screen: int = _resolve_output_screen()
    var resolved_size: Vector2i = DisplayServer.screen_get_size(resolved_screen)
    status_label.text = "SETTINGS / OUTPUT SCREEN %d / %d×%d" % [
        resolved_screen + 1,
        resolved_size.x,
        resolved_size.y,
    ]
    _telemetry_event("output_screen_preference_changed", {
        "preference": _output_screen_preference,
        "resolved_screen": resolved_screen,
        "resolved_size": _vec2i_array(resolved_size),
    })
    _publish_telemetry_to_github("output_screen_preference_changed")


func _load_workstation_settings() -> void:
    var config: ConfigFile = ConfigFile.new()
    if config.load(SETTINGS_PATH) != OK:
        _output_screen_preference = -1
        return

    _output_screen_preference = int(config.get_value("output", "screen", -1))
    if _output_screen_preference >= DisplayServer.get_screen_count():
        _output_screen_preference = -1


func _save_workstation_settings() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("output", "screen", _output_screen_preference)
    config.save(SETTINGS_PATH)


func _resolve_output_screen() -> int:
    var screen_count: int = maxi(1, DisplayServer.get_screen_count())
    if _output_screen_preference >= 0 and _output_screen_preference < screen_count:
        return _output_screen_preference
    return clampi(get_window().current_screen, 0, screen_count - 1)


func _enter_render_fullscreen() -> void:
    if not is_instance_valid(_active_sketch) or _fullscreen_active or _presentation_transition:
        return

    _ensure_presentation_output()
    if not is_instance_valid(_presentation_output) or not is_instance_valid(_presentation_output_texture):
        push_error("Presentation output window could not be created.")
        return

    var root_window: Window = get_window()
    var current_mode: int = DisplayServer.window_get_mode()

    if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
        _remember_windowed_rect()

    _presentation_previous_mode = current_mode
    _presentation_previous_position = root_window.position
    _presentation_previous_size = root_window.size
    _presentation_previous_always_on_top = root_window.always_on_top
    _presentation_previous_unresizable = root_window.unresizable
    _presentation_previous_restore_position = _restore_position
    _presentation_previous_restore_size = _restore_size
    _presentation_previous_has_restore_rect = _has_restore_rect
    _presentation_screen = _resolve_output_screen()

    _presentation_transition = true
    _restoring_window = true
    _fullscreen_active = true
    _output_generation += 1

    var generation: int = _output_generation
    var target_position: Vector2i = DisplayServer.screen_get_position(_presentation_screen)
    var target_size: Vector2i = DisplayServer.screen_get_size(_presentation_screen)

    fullscreen_overlay.visible = false
    _presentation_output_texture.texture = sketch_viewport.get_texture()

    # Do not ask Windows to choose a fullscreen monitor. A native borderless
    # window is positioned directly on the selected physical screen instead.
    # This keeps monitor routing deterministic and preserves the instant hide on
    # Esc that fixed the previous transition artifact.
    _presentation_output.hide()
    _presentation_output.mode = Window.MODE_WINDOWED
    _presentation_output.current_screen = _presentation_screen
    _presentation_output.position = target_position
    _presentation_output.size = target_size
    _presentation_output.borderless = true
    _presentation_output.unresizable = true
    _presentation_output.always_on_top = true

    _telemetry_event("presentation_enter_request", {
        "workstation_revision": WORKSTATION_DIAGNOSTIC_REVISION,
        "root_unchanged": _root_window_matches_entry_state(),
        "selected_screen": _presentation_screen,
        "screen_preference": _output_screen_preference,
        "target_position": _vec2i_array(target_position),
        "target_size": _vec2i_array(target_size),
        "output": _presentation_output_snapshot(),
    })

    _presentation_output.show()
    # Reassert in the same frame after native creation so Windows never gets a
    # chance to keep the default monitor geometry chosen during show().
    _presentation_output.mode = Window.MODE_WINDOWED
    _presentation_output.position = target_position
    _presentation_output.size = target_size
    _presentation_output.always_on_top = true
    _presentation_output.grab_focus()

    _presentation_transition = false

    _telemetry_event("presentation_output_visible", {
        "workstation_revision": WORKSTATION_DIAGNOSTIC_REVISION,
        "root_unchanged": _root_window_matches_entry_state(),
        "selected_screen": _presentation_screen,
        "target_position": _vec2i_array(target_position),
        "target_size": _vec2i_array(target_size),
        "output": _presentation_output_snapshot(),
    })
    _telemetry_event("presentation_enter_complete", {
        "workstation_revision": WORKSTATION_DIAGNOSTIC_REVISION,
        "root_unchanged": _root_window_matches_entry_state(),
        "selected_screen": _presentation_screen,
        "target_position": _vec2i_array(target_position),
        "target_size": _vec2i_array(target_size),
        "output": _presentation_output_snapshot(),
    })

    call_deferred(
        "_stabilize_presentation_output",
        generation,
        _presentation_screen,
        target_position,
        target_size
    )


func _stabilize_presentation_output(
    generation: int,
    target_screen: int,
    target_position: Vector2i,
    target_size: Vector2i
) -> void:
    for frame_index: int in range(OUTPUT_STABILIZE_FRAMES):
        await get_tree().process_frame
        if generation != _output_generation or not _fullscreen_active:
            return
        if not is_instance_valid(_presentation_output):
            return

        _presentation_output.mode = Window.MODE_WINDOWED
        _presentation_output.position = target_position
        _presentation_output.size = target_size
        _presentation_output.always_on_top = true

        var matched: bool = _presentation_output.position == target_position \
            and _presentation_output.size == target_size
        _telemetry_event("presentation_output_stabilize", {
            "attempt": frame_index + 1,
            "selected_screen": target_screen,
            "target_position": _vec2i_array(target_position),
            "target_size": _vec2i_array(target_size),
            "matched": matched,
            "output": _presentation_output_snapshot(),
        })


func _exit_render_fullscreen() -> void:
    _output_generation += 1
    super._exit_render_fullscreen()


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched: Dictionary = data.duplicate(true)
    enriched["workstation_revision"] = WORKSTATION_DIAGNOSTIC_REVISION
    enriched["output_screen_preference"] = _output_screen_preference
    enriched["resolved_output_screen"] = _resolve_output_screen()
    if not enriched.has("responsive"):
        enriched["responsive"] = _responsive_layout_snapshot()
    super._telemetry_event(event_name, enriched)
