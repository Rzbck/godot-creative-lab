extends "res://sketches/010_fault_register/runtime/fault_register_legacy.gd"

func _draw_grid(_font: Font) -> void:
    var left: float = 88.0
    var top: float = 102.0
    var width: float = 1104.0
    var height: float = 510.0
    var grid_color: Color = INK
    grid_color.a = 0.13 + grid_tension * 0.08

    for column: int in range(7):
        var x: float = left + float(column) * width / 6.0
        var p0: Vector2 = Vector2(x, top)
        var p1: Vector2 = Vector2(x, top + height)
        p0 += _fault_offset(p0) * 0.35
        p1 += _fault_offset(p1) * 0.35
        draw_line(p0, p1, grid_color, 1.0)

    for row: int in range(9):
        var y: float = top + float(row) * height / 8.0
        var p0: Vector2 = Vector2(left, y)
        var p1: Vector2 = Vector2(left + width, y)
        p0 += _fault_offset(p0) * 0.25
        p1 += _fault_offset(p1) * 0.25
        draw_line(p0, p1, grid_color, 1.0)
