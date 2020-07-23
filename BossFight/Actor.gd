extends Node2D

export var move_range = 0

onready var globals = get_node("/root/GlobalVars")
onready var astar_node = get_parent().get_parent().get_child(3)

onready var current_actor = globals.current_actor

onready var world = get_parent().get_parent()
onready var gamestate = get_parent().get_parent().get_parent()

# starts pathfinding from actor's current tile
func actor_start_move():
	globals.actor_origin_tile.player_pathfind(move_range)

func actor_move(end_position):
	var move_points = astar_node.astar_path(get_current_tile().position, end_position)
	
	print("move points", move_points)
	var count = 0
	unoccupy_start_tile()
	for moves in move_points:
		$Tween.interpolate_property(self, "position", position, moves, .1, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0)
		$Tween.start()
		yield($Tween, "tween_completed")
		print("Moving ", position, moves)
		count += 1

	occupy_end_tile(end_position)
	astar_node.astar_reset()
	
func get_current_tile():
	var check_tile = get_world_2d().get_direct_space_state().intersect_point(position, 32, [], 2, false, true)
	globals.actor_tile = check_tile[0]["collider"].get_parent()
	return globals.actor_tile

func occupy_end_tile(end_position):
	var check_tile = get_world_2d().get_direct_space_state().intersect_point(end_position, 32, [], 2, false, true)
	globals.actor_tile = check_tile[0]["collider"].get_parent()
	globals.actor_tile.tile_unoccupied = false	

func unoccupy_start_tile():
	get_current_tile()
	globals.actor_tile.tile_unoccupied = true
