extends "res://app/main/main_runtime_diagnostics.gd"

const DIAGNOSTIC_TELEMETRY_PUBLISH_SCRIPT: String = "res://scripts/publish-telemetry-diagnostics.ps1"


func _publish_telemetry_to_github(reason: String) -> void:
    if OS.get_name() != "Windows":
        return
    if _telemetry_path.is_empty() or not FileAccess.file_exists(_telemetry_path):
        return

    # Release the JSONL handle so the publisher can read a complete snapshot.
    if _telemetry_file != null:
        _telemetry_file.flush()
        _telemetry_file.close()
        _telemetry_file = null

    var script_path: String = ProjectSettings.globalize_path(DIAGNOSTIC_TELEMETRY_PUBLISH_SCRIPT)
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

    if FileAccess.file_exists(_telemetry_path):
        _telemetry_file = FileAccess.open(_telemetry_path, FileAccess.READ_WRITE)
        if _telemetry_file != null:
            _telemetry_file.seek_end()

    if exit_code == 0:
        print("CREATIVE_LAB_TELEMETRY_PUBLISH_COMPLETE reason=", reason, " schema=4")
    else:
        push_warning(
            "Diagnostic telemetry GitHub publication failed with exit code %d; local telemetry remains available. Output: %s"
            % [exit_code, "\n".join(output)]
        )
