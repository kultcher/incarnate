extends Node2D

onready var globals = get_node("/root/GlobalVars")

onready var astar = AStar2D.new()
onready var tilemap = get_parent().get_child(0)

func astar_import(valid_tiles):
	astar_reset()
	var points = 0
	for tile in valid_tiles:
		astar.add_point(points, tile.position + Vector2(0,0))
		points += 1
	astar_connect(astar.get_points())


# thanks to GDQuest for the example
func astar_connect(points):
	var point_pos
	var closest_point
	for point in points:
		point_pos = astar.get_point_position(point) # we have vector 2 of current pos

		# checking in each direction for next point
		var points_relative = PoolVector2Array([
			Vector2(point_pos.x + 64, point_pos.y),
			Vector2(point_pos.x - 64, point_pos.y),
			Vector2(point_pos.x, point_pos.y + 64),
			Vector2(point_pos.x, point_pos.y - 64)])

		for point_relative in points_relative:
			closest_point = astar.get_closest_point(point_relative)
			
			var curr_point_pos = astar.get_point_position(point)
			var closest_point_pos = astar.get_point_position(closest_point)
			
			#if not itself
			if point != closest_point:
				# if not a diagonal
				if not abs(curr_point_pos.x - closest_point_pos.x) == abs(curr_point_pos.y - closest_point_pos.y):
					# if not too far away (over an obstacle)
					if abs(curr_point_pos.x - closest_point_pos.x) < 128 and abs(curr_point_pos.y - closest_point_pos.y) < 128:
						astar.connect_points(point, closest_point, false)


#creates an astar path between origin and destination tile
func astar_path(origin_tile, destination_tile):
	var origin = astar.get_closest_point(origin_tile) # origin POINT
	var destination = astar.get_closest_point(destination_tile)
#	print("points: ", origin, " ", destination)
	var path = astar.get_point_path(origin, destination)
	return(path)
	
# resets astar points after move completed or before new move
func astar_reset():
	astar.clear()
	
	
func get_nearest_point():
	print(astar.get_closest_point(get_global_mouse_position()))

# debug
func _input(event):
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		get_nearest_point()
