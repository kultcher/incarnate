class_name Intent
extends RefCounted
## One thing an encounter will do this enemy phase, shown during the player
## phase: an area (with optional numbers per square), a target, or both.

var title: String
var text: String
var icon: Texture2D
## Squares it affects (Death's Grasp's burst).
var cells: Array[Vector2i] = []
## A number to show on some squares (Death's Caress: health lost there).
var numbers: Dictionary[Vector2i, int] = {}
## The unit it's aimed at (Grave Smash's target), if any.
var target: UnitState
var color := Color(1.0, 0.35, 0.3)


func _init(p_title: String, p_text: String, p_icon: Texture2D = null) -> void:
	title = p_title
	text = p_text
	icon = p_icon
