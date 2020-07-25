extends Node

onready var gamestate = self.get_parent().get_parent()

var turn_order = []

func start_turn():
	var enemy_turn_order = determine_turn_order()
	for enemy in enemy_turn_order:
		yield(get_tree(), "idle_frame")
		enemy.start_turn()
	enemy_turn_order.clear()
	print("Enemy turn finished")
	gamestate.end_enemy_turn()

func determine_turn_order():
	for enemy in self.get_children():
		turn_order.append(enemy)
	print(turn_order[0].name)
	return(turn_order)
