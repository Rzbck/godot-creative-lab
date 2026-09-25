extends "res://app/main/main_runtime_gallery_compact_review.gd"

# Persist the workstation native window state and apply it as early as Godot
# allows. Revision 3 deliberately does NOT toggle visibility on the main Window:
# Godot 4.7.1 rejects changing visibility of the main window. Applying geometry
# and mode in _enter_tree() is early enough to affect the first rendered scene
# frame without generating the host error seen on Windows.

const WINDOW_MEMORY_REVISION: int = 3
const WINDOW_STATE_PATH: String = "user://creative_lab_window_state.cfg"
const WINDOW_STATE_SECTION: String = "window"
const WINDOW_STATE_SETTLE_SECONDS: float = 0.45
const WINDOW_EXPANDED_GUARD_PX: int = 2

var _startup_window_restore_active: bool = true
var _window_state_candidate_key: String = ""
var _window_state_candidate_age: float = 0.0
var _window_state_saved_key: String = ""
var _workstation_expanded: bool = false


func _enter_tree() -> void:
    if DisplayServer.get_name().to_lower() == "headless":
        _startup_window_restore_active = false
        return

    _apply_saved_window_state(_load_saved_window_state())


func _ready() -> void:
    super._ready()
    call_deferred("_finish_startup_window_restore")


# The saved native state is already applied in _enter_tree(). Do not let the
# legacy startup layer overwrite it with a later fullscreen request.
func _enter_startup_workstation_fullscreen() -> void:
    pass


func _process(delta: float) -> void:
    super._process(delta)
    if _startup_window_restore_active or _fullscreen_active or _presentation_transition or _restoring_window:
        return

    var snapshot := _current_window_state()
    var key := JSON.stringify(snapshot)
    if key != _window_state_candidate_key:
        _window_state_candidate_key = key
        _window_state_candidate_age = 0.0
        return

    _window_state_candidate_age += delta
    if _window_state_candidate_age >= WINDOW_STATE_SETTLE_SECONDS and key != _window_state_saved_key:
        _save_window_state(snapshot)
        _window_state_saved_key = key


func _exit_tree() -> void:
    if DisplayServer.get_name().to_lower() == "headless":
        return
    if not _fullscreen_active and not _presentation_transition:
        _save_window_state(_current_window_state())


func _finish_startup_window_restore() -> void:
    await get_tree().process_frame
    await get_tree().process_frame

    var root_window := get_window()
    root_window.grab_focus()
    _startup_window_restore_active = false
    _sync_window_controls()
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)

    var state := _current_window_state()
    _window_state_saved_key = JSON.stringify(state)
    _window_state_candidate_key = _window_state_saved_key
    _window_state_candidate_age = 0.0
    _save_window_state(state)

    _telemetry_event("workstation_window_state_restored", {
        "window_memory_revision": WINDOW_MEMORY_REVISION,
        "logical_mode": str(state.get("mode", "windowed")),
        "expanded_windowed": _workstation_expanded,
        "state": state,
        "startup_visibility_strategy": "apply_before_first_scene_frame",
    })


func _load_saved_window_state() -> Dictionary:
    var current_screen := DisplayServer.window_get_current_screen()
    var fallback := {
        "mode": "maximized",
        "screen": current_screen,
        "position": [DisplayServer.window_get_position().x, DisplayServer.window_get_position().y],
        "size": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
        "restore_position": [_restore_position.x, _restore_position.y],
        "restore_size": [_restore_size.x, _restore_size.y],
        "has_restore_rect": _has_restore_rect,
    }

    var config := ConfigFile.new()
    if config.load(WINDOW_STATE_PATH) != OK:
        return fallback

    var revision := int(config.get_value(WINDOW_STATE_SECTION, "revision", 1))
    var state_variant: Variant = config.get_value(WINDOW_STATE_SECTION, "state", fallback)
    if not state_variant is Dictionary:
        return fallback

    var state := (state_variant as Dictionary).duplicate(true)
    # Revision 1 had no dedicated workstation-fullscreen control: its saved
    # "fullscreen" state came from the custom maximize button. Migrate that
    # state to the stable borderless expanded window instead of resurrecting the
    # Windows fullscreen/maximize ambiguity seen in host telemetry.
    if revision < 2 and str(state.get("mode", "")) == "fullscreen":
        state["mode"] = "maximized"
    return state


func _apply_saved_window_state(state: Dictionary) -> void:
    var screen_count := maxi(1, DisplayServer.get_screen_count())
    var screen := clampi(int(state.get("screen", DisplayServer.window_get_current_screen())), 0, screen_count - 1)
    DisplayServer.window_set_current_screen(screen)

    var restore_position := _array_to_vec2i(state.get("restore_position", []), _restore_position)
    var restore_size := _array_to_vec2i(state.get("restore_size", []), _restore_size)
    _restore_position = restore_position
    _restore_size = Vector2i(maxi(MIN_WINDOW_SIZE.x, restore_size.x), maxi(MIN_WINDOW_SIZE.y, restore_size.y))
    _has_restore_rect = bool(state.get("has_restore_rect", false))

    var mode_name := str(state.get("mode", "maximized"))
    var position := _array_to_vec2i(state.get("position", []), DisplayServer.window_get_position())
    var size := _array_to_vec2i(state.get("size", []), DisplayServer.window_get_size())
    size.x = maxi(MIN_WINDOW_SIZE.x, size.x)
    size.y = maxi(MIN_WINDOW_SIZE.y, size.y)

    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
    get_window().unresizable = false
    _workstation_expanded = false

    match mode_name:
        "windowed":
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            DisplayServer.window_set_size(size)
            DisplayServer.window_set_position(position)
        "fullscreen":
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        _:
            _workstation_expanded = true
            _apply_expanded_window_rect(screen)


func _apply_expanded_window_rect(screen: int) -> void:
    var usable := DisplayServer.screen_get_usable_rect(screen)
    var expanded_size := usable.size
    # On this Windows/Godot setup, an exact monitor-sized borderless client is
    # reclassified as FULLSCREEN/EXCLUSIVE_FULLSCREEN. Keep a visually invisible
    # 2 px guard on the bottom edge so the workstation remains genuinely windowed.
    expanded_size.y = maxi(MIN_WINDOW_SIZE.y, expanded_size.y - WINDOW_EXPANDED_GUARD_PX)

    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)
    get_window().unresizable = true
    DisplayServer.window_set_position(usable.position)
    DisplayServer.window_set_size(expanded_size)


func _toggle_maximize_window() -> void:
    if _fullscreen_active or _presentation_transition or _restoring_window:
        return

    var mode := DisplayServer.window_get_mode()
    _telemetry_event("window_toggle_maximize", {
        "from_mode": _window_mode_name(mode),
        "logical_expanded": _workstation_expanded,
        "strategy": "windowed_workarea",
    })

    if _workstation_expanded or _is_expanded_mode(mode):
        _workstation_expanded = false
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
        get_window().unresizable = false
        _restore_window()
        return

    if mode == DisplayServer.WINDOW_MODE_WINDOWED:
        _remember_windowed_rect()

    _workstation_expanded = true
    _apply_expanded_window_rect(DisplayServer.window_get_current_screen())
    _sync_window_controls()
    _telemetry_event("window_maximize_requested", {
        "logical_mode": "maximized",
        "actual_mode": _window_mode_name(DisplayServer.window_get_mode()),
        "strategy": "windowed_workarea",
    })


func _restore_window() -> void:
    _workstation_expanded = false
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
    get_window().unresizable = false
    super._restore_window()


func _remember_windowed_rect() -> void:
    if _workstation_expanded:
        return
    super._remember_windowed_rect()


func _is_expanded_mode(mode: int) -> bool:
    return _workstation_expanded or super._is_expanded_mode(mode)


func _current_window_state() -> Dictionary:
    var mode := DisplayServer.window_get_mode()
    var mode_name := "windowed"
    if _workstation_expanded:
        mode_name = "maximized"
    elif mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
        mode_name = "maximized"
    elif mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
        mode_name = "fullscreen"

    var position := DisplayServer.window_get_position()
    var size := DisplayServer.window_get_size()
    return {
        "mode": mode_name,
        "screen": DisplayServer.window_get_current_screen(),
        "position": [position.x, position.y],
        "size": [size.x, size.y],
        "restore_position": [_restore_position.x, _restore_position.y],
        "restore_size": [_restore_size.x, _restore_size.y],
        "has_restore_rect": _has_restore_rect,
    }


func _save_window_state(state: Dictionary) -> void:
    var config := ConfigFile.new()
    config.set_value(WINDOW_STATE_SECTION, "revision", WINDOW_MEMORY_REVISION)
    config.set_value(WINDOW_STATE_SECTION, "state", state)
    config.save(WINDOW_STATE_PATH)


func _array_to_vec2i(value: Variant, fallback: Vector2i) -> Vector2i:
    if value is Array:
        var values := value as Array
        if values.size() >= 2:
            return Vector2i(int(values[0]), int(values[1]))
    return fallback


# Final close publication must see a closed, immutable JSONL file. Flush the
# last record, release the FileAccess handle, then spawn the publisher. This
# avoids the previous race where the close publisher could hash an empty file.
func _close_window() -> void:
    _telemetry_event("session_close_request", {
        "window_memory_revision": WINDOW_MEMORY_REVISION,
        "final_publish_spawned_before_quit": true,
    })
    if _telemetry_file != null:
        _telemetry_file.flush()
        _telemetry_file = null
    _spawn_final_telemetry_publisher()
    get_tree().quit()


func _spawn_final_telemetry_publisher() -> void:
    if OS.get_name() != "Windows":
        return
    if _telemetry_path.is_empty() or not FileAccess.file_exists(_telemetry_path):
        return

    var script_path := ProjectSettings.globalize_path(CHECKPOINT_PUBLISH_SCRIPT)
    var repo_root := ProjectSettings.globalize_path("res://")
    var telemetry_path := ProjectSettings.globalize_path(_telemetry_path)
    var arguments := PackedStringArray([
        "-NoProfile",
        "-WindowStyle", "Hidden",
        "-ExecutionPolicy", "Bypass",
        "-File", script_path,
        "-RepoRoot", repo_root,
        "-TelemetryFile", telemetry_path,
        "-Reason", "session_close_request",
    ])
    var pid := OS.create_process("powershell.exe", arguments)
    if pid <= 0:
        push_warning("Could not start final telemetry publisher before quit.")


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched := data.duplicate(true)
    enriched["window_memory_revision"] = WINDOW_MEMORY_REVISION
    enriched["workstation_expanded"] = _workstation_expanded
    super._telemetry_event(event_name, enriched)
