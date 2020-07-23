extends Control

onready var globals = get_node("/root/GlobalVars")

func show_menu():
	$ItemList.visible = true
	$ItemList.unselect_all()

func hide_menu():
	$ItemList.visible = false
	$ItemList.unselect_all()

func _on_ItemList_item_selected(index):
	if index == 0:
		get_tree().call_group("player", "actor_start_move")

	if index == 1:
		get_tree().call_group("player", "player_action")
