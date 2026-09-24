extends "res://app/main/main.gd"

const WORKSPACE_TELEMETRY_DIR: String = "res://.telemetry_runtime"
const TELEMETRY_PUBLISH_SCRIPT: String = "res://scripts/publish-telemetry.ps1"
const TELEMETRY_PUBLISH_EVENTS: Dictionary = {
    "presentation_exit_complete": true,
    "window_restore_complete": true,
    "session_close_request": true,
}
const WINDOW_MODE_RELEASE_ATTEMPTS: int = 24


func _ensure_telemetry_started() -> void:
    # Headless CI must never create runtime files in the checkout.
    if DisplayServer.get_name() == "headless":
        return
    if _telemetry_file != null or not _telemetry_session_id.is_empty():
        return

    _cleanup_legacy_user_telemetry()

    var project_dir: DirAccess = DirAccess.open("res://")
    if project_dir == null:
        return
    if not project_dir.dir_exists(".telemetry_runtime"):
        var mkdir_error: int = project_dir.make_dir(".telemetry_runtime")
        if mkdir_error != OK:
            return

    # Keep the workstation clean: only the current local session is retained.
    var runtime_dir: DirAccess = DirAccess.open(WORKSPACE_TELEMETRY_DIR)
    if runtime_dir != null:
        for file_name: String in runtime_dir.get_files():
            if file_name.ends_with(".jsonl") or file_name == "publish-status.json":
                runtime_dir.remove(file_name)

    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.randomize()
    _telemetry_session_id = "%d-%08x" % [int(Time.get_unix_time_from_system()), rng.randi()]
    _telemetry_started_msec = Time.get_ticks_msec()
    _telemetry_path = "%s/session_%s.jsonl" % [WORKSPACE_TELEMETRY_DIR, _telemetry_session_id]
    _telemetry_file = FileAccess.open(_telemetry_path, FileAccess.WRITE)
    if _telemetry_file == null:
        return

    # The public telemetry branch receives sanitized geometry/state only.
    # No username, machine name, IP, absolute path or account identifier is recorded.
    _telemetry_remote_url = ""
    _telemetry_remote_token = ""

    var start_record: Dictionary = {
        "schema": 3,
        "session": _telemetry_session_id,
        "seq": 0,
        "elapsed_ms": 0,
        "event": "session_start",
        "window": _window_telemetry_snapshot(),
        "data": {
            "godot": str(Engine.get_version_info().get("string", "")),
            "os": OS.get_name(),
            "layout": _layout_telemetry_snapshot(),
        },
    }
    _telemetry_file.store_line(JSON.stringify(start_record))
    _telemetry_file.flush()

    print("CREATIVE_LAB_TELEMETRY ", _telemetry_path)
    print("CREATIVE_LAB_TELEMETRY_GITHUB telemetry/runtime -> latest.jsonl")


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    _ensure_telemetry_started()
    if _telemetry_file == null:
        return

    _telemetry_sequence += 1
    var record: Dictionary = {
        "schema": 3,
        "session": _telemetry_session_id,
        "seq": _telemetry_sequence,
        "elapsed_ms": Time.get_ticks_msec() - _telemetry_started_msec,
        "event": event_name,
        "window": _window_telemetry_snapshot(),
        "data": data.duplicate(true),
    }
    _telemetry_file.store_line(JSON.stringify(record))
    _telemetry_file.flush()

    if TELEMETRY_PUBLISH_EVENTS.has(event_name):
        call_deferred("_publish_telemetry_to_github", event_name)


func _publish_telemetry_to_github(reason: String) -> void:
    if OS.get_name() != "Windows":
        return
    if _telemetry_path.is_empty() or not FileAccess.file_exists(_telemetry_path):
        return

    if _telemetry_file != null:
        _telemetry_file.flush()

    var script_path: String = ProjectSettings.globalize_path(TELEMETRY_PUBLISH_SCRIPT)
    var telemetry_path: String = ProjectSettings.globalize_path(_telemetry_path)
    var repo_root: String = ProjectSettings.globalize_path("res://")

    var arguments: PackedStringArray = PackedStringArray([
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", script_path,
        "-RepoRoot", repo_root,
        "-TelemetryFile", telemetry_path,
        "-Reason", reason,
    ])

    var pid: int = OS.create_process("powershell.exe", arguments)
    if pid <= 0:
        push_warning("Telemetry GitHub publisher could not start; local workspace telemetry remains available.")
        return

    print("CREATIVE_LAB_TELEMETRY_PUBLISH pid=", pid, " reason=", reason)


func _cleanup_legacy_user_telemetry() -> void:
    # Remove only the telemetry folder created by the previous implementation.
    # Other Godot user data is left untouched. Locked leftovers are reported and
    # retried on the next launch instead of pretending cleanup succeeded.
    var legacy_path: String = "user://telemetry"
    var legacy_dir: DirAccess = DirAccess.open(legacy_path)
    if legacy_dir == null:
        return

    var clean: bool = true
    for file_name: String in legacy_dir.get_files():
        var remove_error: int = legacy_dir.remove(file_name)
        if remove_error != OK:
            clean = false

    for directory_name: String in legacy_dir.get_directories():
        if not _remove_legacy_directory("%s/%s" % [legacy_path, directory_name]):
            clean = false

    if clean:
        var dir_error: int = DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))
        clean = dir_error == OK

    if clean:
        print("CREATIVE_LAB_TELEMETRY legacy user://telemetry removed")
    else:
        push_warning("Legacy user://telemetry still contains a locked file; cleanup will retry next launch.")


func _remove_legacy_directory(path: String) -> bool:
    var directory: DirAccess = DirAccess.open(path)
    if directory == null:
        return true

    var clean: bool = true
    for file_name: String in directory.get_files():
        if directory.remove(file_name) != OK:
            clean = false
    for directory_name: String in directory.get_directories():
        if not _remove_legacy_directory("%s/%s" % [path, directory_name]):
            clean = false

    if clean:
        clean = DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
    return clean


func _finish_exit_render_fullscreen() -> void:
    var root_window: Window = get_window()

    # Telemetry from the broken session proved that Windows/Godot could keep the
    # root window in EXCLUSIVE_FULLSCREEN even after its 1280x720 rect had been
    # restored. Never rebuild the UI until both mode AND geometry are confirmed.
    margin.visible = false
    fullscreen_overlay.visible = true
    root_window.unresizable = false
    root_window.always_on_top = _presentation_previous_always_on_top

    var restore_position: Vector2i = _presentation_previous_position
    var restore_size: Vector2i = _presentation_previous_size
    if _presentation_previous_has_restore_rect:
        restore_position = _presentation_previous_restore_position
        restore_size = _presentation_previous_restore_size

    var windowed_ok: bool = await _force_windowed_rect(
        restore_position,
        restore_size,
        "presentation_exit_apply"
    )

    if not windowed_ok:
        _telemetry_event("presentation_exit_mode_release_failed", {
            "target_mode": "windowed",
            "target_position": _vec2i_array(restore_position),
            "target_size": _vec2i_array(restore_size),
        })

    if _presentation_previous_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
        for attempt: int in range(WINDOW_MODE_RELEASE_ATTEMPTS):
            await get_tree().process_frame
            var maximized_ok: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED
            _telemetry_event("presentation_exit_restore_mode_apply", {
                "attempt": attempt + 1,
                "target_mode": "maximized",
                "matched": maximized_ok,
            })
            if maximized_ok:
                break

    _restore_position = _presentation_previous_restore_position
    _restore_size = _presentation_previous_restore_size
    _has_restore_rect = _presentation_previous_has_restore_rect

    _telemetry_event("presentation_exit_native_restored", {"layout": _layout_telemetry_snapshot()})

    _force_root_full_rect()
    _force_workstation_layout()
    await get_tree().process_frame
    await get_tree().process_frame

    margin.visible = true
    top_bar.visible = true
    rail.visible = true
    status_bar.visible = true
    gallery_view.visible = false
    project_view.visible = true
    page_spacer.visible = false

    _force_root_full_rect()
    _force_workstation_layout()
    await get_tree().process_frame
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
    _telemetry_event("presentation_exit_complete", {"layout": _layout_telemetry_snapshot()})


func _apply_restore_rect() -> void:
    var target_position: Vector2i = _restore_position
    var target_size: Vector2i = _restore_size
    var has_target: bool = _has_restore_rect

    var restore_ok: bool = true
    if has_target:
        restore_ok = await _force_windowed_rect(
            target_position,
            target_size,
            "window_restore_apply"
        )
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        for attempt: int in range(WINDOW_MODE_RELEASE_ATTEMPTS):
            await get_tree().process_frame
            var mode_ok: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
            _telemetry_event("window_restore_apply", {
                "attempt": attempt + 1,
                "mode_ok": mode_ok,
                "rect_ok": true,
                "matched": mode_ok,
            })
            if mode_ok:
                break

    if has_target:
        _restore_position = target_position
        _restore_size = target_size
        _has_restore_rect = true

    _force_root_full_rect()
    _force_workstation_layout()
    _sync_window_controls()
    await get_tree().process_frame
    await get_tree().process_frame
    _restoring_window = false
    _telemetry_event("window_restore_complete", {
        "matched": restore_ok,
        "layout": _layout_telemetry_snapshot(),
    })


func _force_windowed_rect(
    target_position: Vector2i,
    target_size: Vector2i,
    telemetry_event_name: String
) -> bool:
    var root_window: Window = get_window()

    # Important ordering for Windows: while the OS still considers the borderless
    # monitor-sized window fullscreen, changing only the rect is not enough. Each
    # iteration therefore applies the smaller rect and requests WINDOWED again.
    for attempt: int in range(WINDOW_MODE_RELEASE_ATTEMPTS):
        root_window.unresizable = false
        root_window.size = target_size
        root_window.position = target_position
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
        await get_tree().process_frame

        var mode_ok: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
        var rect_ok: bool = _window_rect_matches(
            root_window.position,
            root_window.size,
            target_position,
            target_size
        )
        var matched: bool = mode_ok and rect_ok

        _telemetry_event(telemetry_event_name, {
            "attempt": attempt + 1,
            "target_mode": "windowed",
            "target_position": _vec2i_array(target_position),
            "target_size": _vec2i_array(target_size),
            "mode_ok": mode_ok,
            "rect_ok": rect_ok,
            "matched": matched,
        })

        if matched:
            # Reapply once after the mode switch because Windows can adjust the
            # client rect on the transition frame.
            root_window.size = target_size
            root_window.position = target_position
            await get_tree().process_frame
            await get_tree().process_frame
            if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED \
            and _window_rect_matches(root_window.position, root_window.size, target_position, target_size):
                return true

    # Last-resort transition path: leave fullscreen through MAXIMIZED, then retry
    # WINDOWED. The fullscreen overlay remains visible, so this should not expose
    # a malformed workstation layout to the user.
    _telemetry_event("window_mode_release_fallback", {
        "target_mode": "windowed",
        "target_position": _vec2i_array(target_position),
        "target_size": _vec2i_array(target_size),
    })
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
    await get_tree().process_frame
    await get_tree().process_frame

    for attempt: int in range(WINDOW_MODE_RELEASE_ATTEMPTS):
        root_window.unresizable = false
        root_window.size = target_size
        root_window.position = target_position
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        await get_tree().process_frame

        var mode_ok: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
        var rect_ok: bool = _window_rect_matches(
            root_window.position,
            root_window.size,
            target_position,
            target_size
        )
        if mode_ok and rect_ok:
            return true

    return false
