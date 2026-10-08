class_name IntentLayer
extends Node2D
## Draws what the encounter will do this enemy phase (Encounter.intents):
## tinted squares, a number per square where it matters, and a marker over
## each targeted unit. Redrawn whenever the intents change.

var board_view: BoardView
var _intents: Array[Intent] = []

const TINT_ALPHA := 0.16


func _ready() -> void:
	EventBus.intents_changed.connect(_on_intents_changed)


func _on_intents_changed(intents: Array[Intent]) -> void:
	_intents = intents.duplicate()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var half := Vector2.ONE * 31.0
	for intent in _intents:
		for cell in intent.cells:
			var center := board_view.cell_to_local(cell)
			draw_rect(Rect2(center - half, half * 2.0), Color(intent.color, TINT_ALPHA))
		for cell: Vector2i in intent.numbers:
			var pos := board_view.cell_to_local(cell) + Vector2(-8, 8)
			var text := str(intent.numbers[cell])
			draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color.BLACK)
			draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, intent.color.lightened(0.3))
	# Target markers: a ring per targeting intent, stacked if several.
	var rings: Dictionary[int, int] = {}
	for intent in _intents:
		var t := intent.target
		if t == null or not t.is_alive():
			continue
		var n: int = rings.get(t.id, 0)
		rings[t.id] = n + 1
		var center := board_view.cell_to_local(t.cell) + Vector2.ONE * 32.0 * (t.def.footprint - 1)
		draw_arc(center + Vector2(0, 8), 30.0 + n * 5.0, 0.0, TAU, 40, Color(intent.color, 0.9), 2.5)
		if intent.icon != null:
			var r := Rect2(center + Vector2(14 + n * 18, -40), Vector2(18, 18))
			draw_rect(r.grow(1.0), Color(0, 0, 0, 0.8))
			draw_texture_rect(intent.icon, r, false)
