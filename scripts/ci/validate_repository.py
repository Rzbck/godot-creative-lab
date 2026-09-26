from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

PROJECT_OWNED_ROOTS = (
    ROOT / "app",
    ROOT / "sketches",
    ROOT / "shared",
)

FORBIDDEN_TRACKED_PREFIXES = (
    ".godot/",
    "build/",
    "dist/",
    "export/",
    "captures/",
    "local/",
    "assets/",
)

MAX_TRACKED_FILE_BYTES = 90 * 1024 * 1024

ALLOWED_PROJECT_NAME = re.compile(r"^[a-z0-9_]+(?:\.[a-z0-9_]+)*$")
ALLOWED_CONVENTIONAL_FILENAMES = {
    "README.md",
    "LICENSE",
    "LICENSE.md",
}

FULL_CANVAS_SURFACE_SCRIPT = "res://sketches/_shared/full_canvas_surface.gd"
VISUAL_FINISH_CONTRACT_INDEX = 36

BURNED_IN_SKETCH_TITLE = re.compile(
    r"draw_string\([^\n]*[\"']\d{3}\s*/\s*[A-Za-z]",
    re.MULTILINE,
)
SHADER_MATERIAL_BLOCK = re.compile(
    r"\[sub_resource type=\"ShaderMaterial\"[^\]]*\]\n(?P<body>.*?)(?=\n\[|\Z)",
    re.DOTALL,
)


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return result.stdout


def tracked_files() -> list[str]:
    return [line.strip() for line in git("ls-files").splitlines() if line.strip()]


def validate_required_files() -> None:
    required = (
        "project.godot",
        "AGENTS.md",
        "HANDOFF.md",
        ".gitignore",
        ".gitattributes",
        "docs/ARCHITECTURE.md",
        "sketches/_shared/full_canvas_surface.gd",
        "knowledge/cross-domain/VISUAL_FINISH_GATE.md",
    )
    for relative in required:
        if not (ROOT / relative).is_file():
            fail(f"required file missing: {relative}")


def validate_forbidden_paths(files: list[str]) -> None:
    for relative in files:
        normalized = relative.replace("\\", "/")
        for prefix in FORBIDDEN_TRACKED_PREFIXES:
            if normalized == prefix.rstrip("/") or normalized.startswith(prefix):
                fail(f"forbidden tracked path: {normalized}")


def validate_file_sizes(files: list[str]) -> None:
    for relative in files:
        path = ROOT / relative
        if not path.is_file():
            continue
        size = path.stat().st_size
        if size >= MAX_TRACKED_FILE_BYTES:
            mib = size / (1024 * 1024)
            fail(f"tracked file is too large for normal Git policy: {relative} ({mib:.1f} MiB)")


def validate_project_owned_names() -> None:
    for root in PROJECT_OWNED_ROOTS:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if path.name == ".gitkeep":
                continue
            relative = path.relative_to(ROOT)
            for component in relative.parts:
                if " " in component:
                    fail(f"space in project-owned path: {relative}")
                if component.startswith("."):
                    continue
                if path.is_file() and component == path.name and component in ALLOWED_CONVENTIONAL_FILENAMES:
                    continue
                stem = component
                if path.is_file() and component == path.name:
                    stem = path.stem
                if stem and not ALLOWED_PROJECT_NAME.fullmatch(stem.lower()):
                    fail(f"non snake_case project-owned path: {relative}")
                if any(char.isupper() for char in component):
                    fail(f"uppercase character in project-owned path: {relative}")


def validate_project_config() -> None:
    path = ROOT / "project.godot"
    text = path.read_text(encoding="utf-8")
    if 'config/name="DataC0re Creative Lab"' not in text:
        fail("unexpected or missing project name")
    if 'config/features=PackedStringArray("4.7")' not in text:
        fail("Godot 4.7 project feature declaration missing")


def validate_no_burned_in_sketch_titles(files: list[str]) -> None:
    for relative in files:
        normalized = relative.replace("\\", "/")
        if not normalized.startswith("sketches/") or "/runtime/" not in normalized or not normalized.endswith(".gd"):
            continue
        text = (ROOT / relative).read_text(encoding="utf-8")
        if BURNED_IN_SKETCH_TITLE.search(text):
            fail(f"sketch title/index must not be burned into rendered output: {normalized}")


def validate_full_canvas_shader_surfaces(files: list[str]) -> None:
    for relative in files:
        normalized = relative.replace("\\", "/")
        if not normalized.startswith("sketches/") or "/runtime/" not in normalized or not normalized.endswith(".tscn"):
            continue

        text = (ROOT / relative).read_text(encoding="utf-8")
        marker = '[node name="ShaderSurface"'
        if marker not in text:
            continue
        if FULL_CANVAS_SURFACE_SCRIPT not in text:
            fail(f"ShaderSurface must use shared full-canvas sizing component: {normalized}")

        blocks = text.split("\n[node ")
        for block in blocks:
            if not block.startswith('name="ShaderSurface"'):
                continue
            if re.search(r"offset_right\s*=\s*1280(?:\.0+)?", block):
                fail(f"fixed 1280px ShaderSurface width forbidden: {normalized}")
            if re.search(r"offset_bottom\s*=\s*720(?:\.0+)?", block):
                fail(f"fixed 720px ShaderSurface height forbidden: {normalized}")
            if "script = ExtResource" not in block:
                fail(f"ShaderSurface missing sizing script assignment: {normalized}")


def validate_shader_material_locality(files: list[str]) -> None:
    """Prevent Gallery thumbnail instances from sharing mutable shader uniforms.

    Gallery, PREVIEW and PROGRAM can instantiate the same PackedScene at once.
    Stateful shader materials therefore must be local to each scene instance;
    otherwise a hidden thumbnail can overwrite an active sketch's texture/uniforms.
    """
    for relative in files:
        normalized = relative.replace("\\", "/")
        if not normalized.startswith("sketches/") or "/runtime/" not in normalized or not normalized.endswith(".tscn"):
            continue
        text = (ROOT / relative).read_text(encoding="utf-8")
        for match in SHADER_MATERIAL_BLOCK.finditer(text):
            body = match.group("body")
            if not re.search(r"^resource_local_to_scene\s*=\s*true\s*$", body, re.MULTILINE):
                fail(f"ShaderMaterial must set resource_local_to_scene = true: {normalized}")


def _sketch_index(definition: Path) -> int:
    try:
        return int(definition.parent.name.split("_", 1)[0])
    except (ValueError, IndexError):
        return -1


def validate_visual_finish_profiles() -> None:
    for definition in sorted((ROOT / "sketches").glob("[0-9][0-9][0-9]_*/definition.json")):
        index = _sketch_index(definition)
        if index < VISUAL_FINISH_CONTRACT_INDEX:
            continue
        try:
            data = json.loads(definition.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            fail(f"invalid definition JSON: {definition.relative_to(ROOT)}: {exc}")

        profile = data.get("visual_finish")
        if not isinstance(profile, dict):
            fail(f"sketch {index:03d}+ must declare visual_finish: {definition.relative_to(ROOT)}")
        for key in ("composition", "material_model", "final_render", "detail_scales"):
            if key not in profile:
                fail(f"visual_finish missing {key}: {definition.relative_to(ROOT)}")
        detail_scales = profile.get("detail_scales")
        if not isinstance(detail_scales, list) or len(detail_scales) < 3:
            fail(f"visual_finish requires at least 3 detail scales: {definition.relative_to(ROOT)}")
        final_render = str(profile.get("final_render", "")).lower()
        if not final_render or "coarse" in final_render or "nearest_upscale" in final_render:
            fail(f"visual_finish final_render is not acceptable: {definition.relative_to(ROOT)}")
        if not bool(profile.get("interaction_stateful", False)):
            fail(f"visual_finish interaction_stateful must be true: {definition.relative_to(ROOT)}")


def main() -> None:
    print("Creative Lab repository policy")
    validate_required_files()
    files = tracked_files()
    validate_forbidden_paths(files)
    validate_file_sizes(files)
    validate_project_owned_names()
    validate_project_config()
    validate_no_burned_in_sketch_titles(files)
    validate_full_canvas_shader_surfaces(files)
    validate_shader_material_locality(files)
    validate_visual_finish_profiles()
    print(f"Tracked files checked: {len(files)}")
    print("Repository policy: PASS")


if __name__ == "__main__":
    main()
