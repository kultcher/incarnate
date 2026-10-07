class_name PickMarks
extends Node2D
## Marks cells already picked while targeting a multi-step skill, with a
## count when the same cell is picked more than once. For path skills, draws
## the path so far and marks its end ("click again to stop here").

const COLOR := Color(1.0, 0.85, 0.3)

var board_view: BoardView
var _counts: Dictionary[Vector2i, int] = {}
var _path: Array[Vector2i] = []
var _path_can_end: bool = false


func show_picks(picks: Array[Vector2i]) -> void:
	_path.clear()
	_counts.clear()
	for cell in picks:
		_counts[cell] = _counts.get(cell, 0) + 1
	queue_redraw()


## [param origin] is where the path starts (the caster's cell).
func show_path(origin: Vector2i, picks: Array[Vector2i], can_end: bool) -> void:
	_counts.clear()
	_path = [origin]
	_path.append_array(picks)
	_path_can_end = can_end and not picks.is_empty()
	queue_redraw()


func clear() -> void:
	_counts.clear()
	_path.clear()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for cell: Vector2i in _counts:
		var c := board_view.cell_to_local(cell)
		draw_arc(c, 30.0, 0.0, TAU, 32, COLOR, 3.0)
		var badge := c + Vector2(20, -20)
		draw_circle(badge, 11.0, Color(0.15, 0.05, 0.05, 0.9))
		draw_arc(badge, 11.0, 0.0, TAU, 20, COLOR, 2.0)
		draw_string(font, badge + Vector2(-11, 6), "x%d" % _counts[cell] if _counts[cell] > 1 else "✓",
				HORIZONTAL_ALIGNMENT_CENTER, 22, 15, COLOR)
	if _path.size() >= 2:
		var points := PackedVector2Array()
		for cell in _path:
			points.append(board_view.cell_to_local(cell))
		draw_polyline(points, COLOR, 4.0, true)
		for i in range(1, points.size()):
			draw_circle(points[i], 5.0, COLOR)
		if _path_can_end:
			# Double ring: the path may stop here (click it again).
			var end := points[points.size() - 1]
			draw_arc(end, 26.0, 0.0, TAU, 32, COLOR, 3.0)
			draw_arc(end, 20.0, 0.0, TAU, 32, COLOR, 2.0)
