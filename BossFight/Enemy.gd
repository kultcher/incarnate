extends "res://Actor.gd"

var nearest_player
var current_target


func _ready():
	base_move_range = 3
	yield(get_tree(), "idle_frame")
	get_current_tile().tile_unoccupied = false

func start_turn():
	gamestate.current_actor = self
	nearest_player = find_nearest_player()
	move_to_target(nearest_player)
	yield(self, "actor_move_completed")
	basic_melee()


# gets all players units on field, gets distances to each unit, returns location of nearest player unit
func find_nearest_player():
	var units = []
	var distances = []
	var player_units = world.find_node("Actors").get_children()
	for unit in player_units:
		units.append(unit)
		distances.append(position.distance_to(unit.position))
	var target = (units[distances.find(distances.min())]) # gets the Node of the closest unit
	current_target = target
	return target.position

func move_to_target(target):
	self.movestate = MOVE
	self.start_move_path(base_move_range)
	actor_move(target)


func basic_melee():
	print(self.name, " attacks!")
	if position.distance_to(current_target.position) <= tilesize:
		var facing = face_target(current_target.position)
		melee_animation(facing, current_target)
		yield(get_tree(), "idle_frame")
		current_target.take_damage(5)
