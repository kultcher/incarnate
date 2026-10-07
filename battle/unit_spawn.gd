@tool
class_name UnitSpawn
extends Marker2D
## Place these in a level's Spawns node to set starting units.
## The battle snaps each one to the cell under it and then removes it.

@export var def: UnitDef:
	set(value):
		def = value
		queue_redraw()
@export var team: Enums.Team = Enums.Team.PLAYER:
	set(value):
		team = value
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := Color(0.3, 0.8, 1.0) if team == Enums.Team.PLAYER else Color(1.0, 0.4, 0.35)
	draw_rect(Rect2(-28, -28, 56, 56), Color(color, 0.25))
	draw_rect(Rect2(-28, -28, 56, 56), color, false, 2.0)
	var label := def.display_name if def != null else "(no unit)"
	draw_string(ThemeDB.fallback_font, Vector2(-26, 4), label, HORIZONTAL_ALIGNMENT_LEFT, 52, 11)
