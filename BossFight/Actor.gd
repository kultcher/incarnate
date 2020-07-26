extends Node2D


##### navigation variables #####

onready var globals = get_node("/root/GlobalVars")
onready var astar_node = get_parent().get_parent().get_child(3)

onready var world = get_parent().get_parent()
onready var gamestate = get_parent().get_parent().get_parent()
onready var sprite = find_node("AnimatedSprite")

var tilesize = 64 # future proofing in case 
var all_directions = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]

##### pathfinding variables #####

var distance_cycle
var unchecked_tiles = [] # can probably put this in individual scripts but have to make sure to clear it

enum {MOVE, SHIFT, FLY, TELEPORT}
enum {STANDARD, SEGMENTED}

##### local actor variables #####

export var base_move_range = 4
export var max_actions = 3
export var max_health = 10

var actions = 0
var health = max_health

var active_skill
var movestate = MOVE
var targstate = STANDARD
var segments
var skill_origin
var target_tiles = []

signal actor_move_completed

# moves unit to new tile along astar path, changes occupation status at start and end
func actor_move(end_position):
	var move_points = astar_node.astar_path(get_current_tile().position, end_position)
#	print("move points", move_points)
	unoccupy_tile()
	for moves in move_points:
		if moves.x > self.position.x:
			sprite.animation = "right"
		elif moves.x < self.position.x:
			sprite.animation = "left"
		elif moves.y > self.position.y:
			sprite.animation = "down"
		elif moves.y < self.position.y:
			sprite.animation = "up"
		$Tween.interpolate_property(self, "position", position, moves, .25, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
		$Tween.start()
		yield($Tween, "tween_completed")
		yield(get_tree(), "idle_frame")
	occupy_tile()
	astar_node.astar_reset()
	self.actions -= 1
	
	# resets movement/tiles
	get_tree().call_group("checked_tiles", "reset_pathing")
	unchecked_tiles.clear()
	emit_signal("actor_move_completed")

func shift_end_check():
	pass
		
func get_current_tile():
	var check_tile = get_world_2d().get_direct_space_state().intersect_point(self.position, 32, [], 2, false, true)
	var actor_tile = check_tile[0]["collider"].get_parent()
	return actor_tile

func occupy_tile():
	get_current_tile().tile_unoccupied = false

func unoccupy_tile():
	get_current_tile().tile_unoccupied = true

func face_target(target_position):
	if target_position.x > self.position.x:
		sprite.animation = "right"
		return Vector2.RIGHT
	elif target_position.x < self.position.x:
		sprite.animation = "left"
		return Vector2.LEFT
	elif target_position.y > self.position.y:
		sprite.animation = "down"
		return Vector2.DOWN
	elif target_position.y < self.position.y:
		sprite.animation = "up"
		return Vector2.UP
		
# consider (- 32 * direction to prevent "overshooting" target
func melee_animation(direction, target):
	var start_pos = position
	var scale = $AnimatedSprite.scale
	$Tween.interpolate_property(self, "position", position, target.position, .5, Tween.TRANS_ELASTIC, Tween.EASE_IN, 0)
	$Tween.interpolate_property(sprite, "scale", (scale * 1), (scale * 1.25), .5, Tween.TRANS_SINE, Tween.EASE_OUT, 0)
	print(sprite.scale)
	$Tween.start()
	yield($Tween, "tween_completed")
	$Tween.interpolate_property(self, "position", target.position, start_pos, .5, Tween.TRANS_BACK, Tween.EASE_OUT, 0)
	$Tween.interpolate_property(sprite, "scale", (scale * 1.25), (scale * 1), .5, Tween.TRANS_QUART, Tween.EASE_IN, 0)
	$Tween.start()
	yield($Tween, "tween_completed")

func take_damage(amount):
	self.health -= amount
	randomize()
	var float_position = $CombatText.rect_position + Vector2(clamp(randi(), 16, 32), clamp(-randi(), -32, -64))
	$CombatText.show()
	$CombatText.text = str(amount)
	$Tween.interpolate_property($CombatText, "rect_position", $CombatText.rect_position, float_position, 3, Tween.TRANS_QUAD, Tween.EASE_OUT, 0)
	$Tween.start()
	yield($Tween, "tween_completed")
	$CombatText.hide()
	$CombatText.rect_position = Vector2(0,-16)
	
	if self.health <= 0:
		die()
	
	#### can use themes to change colors
	
func take_healing(amount):
	self.health += amount

func die():
	get_current_tile().tile_unoccupied = true
	queue_free()

##### movement pathfinding #####
	
func start_move_path(move_range):
	print("starting")
	var hometile = get_current_tile()
	distance_cycle = 0
	hometile.checked_tile = true
	hometile.add_to_group("checked_tiles")
	for neighbor in hometile.neighbors:
#		neighbor.origin_tile = self
		neighbor.distance_from_origin = hometile.distance_from_origin + distance_cycle
		
		match movestate:
			MOVE:
				if neighbor.tile_passable == true and neighbor.tile_unoccupied == true:
					unchecked_tiles.append(neighbor)
			SHIFT:
				if neighbor.tile_passable == true:
					unchecked_tiles.append(neighbor)
	
	next_move_distance(unchecked_tiles, move_range) # increments distance marker

func next_move_distance(unchecked_tiles, move_range):
	distance_cycle += 1
	if distance_cycle <= move_range:
		next_move_set(unchecked_tiles, move_range)
	else:
		get_valid_move_tiles()

func next_move_set(unchecked_tiles, move_range):

	var new_unchecked = []
	for tiles in unchecked_tiles:

		# if tile is within move range and not already checked, set distance
		if tiles.distance_from_origin < distance_cycle and tiles.checked_tile == false:
			if movestate == SHIFT:
				tiles.distance_from_origin = distance_cycle
			else:
				tiles.distance_from_origin = distance_cycle + tiles.move_cost

		# if tile exceeds move range and not already checked, re-add to list
		if tiles.distance_from_origin > distance_cycle and tiles.checked_tile == false:
			new_unchecked.append(tiles)
		else:			
			tiles.checked_tile = true
			tiles.add_to_group("checked_tiles")
			for neighbor in tiles.neighbors:
#				neighbor.origin_tile = self

				match movestate:
					MOVE:
						if neighbor.tile_passable == true and neighbor.tile_unoccupied == true:
							new_unchecked.append(neighbor)
					SHIFT:
						if neighbor.tile_passable == true:
							new_unchecked.append(neighbor)

	next_move_distance(new_unchecked, move_range)

# for each checked tile, highlights and flags it as valid, then exports for AStar to use
func get_valid_move_tiles():
	print("getting valid")
	var valid_tiles = get_tree().get_nodes_in_group("checked_tiles")
	astar_node.astar_import(valid_tiles)
	for tiles in valid_tiles:
		tiles.get_child(2).visible = true
		tiles.tile_valid = true

##### range-based pathfinding #####


func start_range_path(skill_range):
	var hometile = get_current_tile()
	distance_cycle = 0
	hometile.checked_tile = true
	hometile.add_to_group("checked_tiles")
	for neighbor in hometile.neighbors:
#		neighbor.origin_tile = self
		neighbor.distance_from_origin = hometile.distance_from_origin + distance_cycle
		if neighbor.tile_unobstructed == true:
			unchecked_tiles.append(neighbor)

	next_range_distance(unchecked_tiles, skill_range) # increments distance marker


func next_range_distance(unchecked_tiles, skill_range):
	distance_cycle += 1
	if distance_cycle <= skill_range:
		next_range_set(unchecked_tiles, skill_range)
	else:
		get_valid_target_tiles()
		

func next_range_set(unchecked_tiles, skill_range):
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
#				neighbor.origin_tile = self
				if neighbor.tile_unobstructed == true:
					new_unchecked.append(neighbor)

	next_range_distance(new_unchecked, skill_range)

func get_valid_target_tiles():
	var valid_tiles = get_tree().get_nodes_in_group("checked_tiles")
#	astar_node.astar_import(valid_tiles)
	for tiles in valid_tiles:
		tiles.get_child(2).visible = true
		tiles.tile_valid = true



#### this mostly works except it doesn't account for obstacles... it doesn't get tiles in order so I can't
#### have it cut off after an obstace... have to reorder them manually
#### or find another way to account for obstacles
#### or just redo it more like a regular move... simple counter checking raycast same direction, etc.
func start_line_path(skill_range):
	var target_tiles = []
	var hometile = get_current_tile()
	hometile.checked_tile = true
	hometile.add_to_group("checked_tiles")
	for direction in all_directions:
		var target = position + (direction * skill_range * tilesize)
		var segment = SegmentShape2D.new()
		segment.a = position + Vector2(32, 32)
		segment.b = target + Vector2(32, 32)
		var query = Physics2DShapeQueryParameters.new()
		query.set_shape(segment)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.exclude = [get_current_tile().find_node("Area2D")]
		var check_line = get_world_2d().get_direct_space_state().intersect_shape(query, 32)
		for line in check_line:
			target_tiles.append(line["collider"].get_parent())
			for tiles in target_tiles:
				pass
#		print(target_tiles)
#		target_tiles.clear()
		
			
#			line["collider"].get_parent().add_to_group("checked_tiles")
#			target_tiles.append(line["collider"].get_parent())
#			print(line["collider"].get_parent())

func segment_info(segment_count, start_tile):
	segments = segment_count
	skill_origin = start_tile
	skill_origin.segment_highlight()

