class_name ShadowMarker
extends Node2D
## A pulsing gold ring under a Shadow that can use an inherited skill now,
## with a badge counting its usable skills. Drawn by the ShadowLayer under
## the units, so the Shadow's own dim tint doesn't hide it.

const COLOR := Color(1.0, 0.82, 0.3)

var count: int = 1
var pulse: float = 0.0


func _draw() -> void:
	var alpha := 0.55 + 0.45 * pulse
	draw_circle(Vector2.ZERO, UnitView.RING_RADIUS, Color(COLOR, 0.18 * alpha))
	draw_arc(Vector2.ZERO, UnitView.RING_RADIUS, 0.0, TAU, 40, Color(COLOR, alpha), 3.0)
	var badge := Vector2(UnitView.RING_RADIUS * 0.75, -UnitView.RING_RADIUS * 0.75)
	draw_circle(badge, 9.0, Color(0.15, 0.1, 0.05, 0.9))
	draw_arc(badge, 9.0, 0.0, TAU, 20, COLOR, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, badge + Vector2(-4, 5), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR)
