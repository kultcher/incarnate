extends "res://GridTileMain.gd"

onready var hero = get_parent()

func execute_skill(target_tile):
	active_skill.call_func(target_tile)

func blade_fury_prime():
	hero.get_current_tile().start_range_path(1)
	active_skill = funcref(self, "blade_fury_exe")


func blade_fury_exe(target_tile):
	print("Blade Fury!")
	if target_tile.get_cell_actor():
		hero.melee_animation(hero.face_target(target_tile.position), target_tile)
		target_tile.get_cell_actor().take_damage(4)
		get_tree().call_group("checked_tiles", "deselect")
	else:
		print("No target!")