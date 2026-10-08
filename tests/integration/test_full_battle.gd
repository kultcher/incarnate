extends GutTest
## Milestone 3 gate: a full battle against three enemies, in the real scene,
## plays to a win or a loss. Runs at high speed with the AI on both sides.

const SPEED := 25.0

var battle: Battle


func before_each() -> void:
	Engine.time_scale = SPEED


func after_each() -> void:
	Engine.time_scale = 1.0
	await wait_process_frames(2)


func _load(autoplay: bool) -> void:
	battle = load("res://battle/battle.tscn").instantiate()
	battle.autoplay = autoplay
	battle.card_seed = 1  # The same shuffle every run.
	add_child_autofree(battle)
	await wait_process_frames(2)


func _enemies() -> int:
	var n := 0
	for unit in battle.board.units():
		if not unit.is_player():
			n += 1
	return n


func test_gate_full_battle_vs_three_enemies_ends_in_win_or_loss() -> void:
	await _load(true)
	assert_eq(_enemies(), 3, "Three Shamblers")
	await wait_for_signal(battle.battle_controller.battle_ended, 20.0, "Battle finished")
	var outcome := battle.battle_controller.outcome
	assert_true(outcome == Enums.Outcome.VICTORY or outcome == Enums.Outcome.DEFEAT,
			"Outcome %s in %d rounds" % [Enums.Outcome.keys()[outcome], battle.battle_controller.round_number])
	assert_true(battle.hud._end_screen.visible, "Victory/defeat screen is up")
	assert_false(battle.presenter.is_busy(), "All animations finished")
	gut.p("Battle ended: %s in %d rounds" % [Enums.Outcome.keys()[outcome], battle.battle_controller.round_number])


func test_end_turn_hands_over_to_enemies_and_back() -> void:
	await _load(false)
	var c := battle.controller
	assert_true(c.is_active(), "Player phase starts at once")
	var hp_before := 0
	for unit in battle.board.units():
		if unit.is_player():
			hp_before += unit.hp

	c.request_end_turn()
	assert_false(c.is_active(), "Input is off during the enemy phase")
	assert_eq(battle.battle_controller.phase, Enums.Team.ENEMY)
	await wait_until(func() -> bool: return c.is_active(), 10.0, "Back to the player")

	assert_eq(battle.battle_controller.round_number, 2)
	var hp_after := 0
	for unit in battle.board.units():
		if unit.is_player():
			hp_after += unit.hp
			assert_false(unit.actions.is_spent(), "%s refreshed" % unit)
	assert_lt(hp_after, hp_before, "The Shamblers closed in and clawed someone")


func test_input_is_ignored_during_the_enemy_phase() -> void:
	await _load(false)
	var c := battle.controller
	var bt: UnitState
	for unit in battle.board.units():
		if unit.def.id == &"bloodthane":
			bt = unit
	c.request_end_turn()
	await c.click_cell(bt.cell)
	assert_null(c.selected, "Can't select during the enemy phase")
	await wait_until(func() -> bool: return c.is_active(), 10.0)


func test_f9_hands_the_rest_of_the_turn_to_the_ai() -> void:
	await _load(false)
	battle.set_autoplay(true)
	await wait_for_signal(battle.battle_controller.battle_ended, 20.0)
	assert_ne(battle.battle_controller.outcome, Enums.Outcome.NONE)
