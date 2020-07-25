extends Node2D

export var move_range = 4
export var max_actions = 3
export var max_health = 10

var actions = 0
onready var health = max_health

var tilesize = 64 # future proofing in case 

onready var globals = get_node("/root/GlobalVars")
onready var astar_node = get_parent().get_parent().get_child(3)

onready var current_actor = globals.current_actor

onready var world = get_parent().get_parent()
onready var gamestate = get_parent().get_parent().get_parent()

onready var sprite = find_node("AnimatedSprite")

signal actor_move_completed


func actor_move(end_position):
	var move_points = astar_node.astar_path(get_current_tile().position, end_position)
	print("move points", move_points)
	unoccupy_start_tile()
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
	occupy_end_tile(end_position)
	astar_node.astar_reset()
	self.actions -= 1
	get_tree().call_group("checked_tiles", "deselect")
	emit_signal("actor_move_completed")
	
	##### fix viewport issue... remove main grid tile from "grid_tile" group or alternately add each one to group as it's added to grid
	
func get_current_tile():
	var check_tile = get_world_2d().get_direct_space_state().intersect_point(self.position, 32, [], 2, false, true)
	globals.actor_tile = check_tile[0]["collider"].get_parent()
	return globals.actor_tile

func occupy_end_tile(end_position):
	get_current_tile().tile_unoccupied = false


func unoccupy_start_tile():
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
		queue_free()
	
	#### can use themes to change colors
	
func take_healing(amount):
	self.health += amount
