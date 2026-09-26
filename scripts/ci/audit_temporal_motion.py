from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SKETCHES = ROOT / "sketches"
NEW_CONTRACT_INDEX = 26

DIRECT_CLOCK_TRIG = re.compile(
    r"\b(?:sin|cos)\s*\([^\n;]*(?:sketch_time|u_time|\bTIME\b)",
    re.IGNORECASE,
)
FIXED_INTERVAL_BRANCH = re.compile(
    r"\bif\s+[^\n]*(?:_age|_clock|_timer|_accum)[^\n]*(?:>|>=)\s*\d+(?:\.\d+)?",
    re.IGNORECASE,
)
INTENT_MARKER = "TEMPORAL_INTENT:"


def sketch_index(path: Path) -> int:
    try:
        return int(path.parts[path.parts.index("sketches") + 1].split("_", 1)[0])
    except (ValueError, IndexError):
        return -1


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def audit_runtime() -> tuple[list[str], list[str]]:
    warnings: list[str] = []
    errors: list[str] = []

    for path in sorted(SKETCHES.glob("[0-9][0-9][0-9]_*/*/*")):
        if not path.is_file() or path.suffix not in {".gd", ".gdshader"}:
            continue
        text = path.read_text(encoding="utf-8")
        direct = list(DIRECT_CLOCK_TRIG.finditer(text))
        fixed = list(FIXED_INTERVAL_BRANCH.finditer(text))
        idx = sketch_index(path)

        for match in direct:
            warnings.append(
                f"clock-trig {relative(path)}:{line_number(text, match.start())}: "
                f"{match.group(0).strip()[:96]}"
            )

        for match in fixed:
            warnings.append(
                f"fixed-interval {relative(path)}:{line_number(text, match.start())}: "
                f"{match.group(0).strip()[:96]}"
            )

        if idx >= NEW_CONTRACT_INDEX and direct and INTENT_MARKER not in text:
            errors.append(
                f"{relative(path)} uses direct clock trigonometry but has no "
                f"'{INTENT_MARKER}' explanation"
            )

    return warnings, errors


def audit_signatures() -> list[str]:
    errors: list[str] = []
    for definition in sorted(SKETCHES.glob("[0-9][0-9][0-9]_*/definition.json")):
        idx = sketch_index(definition)
        if idx < NEW_CONTRACT_INDEX:
            continue
        try:
            data = json.loads(definition.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"{relative(definition)} invalid JSON: {exc}")
            continue
        signature = data.get("creative_signature")
        if not isinstance(signature, dict) or not signature:
            errors.append(
                f"{relative(definition)} must define a non-empty creative_signature for index {idx:03d}+"
            )
    return errors


def main() -> None:
    print("DC//LAB temporal motion audit")
    warnings, errors = audit_runtime()
    errors.extend(audit_signatures())

    if warnings:
        print("\nHistorical/direct-clock observations:")
        for item in warnings:
            print(f"  WARN {item}")
    else:
        print("No direct-clock or fixed-interval observations found.")

    if errors:
        print("\nTemporal contract violations:", file=sys.stderr)
        for item in errors:
            print(f"  ERROR {item}", file=sys.stderr)
        raise SystemExit(1)

    print(f"\nTemporal audit: PASS ({len(warnings)} historical observations)")


if __name__ == "__main__":
    main()
