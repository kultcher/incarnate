extends Control

onready var globals = get_node("/root/GlobalVars")
onready var gamestate = get_parent().get_parent().get_parent()

func show_menu():
	$VBoxContainer/Label.text = str("Actions: ", gamestate.current_actor.actions)
	$VBoxContainer/Label2.text = str("Health: ", gamestate.current_actor.health)
	$VBoxContainer.show()
	$VBoxContainer/ItemList.unselect_all()

func hide_menu():
	$VBoxContainer.hide()
	$ActionsList.hide()
	$VBoxContainer/ItemList.unselect_all()



func _on_ItemList_item_selected(index):
	if index == 0:
		get_tree().call_group("grid_tile", "reset_pathing")
		yield(get_tree(), "idle_frame")
		if gamestate.current_actor.actions > 0:
			gamestate.state = gamestate.PLAYER_MOVE
			gamestate.current_actor.movestate = gamestate.current_actor.MOVE
			gamestate.current_actor.start_move_path(gamestate.current_actor.base_move_range)

	if index == 1:
		print("Action")
		get_tree().call_group("grid_tile", "reset_pathing")		
		gamestate.state = gamestate.PLAYER_ACTION
		get_tree().call_group("current_player_unit", "actor_action")
		$ActionsList.show()

	if index == 2:
		get_tree().call_group("checked_tiles", "deselect")
		yield(get_tree(), "idle_frame")
		gamestate.state = gamestate.NO_SELECTION
		hide_menu()
		gamestate.end_player_turn()


func _on_ActionsList_item_selected(index):
	if index == 0:
		gamestate.current_actor.find_node("Skills").blade_fury_prime()
		
	if index == 1:
		gamestate.current_actor.find_node("Skills").bloody_rush_prime()
