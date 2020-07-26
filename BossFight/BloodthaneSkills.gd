extends "res://Actor.gd"

onready var hero = get_parent()

func execute_skill(target_tile):
	active_skill.call_func(target_tile)

func blade_fury_prime():
	hero.start_range_path(1)
	active_skill = funcref(self, "blade_fury_exe")


func blade_fury_exe(target_tile):
	print("Blade Fury!")
	if target_tile.get_cell_actor():
		hero.melee_animation(hero.face_target(target_tile.position), target_tile)
		target_tile.get_cell_actor().take_damage(4)
		get_tree().call_group("checked_tiles", "deselect")
		self.actions -= 1
	else:
		print("No target!")

func bloody_rush_prime():

	active_skill = funcref(self, "bloody_rush_exe")
	hero.movestate = SHIFT
	hero.targstate = SEGMENTED
	hero.start_move_path(3)
	yield(get_tree(), "idle_frame")
	hero.segment_info(3, hero.get_current_tile())


func bloody_rush_exe(target_tile):
	var tween = hero.find_node("Tween")
	var sprite = hero.find_node("AnimatedSprite")
	hero.unoccupy_tile()
	for tile in target_tile:
		tween.interpolate_property(hero, "position", hero.position, tile.position, .25, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
		tween.interpolate_property(sprite, "scale", 3, 5, .25, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
		tween.start()
		yield(hero.find_node("Tween"), "tween_completed")
		yield(get_tree(), "idle_frame")
	hero.occupy_tile()
	hero.shift_end_check()
	hero.targstate = STANDARD
	hero.skill_origin.target_tiles.clear() #####
	hero.skill_origin.deselect()
