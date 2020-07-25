extends "res://Actor.gd"

func _ready():
	yield(get_tree(), "idle_frame")
	get_current_tile().tile_unoccupied = false
	

func start_new_turn():
	actions = max_actions

func populate_skills():
	pass
