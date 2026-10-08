class_name MarkLayer
extends Node2D
## Draws board marks (Restless Dead) under the units: an icon per cell.

var board_view: BoardView
## id -> { "cells": Array[Vector2i], "icon": Texture2D }
var _marks: Dictionary = {}

const ICON_SIZE := 40.0


func set_marks(id: StringName, cells: Array[Vector2i], icon: Texture2D) -> void:
	_marks[id] = { "cells": cells.duplicate(), "icon": icon }
	queue_redraw()


func _draw() -> void:
	for entry: Dictionary in _marks.values():
		var icon: Texture2D = entry["icon"]
		for cell: Vector2i in entry["cells"]:
			var center := board_view.cell_to_local(cell)
			var rect := Rect2(center - Vector2.ONE * ICON_SIZE / 2.0, Vector2.ONE * ICON_SIZE)
			if icon != null:
				draw_texture_rect(icon, rect, false, Color(1, 1, 1, 0.7))
			else:
				draw_rect(rect, Color(0.4, 0.4, 0.45, 0.6))
