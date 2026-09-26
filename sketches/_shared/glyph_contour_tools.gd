extends RefCounted

# Shared vector-outline extraction for experimental type systems.
# Godot exposes real glyph contours through TextServer. We cache sampled
# polylines so sketches can deform the structure of a letter instead of only
# moving a rasterized glyph as one rigid block.

const TAG_CONIC: int = 0
const TAG_ON: int = 1
const TAG_CUBIC: int = 2

static var _cache: Dictionary = {}


static func get_sampled_contours(
    font: Font,
    glyph: String,
    font_size: int,
    curve_steps: int = 6
) -> Array[PackedVector2Array]:
    if glyph.is_empty() or glyph == " ":
        return []

    var key: String = "%s|%s|%d|%d" % [str(font.get_instance_id()), glyph, font_size, curve_steps]
    if _cache.has(key):
        return _duplicate_contours(_cache[key] as Array)

    var server: TextServer = TextServerManager.get_primary_interface()
    if server == null:
        return []

    var codepoint: int = glyph.unicode_at(0)
    for font_rid: RID in font.get_rids():
        var glyph_index: int = server.font_get_glyph_index(font_rid, font_size, codepoint, 0)
        if glyph_index <= 0:
            continue

        var outline: Dictionary = server.font_get_glyph_contours(font_rid, font_size, glyph_index)
        var point_variant: Variant = outline.get("points", PackedVector3Array())
        var contour_variant: Variant = outline.get("contours", PackedInt32Array())
        if not point_variant is PackedVector3Array or not contour_variant is PackedInt32Array:
            continue

        var points: PackedVector3Array = point_variant as PackedVector3Array
        var contour_ends: PackedInt32Array = contour_variant as PackedInt32Array
        if points.is_empty() or contour_ends.is_empty():
            continue

        var sampled: Array[PackedVector2Array] = _sample_contours(points, contour_ends, maxi(2, curve_steps))
        if not sampled.is_empty():
            _cache[key] = sampled
            return _duplicate_contours(sampled)

    return []


static func _sample_contours(
    points: PackedVector3Array,
    contour_ends: PackedInt32Array,
    curve_steps: int
) -> Array[PackedVector2Array]:
    var result: Array[PackedVector2Array] = []
    var start_index: int = 0

    for end_value: int in contour_ends:
        var end_index: int = int(end_value)
        if end_index < start_index or end_index >= points.size():
            start_index = end_index + 1
            continue

        var raw: Array[Vector3] = []
        for point_index: int in range(start_index, end_index + 1):
            raw.append(points[point_index])
        start_index = end_index + 1

        var sampled: PackedVector2Array = _sample_single_contour(raw, curve_steps)
        if sampled.size() >= 3:
            result.append(sampled)

    return result


static func _sample_single_contour(raw: Array[Vector3], curve_steps: int) -> PackedVector2Array:
    var output: PackedVector2Array = PackedVector2Array()
    if raw.is_empty():
        return output

    var first_on: int = -1
    for index: int in range(raw.size()):
        if int(round(raw[index].z)) == TAG_ON:
            first_on = index
            break
    if first_on < 0:
        return output

    var nodes: Array[Vector3] = []
    for offset: int in range(raw.size()):
        nodes.append(raw[(first_on + offset) % raw.size()])

    var count: int = nodes.size()
    nodes.append(nodes[0])
    nodes.append(nodes[1 % count])
    nodes.append(nodes[2 % count])

    var current: Vector2 = Vector2(nodes[0].x, nodes[0].y)
    output.append(current)
    var cursor: int = 1

    while cursor <= count:
        var node: Vector3 = nodes[cursor]
        var tag: int = int(round(node.z))
        var position: Vector2 = Vector2(node.x, node.y)

        if tag == TAG_ON:
            current = position
            output.append(current)
            cursor += 1
            continue

        if tag == TAG_CONIC:
            var next_node: Vector3 = nodes[cursor + 1]
            var next_tag: int = int(round(next_node.z))
            var next_position: Vector2 = Vector2(next_node.x, next_node.y)
            var end_position: Vector2

            if next_tag == TAG_ON:
                end_position = next_position
                _append_quadratic(output, current, position, end_position, curve_steps)
                current = end_position
                cursor += 2
                continue

            if next_tag == TAG_CONIC:
                end_position = (position + next_position) * 0.5
                _append_quadratic(output, current, position, end_position, curve_steps)
                current = end_position
                cursor += 1
                continue

            # Malformed/mixed segment: preserve a visible contour rather than
            # aborting the whole glyph.
            current = position
            output.append(current)
            cursor += 1
            continue

        if tag == TAG_CUBIC:
            var control_b: Vector3 = nodes[cursor + 1]
            var end_node: Vector3 = nodes[cursor + 2]
            if int(round(control_b.z)) == TAG_CUBIC and int(round(end_node.z)) == TAG_ON:
                var control_b_pos: Vector2 = Vector2(control_b.x, control_b.y)
                var end_pos: Vector2 = Vector2(end_node.x, end_node.y)
                _append_cubic(output, current, position, control_b_pos, end_pos, curve_steps)
                current = end_pos
                cursor += 3
                continue

            current = position
            output.append(current)
            cursor += 1
            continue

        cursor += 1

    if output.size() > 1 and output[0].distance_to(output[output.size() - 1]) > 0.01:
        output.append(output[0])
    return output


static func _append_quadratic(
    output: PackedVector2Array,
    start: Vector2,
    control: Vector2,
    finish: Vector2,
    steps: int
) -> void:
    for step: int in range(1, steps + 1):
        var t: float = float(step) / float(steps)
        var omt: float = 1.0 - t
        output.append(start * omt * omt + control * 2.0 * omt * t + finish * t * t)


static func _append_cubic(
    output: PackedVector2Array,
    start: Vector2,
    control_a: Vector2,
    control_b: Vector2,
    finish: Vector2,
    steps: int
) -> void:
    for step: int in range(1, steps + 1):
        var t: float = float(step) / float(steps)
        var omt: float = 1.0 - t
        output.append(
            start * omt * omt * omt
            + control_a * 3.0 * omt * omt * t
            + control_b * 3.0 * omt * t * t
            + finish * t * t * t
        )


static func _duplicate_contours(source: Array) -> Array[PackedVector2Array]:
    var copied: Array[PackedVector2Array] = []
    for item: Variant in source:
        if item is PackedVector2Array:
            copied.append((item as PackedVector2Array).duplicate())
    return copied
