extends "res://app/main/main.gd"

const WORKSPACE_TELEMETRY_DIR: String = "res://.telemetry_runtime"
const TELEMETRY_PUBLISH_SCRIPT: String = "res://scripts/publish-telemetry.ps1"
const TELEMETRY_PUBLISH_EVENTS: Dictionary = {
    "presentation_exit_complete": true,
    "window_restore_complete": true,
    "session_close_request": true,
}


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
    # Other Godot user data is left untouched.
    var legacy_dir: DirAccess = DirAccess.open("user://telemetry")
    if legacy_dir == null:
        return

    for file_name: String in legacy_dir.get_files():
        legacy_dir.remove(file_name)

    for directory_name: String in legacy_dir.get_directories():
        _remove_legacy_directory("user://telemetry/%s" % directory_name)

    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://telemetry"))
    print("CREATIVE_LAB_TELEMETRY legacy user://telemetry removed")


func _remove_legacy_directory(path: String) -> void:
    var directory: DirAccess = DirAccess.open(path)
    if directory == null:
        return

    for file_name: String in directory.get_files():
        directory.remove(file_name)
    for directory_name: String in directory.get_directories():
        _remove_legacy_directory("%s/%s" % [path, directory_name])

    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
