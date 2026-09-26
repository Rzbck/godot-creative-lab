from __future__ import annotations

import argparse
import json
import random
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SPACE = ROOT / "knowledge" / "cross-domain" / "creative_draw_space.json"


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def item_id(item: Any) -> str:
    return str(item["id"] if isinstance(item, dict) else item)


def item_family(item: Any) -> str:
    if isinstance(item, dict):
        return str(item.get("family", item.get("id", "")))
    return str(item)


def signature_features(signature: dict[str, Any]) -> list[str]:
    result: list[str] = []
    for key in ("carrier", "temporal_model", "interaction", "constraint", "render_path"):
        value = signature.get(key)
        if value:
            result.append(f"{key}:{value}")
    for key in ("representations", "operators"):
        for value in signature.get(key, []):
            result.append(f"{key}:{value}")
    return result


def feature_usage(history: list[dict[str, Any]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for signature in history:
        counts.update(signature_features(signature))
    return counts


def extract_reviews(payload: dict[str, Any]) -> dict[str, Any]:
    if isinstance(payload.get("reviews"), dict):
        return payload["reviews"]
    data = payload.get("data")
    if isinstance(data, dict) and isinstance(data.get("reviews"), dict):
        return data["reviews"]
    return {}


def preference_map(
    history: list[dict[str, Any]],
    preference_payload: dict[str, Any] | None,
) -> dict[str, float]:
    if not preference_payload:
        return {}
    reviews = extract_reviews(preference_payload)
    history_by_id = {str(item.get("id", "")): item for item in history}
    accum: dict[str, list[float]] = defaultdict(list)
    for sketch_id, review in reviews.items():
        signature = history_by_id.get(str(sketch_id))
        if not signature or not isinstance(review, dict):
            continue
        average = review.get("average")
        if average is None and isinstance(review.get("ratings"), dict):
            scores = [float(v) for v in review["ratings"].values() if float(v) > 0.0]
            average = sum(scores) / len(scores) if scores else 0.0
        if average is None or float(average) <= 0.0:
            continue
        normalized = max(-1.0, min(1.0, (float(average) - 3.0) / 2.0))
        for feature in signature_features(signature):
            accum[feature].append(normalized)
    return {feature: sum(values) / len(values) for feature, values in accum.items() if values}


def recent_feature_sets(history: list[dict[str, Any]], window: int) -> list[set[str]]:
    return [set(signature_features(item)) for item in history[-window:]]


def candidate_distance(a: dict[str, Any], b: dict[str, Any]) -> int:
    axes = 0
    for key in ("carrier", "temporal_model", "interaction", "constraint", "render_path"):
        if a.get(key) != b.get(key):
            axes += 1
    if set(a.get("representations", [])) != set(b.get("representations", [])):
        axes += 1
    if set(a.get("operators", [])) != set(b.get("operators", [])):
        axes += 1
    return axes


def weighted_pick(
    rng: random.Random,
    pool: list[Any],
    axis: str,
    usage: Counter[str],
    recent_sets: list[set[str]],
    preferences: dict[str, float],
    exploration: bool,
    allowed: callable | None = None,
) -> Any:
    candidates = [item for item in pool if allowed is None or allowed(item)]
    if not candidates:
        raise RuntimeError(f"No candidates available for axis {axis}")

    weights: list[float] = []
    for item in candidates:
        identifier = item_id(item)
        feature = f"{axis}:{identifier}"
        count = usage[feature]
        rarity = 1.0 / (1.0 + 0.58 * float(count))
        recent = 1.0
        if recent_sets:
            if feature in recent_sets[-1]:
                recent *= 0.28
            elif any(feature in features for features in recent_sets[-3:]):
                recent *= 0.50
            elif any(feature in features for features in recent_sets):
                recent *= 0.72
        preference = 1.0
        if not exploration:
            preference += 0.24 * max(-1.0, min(1.0, preferences.get(feature, 0.0)))
        temporal_guard = 0.48 if axis == "temporal_model" and identifier == "forced_oscillator" else 1.0
        weights.append(max(0.01, rarity * recent * preference * temporal_guard))
    return rng.choices(candidates, weights=weights, k=1)[0]


def draw_once(
    space: dict[str, Any],
    rng: random.Random,
    preference_payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    history = list(space.get("history", []))
    window = int(space.get("recent_window", 5))
    usage = feature_usage(history)
    recent_sets = recent_feature_sets(history, window)
    preferences = preference_map(history, preference_payload)
    exploration = rng.random() < float(space.get("exploration_probability", 0.24))

    def pick(pool_name: str, axis: str | None = None, allowed: callable | None = None) -> Any:
        return weighted_pick(
            rng,
            list(space[pool_name]),
            axis or pool_name.rstrip("s"),
            usage,
            recent_sets,
            preferences,
            exploration,
            allowed,
        )

    best: dict[str, Any] | None = None
    best_distance = -1
    for _ in range(64):
        rep_a = pick("representations", "representations")
        rep_b = pick(
            "representations",
            "representations",
            lambda item: item_id(item) != item_id(rep_a) and item_family(item) != item_family(rep_a),
        )
        op_a = pick("operators", "operators")
        op_b = pick(
            "operators",
            "operators",
            lambda item: item_id(item) != item_id(op_a) and item_family(item) != item_family(op_a),
        )
        candidate = {
            "carrier": item_id(pick("carriers", "carrier")),
            "representations": [item_id(rep_a), item_id(rep_b)],
            "operators": [item_id(op_a), item_id(op_b)],
            "temporal_model": item_id(pick("temporal_models", "temporal_model")),
            "interaction": item_id(pick("interactions", "interaction")),
            "constraint": item_id(pick("constraints", "constraint")),
            "render_path": item_id(pick("render_paths", "render_path")),
        }
        distances = [candidate_distance(candidate, previous) for previous in history[-window:]]
        minimum = min(distances) if distances else 7
        if minimum > best_distance:
            best = candidate
            best_distance = minimum
        if minimum >= 4:
            best = candidate
            best_distance = minimum
            break

    if best is None:
        raise RuntimeError("Could not draw a creative signature")
    return {
        "exploration_draw": exploration,
        "minimum_recent_axis_distance": best_distance,
        "creative_signature": best,
    }


def signature_key(result: dict[str, Any]) -> str:
    signature = result["creative_signature"]
    return json.dumps(signature, sort_keys=True, separators=(",", ":"))


def self_test(space: dict[str, Any], seed: int) -> None:
    signatures: set[str] = set()
    render_counts: Counter[str] = Counter()
    temporal_counts: Counter[str] = Counter()
    for offset in range(180):
        result = draw_once(space, random.Random(seed + offset))
        signature = result["creative_signature"]
        reps = signature["representations"]
        rep_by_id = {item_id(item): item for item in space["representations"]}
        if item_family(rep_by_id[reps[0]]) == item_family(rep_by_id[reps[1]]):
            raise AssertionError("representation families collided")
        op_by_id = {item_id(item): item for item in space["operators"]}
        ops = signature["operators"]
        if item_family(op_by_id[ops[0]]) == item_family(op_by_id[ops[1]]):
            raise AssertionError("operator families collided")
        if result["minimum_recent_axis_distance"] < 4:
            raise AssertionError("candidate too close to recent history")
        signatures.add(signature_key(result))
        render_counts[signature["render_path"]] += 1
        temporal_counts[signature["temporal_model"]] += 1

    if len(signatures) < 165:
        raise AssertionError(f"draw diversity too low: {len(signatures)} unique / 180")
    if temporal_counts["forced_oscillator"] > 24:
        raise AssertionError("forced oscillator is overrepresented")
    if max(render_counts.values()) > 62:
        raise AssertionError(f"render path dominance too high: {render_counts}")
    print(f"Adaptive creative draw self-test: PASS ({len(signatures)} unique / 180)")


def main() -> None:
    parser = argparse.ArgumentParser(description="Draw a diversity-aware DC//LAB creative recipe.")
    parser.add_argument("--space", type=Path, default=DEFAULT_SPACE)
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--preferences", type=Path, default=None)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    space = load_json(args.space)
    seed = args.seed if args.seed is not None else random.SystemRandom().randrange(1, 2**31 - 1)
    if args.self_test:
        self_test(space, seed)
        return

    preference_payload = load_json(args.preferences) if args.preferences else None
    result = draw_once(space, random.Random(seed), preference_payload)
    result["seed"] = seed
    result["preference_bias"] = bool(preference_payload)
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
