extends "res://app/main/main_runtime.gd"

# Runtime telemetry publication must be deterministic on Windows. The previous
# implementation launched the publisher asynchronously while Godot still held
# the JSONL file open, so GitHub could remain on an older session with no usable
# completion signal. This layer closes the live file, publishes synchronously,
# then reopens it in append position before the application continues.


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
        _publish_telemetry_to_github(event_name)


func _publish_telemetry_to_github(reason: String) -> void:
    if OS.get_name() != "Windows":
        return
    if _telemetry_path.is_empty() or not FileAccess.file_exists(_telemetry_path):
        return

    # Release the Windows file handle before PowerShell tries to read the JSONL.
    if _telemetry_file != null:
        _telemetry_file.flush()
        _telemetry_file.close()
        _telemetry_file = null

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

    var output: Array = []
    var exit_code: int = OS.execute(
        "powershell.exe",
        arguments,
        output,
        true,
        false
    )

    # Reopen the same session and continue appending after publication.
    if FileAccess.file_exists(_telemetry_path):
        _telemetry_file = FileAccess.open(_telemetry_path, FileAccess.READ_WRITE)
        if _telemetry_file != null:
            _telemetry_file.seek_end()

    if exit_code == 0:
        print("CREATIVE_LAB_TELEMETRY_PUBLISH_COMPLETE reason=", reason)
    else:
        push_warning(
            "Telemetry GitHub publication failed with exit code %d; local workspace telemetry remains available. Output: %s"
            % [exit_code, "\n".join(output)]
        )
