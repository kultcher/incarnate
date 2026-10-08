extends Control
## Start screen: pick a battle.

const BATTLES: Array[Array] = [
	["Golgothon the Restless", "res://levels/golgothon/golgothon_battle.tscn",
			"The first boss: a walking graveyard and its Welcoming Dead."],
	["Test arena", "res://battle/battle.tscn",
			"Three Shamblers. A quick sandbox for trying the kits."],
]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	var title := Label.new()
	title.text = "Incarnate"
	title.add_theme_font_size_override("font_size", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	for entry in BATTLES:
		var b := Button.new()
		b.text = entry[0]
		b.tooltip_text = entry[2]
		b.custom_minimum_size = Vector2(320, 52)
		b.pressed.connect(func() -> void: get_tree().change_scene_to_file(entry[1]))
		box.add_child(b)
		var note := Label.new()
		note.text = entry[2]
		note.modulate = Color(1, 1, 1, 0.6)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(note)
