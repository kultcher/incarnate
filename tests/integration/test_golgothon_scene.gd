extends GutTest
## The Golgothon battle scene: the boss loads as a 2x2 unit, his intents
## show during the player phase, and his enemy phase runs and hands back.

const SPEED := 25.0

var battle: Battle


func before_each() -> void:
	Engine.time_scale = SPEED
	battle = load("res://levels/golgothon/golgothon_battle.tscn").instantiate()
	battle.card_seed = 2
	add_child_autofree(battle)
	await wait_process_frames(2)


func after_each() -> void:
	Engine.time_scale = 1.0
	await wait_process_frames(2)


func test_golgothon_and_four_incarnates_start_in_place() -> void:
	assert_not_null(battle.encounter, "The level's Encounter plays the enemy side")
	var boss := (battle.encounter as GolgothonEncounter).boss()
	assert_not_null(boss)
	assert_eq(boss.cell, Vector2i(4, 1))
	assert_eq(battle.board.unit_at(Vector2i(5, 2)), boss, "2x2")
	var players := 0
	for unit in battle.board.units():
		if unit.is_player():
			players += 1
			assert_eq(unit.hp, 40, "%s on the 40-health scale" % unit.def.display_name)
	assert_eq(players, 4)


func test_intents_show_during_the_player_phase() -> void:
	await wait_until(func() -> bool: return battle.controller.is_active(), 5.0)
	await wait_process_frames(2)
	assert_gt(battle.hud._intent_box.get_child_count(), 0, "The enemy turn is listed")
	assert_false(battle.arena.intents._intents.is_empty(), "And drawn on the board")


func test_the_enemy_phase_runs_and_hands_back() -> void:
	var c := battle.controller
	await wait_until(func() -> bool: return c.is_active(), 5.0)
	c.request_end_turn()
	await wait_until(func() -> bool: return c.is_active(), 15.0, "Back to the player")
	assert_eq(battle.battle_controller.round_number, 2)
	var minions := 0
	for unit in battle.board.units():
		if unit.def.id == &"welcoming_dead":
			minions += 1
	assert_eq(minions, 3, "Welcoming Dead were raised")
	assert_eq(battle.encounter.round_number, 2)
