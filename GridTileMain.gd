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
var origin_tile = null
var distance_from_origin = 0
var neighbors = []
var unchecked_tiles = []

	# flag variables
var distance_cycle
var checked_tile = false
var tile_valid = false
var valid_tiles

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
	globals.hovered_tile = self
	
	
func _on_TextureButton_pressed():
	if gamestate.state == gamestate.NO_SELECTION:
		get_cell_contents()
	if gamestate.state != gamestate.NO_SELECTION:
		do_cell_action()	



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
						var actor = check_object.front()["collider"].get_parent()
						# assign actor and tile to global vars
						actor.add_to_group("current_player_unit")
						globals.current_actor = actor
						globals.actor_origin_tile = self
						globals.actor_move_range = actor.move_range
						select_actor(globals.current_actor)
						check_object.clear()
					elif check_object[0]["collider"] is TileMap:
						deselect()
				else:
					deselect()

func do_cell_action():
	match gamestate.state:
		gamestate.NO_SELECTION:
			deselect()
					
		gamestate.PLAYER_MOVE:
			if tile_valid:
				globals.current_actor.actor_move(position)
				deselect()
			else:
				deselect()
				
		gamestate.PLAYER_ACTION:
			if tile_valid:
				globals.current_actor.find_node("Skills").execute_skill(self)
			else:
				deselect()

			
func select_actor(actor):
		get_tree().call_group("field_menu", "show_menu")
		 # show option menu when unit selected
		### BUG: failing to detect player when player is too low on the screen?


#func player_pathfind(move_range):
#	reset_pathing()
#	globals.actor_move_range = move_range
#	start_move_path()
	

func start_move_path():
	reset_pathing()
	distance_cycle = 0
	checked_tile = true
	add_to_group("checked_tiles")
	for neighbor in neighbors:
		neighbor.origin_tile = self
		neighbor.distance_from_origin = distance_from_origin + distance_cycle
		if neighbor.tile_passable == true and neighbor.tile_unoccupied == true:
			unchecked_tiles.append(neighbor)

	next_move_distance(unchecked_tiles) # increments distance marker

func next_move_distance(unchecked_tiles):
	distance_cycle += 1
	if distance_cycle <= globals.actor_move_range:
		next_move_set(unchecked_tiles)
	else:
		get_valid_move_tiles()
		
func next_move_set(unchecked_tiles):
	pass
	var new_unchecked = []
	for tiles in unchecked_tiles:
		
		# if tile is within move range and not already checked, set distance
		if tiles.distance_from_origin < distance_cycle and tiles.checked_tile == false:
			tiles.distance_from_origin = distance_cycle + tiles.move_cost
		
		# if tile exceeds move range and not already checked, re-add to list
		if tiles.distance_from_origin > distance_cycle and tiles.checked_tile == false:
			new_unchecked.append(tiles)
		else:			
			tiles.checked_tile = true
			tiles.add_to_group("checked_tiles")
			for neighbor in tiles.neighbors:
				neighbor.origin_tile = self
				if neighbor.tile_passable == true and neighbor.tile_unoccupied == true:
					new_unchecked.append(neighbor)

	next_move_distance(new_unchecked)


# for each checked tile, highlights and flags it as valid, then exports for AStar to use
func get_valid_move_tiles():
	print("getting valid")
	valid_tiles = get_tree().get_nodes_in_group("checked_tiles")
	astar_node.astar_import(valid_tiles)
	for tiles in valid_tiles:
		tiles.get_child(2).visible = true
		tiles.tile_valid = true
		globals.selection = true


func reset_pathing():
	origin_tile = null
	checked_tile = false
	tile_valid = false
	distance_from_origin = 0
	unchecked_tiles.clear()
	$TextureRect.visible = false
	if is_in_group("checked_tiles"):
		remove_from_group("checked_tiles")
	
		
func deselect():
	get_tree().call_group("field_menu", "hide_menu")
	get_tree().call_group("grid_tile", "reset_pathing")
	globals.current_actor.remove_from_group("current_player_unit")
	globals.selection = false
	gamestate.state = gamestate.NO_SELECTION
	
	
	
	
	##### mostly works? need to find a way to "toggle" which skill is active... global var?
	
	

func start_range_path(skill_range):
	reset_pathing()
	distance_cycle = 0
	checked_tile = true
	add_to_group("checked_tiles")
	for neighbor in neighbors:
		neighbor.origin_tile = self
		neighbor.distance_from_origin = distance_from_origin + distance_cycle
		if neighbor.tile_unobstructed == true:
			unchecked_tiles.append(neighbor)

	next_range_distance(unchecked_tiles, skill_range) # increments distance marker

func next_range_distance(unchecked_tiles, skill_range):
	print(distance_cycle, skill_range)
	distance_cycle += 1
	if distance_cycle <= skill_range:
		next_range_set(unchecked_tiles, skill_range)
	else:
		get_valid_target_tiles()
		
func next_range_set(unchecked_tiles, skill_range):
	pass
	var new_unchecked = []
	for tiles in unchecked_tiles:
		
		# if tile is within move range and not already checked, set distance
		if tiles.distance_from_origin < distance_cycle and tiles.checked_tile == false:
			tiles.distance_from_origin = distance_cycle
		
		# if tile exceeds move range and not already checked, re-add to list
		if tiles.distance_from_origin > distance_cycle and tiles.checked_tile == false:
			new_unchecked.append(tiles)
		else:			
			tiles.checked_tile = true
			tiles.add_to_group("checked_tiles")
			for neighbor in tiles.neighbors:
				neighbor.origin_tile = self
				if neighbor.tile_passable == true and neighbor.tile_unoccupied == true:
					new_unchecked.append(neighbor)

	next_range_distance(new_unchecked, skill_range)

func get_valid_target_tiles():
	print("getting valid")
	valid_tiles = get_tree().get_nodes_in_group("checked_tiles")
#	astar_node.astar_import(valid_tiles)
	for tiles in valid_tiles:
		tiles.get_child(2).visible = true
		tiles.tile_valid = true
		globals.selection = true
