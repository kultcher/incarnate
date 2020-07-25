extends "res://Actor.gd"

func start_new_turn():
	actions = max_actions

func populate_skills():
	world.find_node(
