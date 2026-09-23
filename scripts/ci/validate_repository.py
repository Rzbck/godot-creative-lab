from __future__ import annotations

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
    return [
        line.strip()
        for line in git("ls-files").splitlines()
        if line.strip()
    ]


def validate_required_files() -> None:
    required = (
        "project.godot",
        "AGENTS.md",
        "HANDOFF.md",
        ".gitignore",
        ".gitattributes",
        "docs/ARCHITECTURE.md",
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
            fail(
                f"tracked file is too large for normal Git policy: "
                f"{relative} ({mib:.1f} MiB)"
            )


def validate_project_owned_names() -> None:
    for root in PROJECT_OWNED_ROOTS:
        if not root.exists():
            continue

        for path in root.rglob("*"):
            if path.name == ".gitkeep":
                continue

            relative = path.relative_to(ROOT)

            # Third-party addons are intentionally excluded from this policy.
            for component in relative.parts:
                if " " in component:
                    fail(f"space in project-owned path: {relative}")

                if component.startswith("."):
                    continue

                stem = component
                if path.is_file():
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


def main() -> None:
    print("Creative Lab repository policy")

    validate_required_files()

    files = tracked_files()

    validate_forbidden_paths(files)
    validate_file_sizes(files)
    validate_project_owned_names()
    validate_project_config()

    print(f"Tracked files checked: {len(files)}")
    print("Repository policy: PASS")


if __name__ == "__main__":
    main()
