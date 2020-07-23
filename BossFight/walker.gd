extends Node

class_name Walker

const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]

var position = Vector2.ZERO
var direction = Vector2.RIGHT
var borders = Rect2()
var step_history = []
var steps_since_turn = 0

func _init(starting_position, new_borders):
	assert(new_borders.has_point(starting_position)) # debug function, checks if starting point is inside borders
	position = starting_position
	step_history.append(position)
	borders = new_borders

func walk(steps):
	for step in steps:
		if randf() <= 0.25 or steps_since_turn >= 4: # 25% chance to direction, or change if 4 in same direction
			change_direction()
		
		if step(): # if step returns true
			step_history.append(position) # if we can go, add it to history
		else:
			change_direction()
	return step_history
	
func step():
	var target_position = position + direction
	if borders.has_point(target_position):
		steps_since_turn += 1
		position = target_position
		return true
	else:
		return false # if target is outside of borders, return false
		
func change_direction():
	steps_since_turn = 0
	var directions = DIRECTIONS.duplicate() # resets the list of directions
	directions.erase(direction)
	directions.shuffle()
	direction = directions.pop_front()
	while not borders.has_point(position + direction): # if unable to move in direction, try another
		direction = directions.pop_front()
	
	
	
