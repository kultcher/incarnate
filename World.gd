extends Node2D

var map_max_x = 16
var map_max_y = 16
var map_curr_x = 1
var map_curr_y = 1

var newTile

onready var globals = get_node("/root/GlobalVars")
onready var gamestate = get_node("..")

##### example for getting to another script
##### onready var astar = preload("res://AStar.gd").new()


func _ready():
	create_map()
	create_grid()
	create_obstacles()
	get_tree().call_group("grid_tile", "get_neighbors")
	check_obstacles()
	spawn_actor()
	$GridTile.remove_from_group("grid_tile")
	get_parent().start_player_turn()
	print("world _ready done")
	
	
func create_map():
	var tile_pos = Vector2(map_curr_x, map_curr_y)
	while map_curr_y < map_max_y:
		while map_curr_x < map_max_x:
			var tilemap_auto = (randi() % 6)
			$GroundTileMap.set_cell(map_curr_x, map_curr_y, 1, false, false, false, Vector2(tilemap_auto, 0))
			map_curr_x += 1
			if map_curr_x == map_max_x:
				map_curr_x = 1
				map_curr_y += 1
			if map_curr_y == map_max_y:
				break
				
				
func create_obstacles():
	var tile_pos = Vector2(map_curr_x, map_curr_y)
	map_curr_x = 1
	map_curr_y = 1
	while map_curr_y < map_max_y:
		while map_curr_x < map_max_x:
			randomize()
			var obstacle_randomizer = (randi() % 11)
			if obstacle_randomizer == 10:
				$ObstacleTileMap.set_cell(map_curr_x, map_curr_y, 0, false, false, false, Vector2(21, 7))
			map_curr_x += 1
			if map_curr_x == map_max_x:
				map_curr_x = 1
				map_curr_y += 1
			if map_curr_y == map_max_y:
				break
				

func create_grid():
	var all_possible_tiles = $GroundTileMap.get_used_cells()
	for tiles in all_possible_tiles:
		$AllGridTiles.add_child(load("res://GridTile.tscn").instance())	# create grid instance for each tile
	
	var get_grid = $AllGridTiles.get_children() # get each node that was created
	
	for tiles in all_possible_tiles.size():
		var current_tile = all_possible_tiles.pop_front()	# get info for current tile in TileMap from front of array
		var current_grid = get_grid.pop_front()		# get the next grid entity
		current_grid.position = $GroundTileMap.map_to_world(current_tile)		# move current grid entity to position
		# check grid for obstacles
		


func check_obstacles():
	yield(get_tree(), "idle_frame")
	var all_grid_tiles = $AllGridTiles.get_children()
	for tiles in all_grid_tiles:
		var tilemap_pos = $GroundTileMap.world_to_map(tiles.position)
		var tile_type = $GroundTileMap.get_cell_autotile_coord(tilemap_pos.x, tilemap_pos.y)
		if tile_type.x >= 4:
			tiles.move_cost = 1


		var tile_offset = tiles.position - Vector2(-16, -16) ### offset slightly otherwise it gets all tiles bordering bottom right corner
		var check_object = get_world_2d().get_direct_space_state().intersect_point(tile_offset)
		if check_object:
			if check_object[0]["collider"] is TileMap:
				tiles.tile_passable = false


func spawn_actor():
	yield(get_tree(), "idle_frame")
	$Actors/Bloodthane.position = $GroundTileMap.map_to_world(Vector2(4,2), false)
	$Actors/Bloodthane/AnimatedSprite.playing = true
	globals.current_actor = $Actors/Bloodthane
	globals.actor_tile = globals.current_actor.get_current_tile()
	globals.actor_tile.tile_unoccupied = false
	
	

func update_debug(current_cell, position, distance_from_origin):
	$UI/DebugLabel.text = str(current_cell) + str(position) + " " + str(distance_from_origin) + " "\
							+ "Pass" + str(globals.hovered_tile.tile_passable) + "Unocc" + str(globals.hovered_tile.tile_unoccupied)\
							+ " Checked " + str(globals.hovered_tile.checked_tile) + \
							str(globals.hovered_tile.is_in_group("checked_tiles")) + str(globals.hovered_tile.tile_valid) \
							+ str(get_global_mouse_position())

func _input(event):
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		get_cell_id()
		
func get_cell_id():
	var check_cell = get_world_2d().get_direct_space_state().intersect_point(get_global_mouse_position(), 32, [], 2, false, true)
	var grid_tile = check_cell[0]["collider"].get_parent()
	var tilemap_cell = $GroundTileMap.world_to_map(grid_tile.position)
	print(grid_tile, tilemap_cell)
	return grid_tile
