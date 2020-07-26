extends Node2D

#var astar = preload("res://AStar.gd").new()

var UP = Vector2(0, -50)
var RIGHT = Vector2(50, 0)
var DOWN = Vector2(0, 50)
var LEFT = Vector2(-50, 0)

var all_directions = [UP, RIGHT, DOWN, LEFT]

# global variables
onready var globals = get_node("/root/GlobalVars")
onready var gamestate = get_parent().get_parent().get_parent()

#script linkage
onready var astar_node = (get_parent().get_parent().find_node("AStar"))  ######### ifffffy

var active_skill

# pathfinding variables 
	# tile variables
var move_cost = 0
var tile_passable = true
var tile_unoccupied = true
var tile_unobstructed = true

	#distance variables
#var origin_tile = null
var distance_from_origin = 0
var neighbors = []
var unchecked_tiles = []
var target_tiles = []

	# flag variables
var distance_cycle
var checked_tile = false
var tile_valid = false
var segment_valid = false

onready var current_actor


# on ready, add neighbors to list
func get_neighbors():
	var neighbor_up = $Area2D/RayCastUp.get_collider()
	var neighbor_right = $Area2D/RayCastRight.get_collider()
	var neighbor_down = $Area2D/RayCastDown.get_collider()
	var neighbor_left = $Area2D/RayCastLeft.get_collider()
	
	if neighbor_right:
		neighbors.append(neighbor_right.get_parent())
	if neighbor_down:
		neighbors.append(neighbor_down.get_parent())
	if neighbor_left:
		neighbors.append(neighbor_left.get_parent())
	if neighbor_up:
		neighbors.append(neighbor_up.get_parent())		

	neighbors.erase("Object:null") #failsafe
	

func _on_TextureButton_mouse_entered():
	get_tree().call_group("debug", "update_debug", self, position, distance_from_origin)
	gamestate.hovered_tile = self
	
	
func _on_TextureButton_pressed():
	if gamestate.state == gamestate.NO_SELECTION:
		get_cell_contents()
	if gamestate.state != gamestate.NO_SELECTION:
		do_cell_action(self)	



#### issue: if player selects another unit while moving, the other unit is selected but keeps first unit's movement options
#### gonna need a state machine

# if nothing selected, check clicked cell for actor and get vars, otherwise deselect
func get_cell_actor():
	var check_actor = get_world_2d().get_direct_space_state().intersect_point(position)
	if check_actor:
		if check_actor[0]["collider"] is StaticBody2D:
			return check_actor[0]["collider"].get_parent()
		

func get_cell_contents():
	if gamestate.turn == gamestate.PLAYER_TURN:
		match gamestate.state:
			gamestate.NO_SELECTION:
				var check_object = get_world_2d().get_direct_space_state().intersect_point(position)
				if check_object:
					# if the first object in the first dictionary's collider is body and is a player unit
					if check_object[0]["collider"] is StaticBody2D and check_object[0]["collider"].get_parent().is_in_group("all_player_units"): 
						gamestate.current_actor = check_object.front()["collider"].get_parent()
						gamestate.current_actor.add_to_group("current_player_unit")
						select_actor()
						check_object.clear()
					elif check_object[0]["collider"] is TileMap:
						deselect()
				else:
					deselect()

func do_cell_action(current_cell):

	match gamestate.state:
		gamestate.NO_SELECTION:
			deselect()


		gamestate.PLAYER_MOVE:
			if tile_valid:
				gamestate.current_actor.actor_move(position)
				deselect()
			else:
				deselect()


		gamestate.PLAYER_ACTION:
			if gamestate.current_actor.targstate == gamestate.current_actor.STANDARD:
				if tile_valid:
					gamestate.current_actor.find_node("Skills").execute_skill(self)
				else:
					deselect()
					
			elif gamestate.current_actor.targstate == gamestate.current_actor.SEGMENTED:
				var last_cell
				if gamestate.current_actor.segments > 0:
					if tile_valid and segment_valid == true:
						gamestate.current_actor.skill_origin.target_tiles.append(current_cell) ##### YIKES
						$ConfirmRect.visible = true
						segment_valid = true
						gamestate.current_actor.skill_origin.segment_deselect()
						last_cell = current_cell
						segment_highlight()
						gamestate.current_actor.segments -= 1
						print(gamestate.current_actor.segments)
						yield(get_tree(), "idle_frame")
						if gamestate.current_actor.segments == 0:
							yield(get_tree(), "idle_frame")
							gamestate.current_actor.find_node("Skills").execute_skill(gamestate.current_actor.skill_origin.target_tiles)
							yield(get_tree(), "idle_frame")

							##### TODO: attach target_tiles to actor instead of grid tiles
							##### ALSO: this should make it easier to clear segmented highlights properly
							##### maybe add a confirmation dialog here...
							
					elif tile_valid and segment_valid == false:
						pass # if you click within range but invalid tile, don't deselect
					else:
						target_tiles.clear()
						deselect()

						
# show option menu when unit selected			
func select_actor():
		get_tree().call_group("field_menu", "show_menu")
		gamestate.state = gamestate.PLAYER_SELECTION


func reset_pathing():
#	origin_tile = null
	checked_tile = false
	tile_valid = false
	segment_valid = false
	distance_from_origin = 0
	unchecked_tiles.clear()
	$SelectionRect.hide()
	$ConfirmRect.hide()
	$SubSelRect.hide()
	if is_in_group("checked_tiles"):
		remove_from_group("checked_tiles")

	
		
func deselect():
	get_tree().call_group("field_menu", "hide_menu")
	get_tree().call_group("grid_tile", "reset_pathing")
	gamestate.state = gamestate.NO_SELECTION
#	gamestate.current_actor.skill_origin.target_tiles.clear() ##### YIIIKES
	if gamestate.current_actor:
		gamestate.current_actor.remove_from_group("current_player_unit")
		
func segment_highlight():
	for neighbor in neighbors:
		if neighbor.tile_passable == true and neighbor.checked_tile == true:
			neighbor.segment_valid = true
			neighbor.add_to_group("segment_tile")
			neighbor.find_node("SubSelRect").show()

func segment_deselect():
	for neighbor in neighbors:
		neighbor.add_to_group("segment_tile")
		neighbor.find_node("SubSelRect").hide()
		neighbor.segment_valid = false
