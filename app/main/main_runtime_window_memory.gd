extends "res://app/main/main_runtime_gallery_compact_review.gd"

# Persist the workstation's native window state and restore it before the first
# rendered frame. The root window stays hidden while mode/screen/rect are applied,
# avoiding the visible 1280x720 -> fullscreen jump seen in host telemetry.

const WINDOW_MEMORY_REVISION: int = 1
const WINDOW_STATE_PATH: String = "user://creative_lab_window_state.cfg"
const WINDOW_STATE_SECTION: String = "window"
const WINDOW_STATE_SETTLE_SECONDS: float = 0.45

var _startup_window_restore_active: bool = true
var _window_state_candidate_key: String = ""
var _window_state_candidate_age: float = 0.0
var _window_state_saved_key: String = ""


func _enter_tree() -> void:
    if DisplayServer.get_name().to_lower() == "headless":
        _startup_window_restore_active = false
        return

    var root_window := get_window()
    root_window.visible = false
    _apply_saved_window_state(_load_saved_window_state())


func _ready() -> void:
    super._ready()
    call_deferred("_finish_startup_window_restore")


# main_runtime_gallery_compact_review calls this during _ready(). Window memory
# has already applied the saved state in _enter_tree(), so the legacy forced
# fullscreen startup must not overwrite a previously saved windowed/maximized state.
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
    root_window.visible = true
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
        "state": state,
        "visible_after_restore": root_window.visible,
    })


func _load_saved_window_state() -> Dictionary:
    var current_screen := DisplayServer.window_get_current_screen()
    var fallback := {
        "mode": "fullscreen",
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

    var state_variant: Variant = config.get_value(WINDOW_STATE_SECTION, "state", fallback)
    if state_variant is Dictionary:
        return (state_variant as Dictionary).duplicate(true)
    return fallback


func _apply_saved_window_state(state: Dictionary) -> void:
    var screen_count := maxi(1, DisplayServer.get_screen_count())
    var screen := clampi(int(state.get("screen", DisplayServer.window_get_current_screen())), 0, screen_count - 1)
    DisplayServer.window_set_current_screen(screen)

    var restore_position := _array_to_vec2i(state.get("restore_position", []), _restore_position)
    var restore_size := _array_to_vec2i(state.get("restore_size", []), _restore_size)
    _restore_position = restore_position
    _restore_size = Vector2i(maxi(MIN_WINDOW_SIZE.x, restore_size.x), maxi(MIN_WINDOW_SIZE.y, restore_size.y))
    _has_restore_rect = bool(state.get("has_restore_rect", false))

    var mode_name := str(state.get("mode", "fullscreen"))
    var position := _array_to_vec2i(state.get("position", []), DisplayServer.window_get_position())
    var size := _array_to_vec2i(state.get("size", []), DisplayServer.window_get_size())
    size.x = maxi(MIN_WINDOW_SIZE.x, size.x)
    size.y = maxi(MIN_WINDOW_SIZE.y, size.y)

    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

    match mode_name:
        "windowed":
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            DisplayServer.window_set_size(size)
            DisplayServer.window_set_position(position)
        "maximized":
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            if _has_restore_rect:
                DisplayServer.window_set_size(_restore_size)
                DisplayServer.window_set_position(_restore_position)
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
        _:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _current_window_state() -> Dictionary:
    var mode := DisplayServer.window_get_mode()
    var mode_name := "windowed"
    if mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
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


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched := data.duplicate(true)
    enriched["window_memory_revision"] = WINDOW_MEMORY_REVISION
    super._telemetry_event(event_name, enriched)
