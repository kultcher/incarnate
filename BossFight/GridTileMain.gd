extends Node2D

#var astar = preload("res://AStar.gd").new()

var UP = Vector2(0, -50)
var RIGHT = Vector2(50, 0)
var DOWN = Vector2(0, 50)
var LEFT = Vector2(-50, 0)

var all_directions = [UP, RIGHT, DOWN, LEFT]

# global variables
onready var globals = get_node("/root/GlobalVars")
onready var gamestate = get_node("..")

#script linkage
onready var astar_node = (get_parent().get_parent().get_child(3))  ######### ifffffy

# pathfinding variables 
	# tile variables
var move_cost = 0
var tile_passable = true
var tile_unoccupied = true

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
	if globals.selection == true:
		do_cell_action()
	if globals.selection == false:
		get_cell_contents()



#### issue: if player selects another unit while moving, the other unit is selected but keeps first unit's movement options
#### gonna need a state machine

# if nothing selected, check clicked cell for actor and get vars, otherwise deselect
func get_cell_contents():
	var check_object = get_world_2d().get_direct_space_state().intersect_point(position)
	if check_object:
		print(check_object)		# if there's anything in tile
		if check_object[0]["collider"] is StaticBody2D: # if the first object in the first dictionary's collider is body...
			var actor = check_object.front()["collider"].get_parent()
			# assign actor and tile to global vars
			globals.current_actor = actor
			globals.actor_origin_tile = self
			print(globals.actor_origin_tile)
			globals.actor_move_range = actor.move_range
			select_actor(globals.current_actor)
			check_object.clear()
		elif check_object[0]["collider"] is TileMap:
			deselect()
	else:
		deselect()

func do_cell_action():
	if tile_valid:
		globals.current_actor.actor_move(position)
		deselect()
	elif tile_unoccupied:
		print("Actor Details")
	else:
		print("Deselecting")
		deselect()

			
func select_actor(actor):
		get_tree().call_group("field_menu", "show_menu")
		 # show option menu when unit selected
		### BUG: failing to detect player when player is too low on the screen?


func player_pathfind(move_range):
	reset_pathing()
#	globals.actor_move_range = move_range
	start_path()
	

func start_path():
	distance_cycle = 1
	checked_tile = true
	add_to_group("checked_tiles")
	for neighbor in neighbors:
		neighbor.origin_tile = self
		neighbor.distance_from_origin = distance_from_origin + distance_cycle
		if neighbor.distance_from_origin == distance_cycle and neighbor.tile_passable == true and neighbor.tile_unoccupied == true:
#			neighbor.distance_from_origin += neighbor.move_cost
			unchecked_tiles.append(neighbor)

	next_distance(unchecked_tiles) # increments distance marker


func next_distance(unchecked_tiles):
	distance_cycle += 1
	print(distance_cycle)
	if distance_cycle <= globals.actor_move_range + 1:
		next_set(unchecked_tiles)
	else:
		get_valid_tiles()

### hacky solution for rough terrain: when you find neighbors from a 2 move cost tile, the first doesn't count so it gets deferred to next cycle
### otherwise have to make the distance cycle function on a per-tile basis?
### if we try to add extra distance during the cycle, it won't get added properly to the unchecked_tiles
### and/or it will double check and add from other sides

### alternate; make it so we count up, if moves_spend > distance from origin, then add to the check list
### write a seperate function to determine the lowest move cost to a spot based on neighbors

func next_set(unchecked_tiles):
	var new_unchecked = []
	for tiles in unchecked_tiles:
		tiles.checked_tile = true
		tiles.add_to_group("checked_tiles")
		for neighbor in tiles.neighbors:
			neighbor.origin_tile = self
			if distance_cycle > neighbor.distance_from_origin and neighbor.checked_tile == false:
				neighbor.distance_from_origin = distance_cycle
			if neighbor.distance_from_origin == distance_cycle and neighbor.checked_tile == false and neighbor.tile_passable == true and neighbor.tile_unoccupied == true:
				new_unchecked.append(neighbor)
	next_distance(new_unchecked)


# for each checked tile, highlights and flags it as valid, then exports for AStar to use
func get_valid_tiles():
	valid_tiles = get_tree().get_nodes_in_group("checked_tiles")
	astar_node.astar_import(valid_tiles)
	for tiles in valid_tiles:
		tiles.get_child(2).visible = true
		tiles.tile_valid = true
		globals.selection = true

#	if distance_from_origin <= globals.actor_move_range and checked_tile == true:
#		valid_tiles.append(self)


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
	get_tree().call_group("grid_tile", "reset_pathing")
	get_tree().call_group("field_menu", "hide_menu")
	globals.selection = false
