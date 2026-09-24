extends "res://app/main/main_base.gd"

const WINDOW_APPLY_ATTEMPTS: int = 12
const WINDOW_RECT_TOLERANCE_PX: int = 2
const TELEMETRY_DIR: String = "user://telemetry"
const TELEMETRY_REMOTE_URL_ENV: String = "CREATIVE_LAB_TELEMETRY_URL"
const TELEMETRY_REMOTE_TOKEN_ENV: String = "CREATIVE_LAB_TELEMETRY_TOKEN"

var _presentation_previous_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
var _presentation_previous_position: Vector2i = Vector2i.ZERO
var _presentation_previous_size: Vector2i = Vector2i(1280, 720)
var _presentation_previous_always_on_top: bool = false
var _presentation_previous_unresizable: bool = false
var _presentation_previous_restore_position: Vector2i = Vector2i.ZERO
var _presentation_previous_restore_size: Vector2i = Vector2i(1280, 720)
var _presentation_previous_has_restore_rect: bool = false
var _presentation_screen: int = 0
var _presentation_transition: bool = false

var _telemetry_file: FileAccess = null
var _telemetry_session_id: String = ""
var _telemetry_started_msec: int = 0
var _telemetry_sequence: int = 0
var _telemetry_path: String = ""
var _telemetry_remote_url: String = ""
var _telemetry_remote_token: String = ""
var _telemetry_http: HTTPRequest = null
var _telemetry_remote_queue: Array[String] = []
var _telemetry_remote_busy: bool = false
var _last_rect_telemetry_msec: int = 0


func _create_render_window() -> void:
    pass


func _enter_render_fullscreen() -> void:
    if not is_instance_valid(_active_sketch) or _fullscreen_active or _presentation_transition:
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
    _presentation_screen = root_window.current_screen

    _telemetry_event("presentation_enter_request", {
        "previous_mode": _window_mode_name(_presentation_previous_mode),
        "previous_position": _vec2i_array(_presentation_previous_position),
        "previous_size": _vec2i_array(_presentation_previous_size),
        "saved_restore_position": _vec2i_array(_presentation_previous_restore_position),
        "saved_restore_size": _vec2i_array(_presentation_previous_restore_size),
        "saved_has_restore_rect": _presentation_previous_has_restore_rect,
    })

    _presentation_transition = true
    _restoring_window = true
    _fullscreen_active = true

    fullscreen_texture.texture = sketch_viewport.get_texture()
    fullscreen_overlay.visible = true
    fullscreen_overlay.grab_focus()

    if current_mode != DisplayServer.WINDOW_MODE_WINDOWED:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

    root_window.unresizable = false
    root_window.always_on_top = true
    _last_preview_size = Vector2i.ZERO
    call_deferred("_finish_enter_render_fullscreen")


func _finish_enter_render_fullscreen() -> void:
    var root_window: Window = get_window()
    var target_position: Vector2i = DisplayServer.screen_get_position(_presentation_screen)
    var target_size: Vector2i = DisplayServer.screen_get_size(_presentation_screen)

    await get_tree().process_frame
    await get_tree().process_frame

    for attempt: int in range(WINDOW_APPLY_ATTEMPTS):
        if not _fullscreen_active:
            _presentation_transition = false
            return

        root_window.unresizable = false
        root_window.position = target_position
        root_window.size = target_size
        await get_tree().process_frame

        var matched: bool = _window_rect_matches(root_window.position, root_window.size, target_position, target_size)
        _telemetry_event("presentation_enter_apply", {
            "attempt": attempt + 1,
            "target_position": _vec2i_array(target_position),
            "target_size": _vec2i_array(target_size),
            "matched": matched,
        })
        if matched:
            break

    fullscreen_overlay.grab_focus()
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)
    root_window.grab_focus()
    _presentation_transition = false
    _telemetry_event("presentation_enter_complete")


func _exit_render_fullscreen() -> void:
    if not _fullscreen_active or _presentation_transition:
        return

    _presentation_transition = true
    _telemetry_event("presentation_exit_request", {
        "restore_mode": _window_mode_name(_presentation_previous_mode),
        "restore_position": _vec2i_array(_presentation_previous_position),
        "restore_size": _vec2i_array(_presentation_previous_size),
    })
    call_deferred("_finish_exit_render_fullscreen")


func _finish_exit_render_fullscreen() -> void:
    var root_window: Window = get_window()

    root_window.unresizable = false
    root_window.always_on_top = _presentation_previous_always_on_top

    if _presentation_previous_mode == DisplayServer.WINDOW_MODE_WINDOWED:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        await get_tree().process_frame

        for attempt: int in range(WINDOW_APPLY_ATTEMPTS):
            root_window.unresizable = false
            root_window.size = _presentation_previous_size
            root_window.position = _presentation_previous_position
            await get_tree().process_frame

            var matched: bool = _window_rect_matches(
                root_window.position,
                root_window.size,
                _presentation_previous_position,
                _presentation_previous_size
            )
            _telemetry_event("presentation_exit_apply", {
                "attempt": attempt + 1,
                "target_mode": "windowed",
                "matched": matched,
            })
            if matched:
                break
    else:
        DisplayServer.window_set_mode(_presentation_previous_mode)
        for attempt: int in range(WINDOW_APPLY_ATTEMPTS):
            await get_tree().process_frame
            var mode_matched: bool = DisplayServer.window_get_mode() == _presentation_previous_mode
            _telemetry_event("presentation_exit_mode_apply", {
                "attempt": attempt + 1,
                "target_mode": _window_mode_name(_presentation_previous_mode),
                "matched": mode_matched,
            })
            if mode_matched:
                break

    _restore_position = _presentation_previous_restore_position
    _restore_size = _presentation_previous_restore_size
    _has_restore_rect = _presentation_previous_has_restore_rect

    margin.visible = true
    top_bar.visible = true
    rail.visible = true
    status_bar.visible = true
    gallery_view.visible = false
    project_view.visible = true
    page_spacer.visible = false
    margin.queue_sort()
    project_view.queue_sort()
    await get_tree().process_frame
    await get_tree().process_frame

    _fullscreen_active = false
    fullscreen_overlay.visible = false
    _last_preview_size = Vector2i.ZERO
    _sync_preview_resolution(true)

    root_window.unresizable = _presentation_previous_unresizable
    _sync_window_controls()
    root_window.grab_focus()

    await get_tree().process_frame
    await get_tree().process_frame
    _restoring_window = false
    _presentation_transition = false
    _telemetry_event("presentation_exit_complete")


func _toggle_maximize_window() -> void:
    if _fullscreen_active or _presentation_transition or _restoring_window:
        return

    var mode: int = DisplayServer.window_get_mode()
    _telemetry_event("window_toggle_maximize", {"from_mode": _window_mode_name(mode)})

    if _is_expanded_mode(mode):
        _restore_window()
        return

    if mode == DisplayServer.WINDOW_MODE_WINDOWED:
        _remember_windowed_rect()

    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
    _sync_window_controls()
    _telemetry_event("window_maximize_requested")


func _restore_window() -> void:
    if _fullscreen_active or _presentation_transition or _restoring_window:
        return

    _restoring_window = true
    _telemetry_event("window_restore_request", {
        "target_position": _vec2i_array(_restore_position),
        "target_size": _vec2i_array(_restore_size),
        "has_restore_rect": _has_restore_rect,
    })

    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    call_deferred("_apply_restore_rect")


func _apply_restore_rect() -> void:
    var target_position: Vector2i = _restore_position
    var target_size: Vector2i = _restore_size
    var has_target: bool = _has_restore_rect

    await get_tree().process_frame

    for attempt: int in range(WINDOW_APPLY_ATTEMPTS):
        if has_target:
            DisplayServer.window_set_size(target_size)
            DisplayServer.window_set_position(target_position)

        await get_tree().process_frame

        var mode_ok: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
        var rect_ok: bool = true
        if has_target:
            rect_ok = _window_rect_matches(
                DisplayServer.window_get_position(),
                DisplayServer.window_get_size(),
                target_position,
                target_size
            )

        _telemetry_event("window_restore_apply", {
            "attempt": attempt + 1,
            "mode_ok": mode_ok,
            "rect_ok": rect_ok,
        })

        if mode_ok and rect_ok:
            break

    if has_target:
        _restore_position = target_position
        _restore_size = target_size
        _has_restore_rect = true

    _sync_window_controls()
    await get_tree().process_frame
    await get_tree().process_frame
    _restoring_window = false
    _telemetry_event("window_restore_complete")


func _remember_windowed_rect() -> void:
    if _fullscreen_active or _presentation_transition or _restoring_window:
        return
    if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
        return

    var window_size: Vector2i = DisplayServer.window_get_size()
    if window_size.x < MIN_WINDOW_SIZE.x or window_size.y < MIN_WINDOW_SIZE.y:
        return

    var window_position: Vector2i = DisplayServer.window_get_position()
    var changed: bool = not _has_restore_rect \
        or window_position != _restore_position \
        or window_size != _restore_size

    _restore_position = window_position
    _restore_size = window_size
    _has_restore_rect = true

    if changed:
        var now_msec: int = Time.get_ticks_msec()
        if now_msec - _last_rect_telemetry_msec >= 100:
            _last_rect_telemetry_msec = now_msec
            _telemetry_event("window_restore_rect_updated")


func _minimize_window() -> void:
    if _fullscreen_active or _presentation_transition:
        return
    _telemetry_event("window_minimize_request")
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


func _close_window() -> void:
    _telemetry_event("session_close_request")
    if _telemetry_file != null:
        _telemetry_file.flush()
    get_tree().quit()


func _sync_preview_resolution(force: bool = false) -> void:
    if not is_instance_valid(sketch_viewport):
        return

    var target_size: Vector2
    if _fullscreen_active:
        target_size = fullscreen_overlay.size
    else:
        target_size = sketch_viewport_container.size

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


func _window_rect_matches(
    current_position: Vector2i,
    current_size: Vector2i,
    target_position: Vector2i,
    target_size: Vector2i
) -> bool:
    return abs(current_position.x - target_position.x) <= WINDOW_RECT_TOLERANCE_PX \
        and abs(current_position.y - target_position.y) <= WINDOW_RECT_TOLERANCE_PX \
        and abs(current_size.x - target_size.x) <= WINDOW_RECT_TOLERANCE_PX \
        and abs(current_size.y - target_size.y) <= WINDOW_RECT_TOLERANCE_PX


func _window_mode_name(mode: int) -> String:
    match mode:
        DisplayServer.WINDOW_MODE_WINDOWED:
            return "windowed"
        DisplayServer.WINDOW_MODE_MINIMIZED:
            return "minimized"
        DisplayServer.WINDOW_MODE_MAXIMIZED:
            return "maximized"
        DisplayServer.WINDOW_MODE_FULLSCREEN:
            return "fullscreen"
        DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
            return "exclusive_fullscreen"
        _:
            return "unknown_%d" % mode


func _vec2i_array(value: Vector2i) -> Array[int]:
    return [value.x, value.y]


func _window_telemetry_snapshot() -> Dictionary:
    var root_window: Window = get_window()
    var screen_index: int = root_window.current_screen
    var screen_size: Vector2i = DisplayServer.screen_get_size(screen_index)

    return {
        "mode": _window_mode_name(DisplayServer.window_get_mode()),
        "position": _vec2i_array(root_window.position),
        "size": _vec2i_array(root_window.size),
        "screen": screen_index,
        "screen_size": _vec2i_array(screen_size),
        "restore_position": _vec2i_array(_restore_position),
        "restore_size": _vec2i_array(_restore_size),
        "has_restore_rect": _has_restore_rect,
        "fullscreen_active": _fullscreen_active,
        "presentation_transition": _presentation_transition,
        "restoring_window": _restoring_window,
        "sketch": str(_active_definition.get("id", "")),
    }


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    _ensure_telemetry_started()
    if _telemetry_file == null:
        return

    _telemetry_sequence += 1
    var record: Dictionary = {
        "schema": 1,
        "session": _telemetry_session_id,
        "seq": _telemetry_sequence,
        "elapsed_ms": Time.get_ticks_msec() - _telemetry_started_msec,
        "event": event_name,
        "window": _window_telemetry_snapshot(),
        "data": data.duplicate(true),
    }
    var payload: String = JSON.stringify(record)
    _telemetry_file.store_line(payload)
    _telemetry_file.flush()

    if not _telemetry_remote_url.is_empty():
        _telemetry_remote_queue.append(payload)
        _pump_telemetry_remote()


func _ensure_telemetry_started() -> void:
    if _telemetry_file != null or not _telemetry_session_id.is_empty():
        return

    var root_dir: DirAccess = DirAccess.open("user://")
    if root_dir == null:
        return
    if not root_dir.dir_exists("telemetry"):
        var mkdir_error: int = root_dir.make_dir("telemetry")
        if mkdir_error != OK:
            return

    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.randomize()
    _telemetry_session_id = "%d-%08x" % [int(Time.get_unix_time_from_system()), rng.randi()]
    _telemetry_started_msec = Time.get_ticks_msec()
    _telemetry_path = "%s/session_%s.jsonl" % [TELEMETRY_DIR, _telemetry_session_id]
    _telemetry_file = FileAccess.open(_telemetry_path, FileAccess.WRITE)
    if _telemetry_file == null:
        return

    var latest_marker: FileAccess = FileAccess.open("%s/latest_session.txt" % TELEMETRY_DIR, FileAccess.WRITE)
    if latest_marker != null:
        latest_marker.store_string(_telemetry_path)
        latest_marker.close()

    _telemetry_remote_url = OS.get_environment(TELEMETRY_REMOTE_URL_ENV).strip_edges()
    _telemetry_remote_token = OS.get_environment(TELEMETRY_REMOTE_TOKEN_ENV).strip_edges()
    if not _telemetry_remote_url.is_empty():
        _telemetry_http = HTTPRequest.new()
        _telemetry_http.name = "TelemetryHttp"
        add_child(_telemetry_http)
        _telemetry_http.request_completed.connect(_on_telemetry_request_completed)

    var start_record: Dictionary = {
        "schema": 1,
        "session": _telemetry_session_id,
        "seq": 0,
        "elapsed_ms": 0,
        "event": "session_start",
        "window": _window_telemetry_snapshot(),
        "data": {
            "godot": str(Engine.get_version_info().get("string", "")),
            "os": OS.get_name(),
            "remote_enabled": not _telemetry_remote_url.is_empty(),
        },
    }
    var start_payload: String = JSON.stringify(start_record)
    _telemetry_file.store_line(start_payload)
    _telemetry_file.flush()
    print("CREATIVE_LAB_TELEMETRY ", _telemetry_path)

    if not _telemetry_remote_url.is_empty():
        _telemetry_remote_queue.append(start_payload)
        _pump_telemetry_remote()


func _pump_telemetry_remote() -> void:
    if _telemetry_remote_busy or _telemetry_http == null or _telemetry_remote_queue.is_empty():
        return

    var payload: String = _telemetry_remote_queue.pop_front()
    var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json"])
    if not _telemetry_remote_token.is_empty():
        headers.append("Authorization: Bearer %s" % _telemetry_remote_token)

    _telemetry_remote_busy = true
    var request_error: int = _telemetry_http.request(
        _telemetry_remote_url,
        headers,
        HTTPClient.METHOD_POST,
        payload
    )
    if request_error != OK:
        _telemetry_remote_busy = false
        _telemetry_remote_url = ""
        push_warning("Remote telemetry disabled after request error %d; local JSONL remains active." % request_error)


func _on_telemetry_request_completed(
    _result: int,
    response_code: int,
    _headers: PackedStringArray,
    _body: PackedByteArray
) -> void:
    _telemetry_remote_busy = false
    if response_code < 200 or response_code >= 300:
        _telemetry_remote_url = ""
        push_warning("Remote telemetry disabled after HTTP %d; local JSONL remains active." % response_code)
        return
    call_deferred("_pump_telemetry_remote")


func _exit_tree() -> void:
    if _telemetry_file != null:
        _telemetry_file.flush()
        _telemetry_file.close()
        _telemetry_file = null
