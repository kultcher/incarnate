extends GutTest
## Loads the real battle scene and drives it through the controller,
## the same way mouse clicks do.

var battle: Battle


func before_each() -> void:
	battle = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await wait_process_frames(2)


func after_each() -> void:
	# Let the last walk animation finish emitting before the scene is freed.
	await wait_process_frames(2)


func _unit_named(display_name: String) -> UnitState:
	for unit in battle.board.units():
		if unit.def.display_name == display_name:
			return unit
	return null


func test_spawns_units_on_their_cells() -> void:
	assert_eq(battle.board.units().size(), 7, "Four Incarnates, three Shamblers")
	assert_eq(_unit_named("Bloodthane").cell, Vector2i(2, 7))
	assert_false(is_instance_valid(battle.arena.spawns_root), "Spawn markers are removed")


func test_click_select_then_move() -> void:
	var bt := _unit_named("Bloodthane")
	var controller := battle.controller
	await controller.click_cell(bt.cell)
	assert_eq(controller.selected, bt)
	assert_eq(battle.arena.highlights.get_used_cells().size() > 0, true, "Move range is shown")

	await controller.click_cell(Vector2i(4, 7))
	assert_eq(bt.cell, Vector2i(4, 7))
	var view := battle.presenter.view_for(bt)
	assert_eq(view.position, battle.arena.cell_to_local(Vector2i(4, 7)), "Sprite finished walking")
	assert_eq(bt.actions.move, 0)


func test_switch_units_mid_turn_and_come_back() -> void:
	var bt := _unit_named("Bloodthane")
	var tl := _unit_named("Traceless")
	var c := battle.controller
	await c.click_cell(bt.cell)
	await c.click_cell(Vector2i(2, 6))
	await c.click_cell(tl.cell)
	await c.click_cell(Vector2i(4, 8))
	await c.click_cell(bt.cell)
	await c.click_cell(Vector2i(2, 4))
	assert_eq(bt.cell, Vector2i(2, 4), "Bloodthane moved twice around Traceless's move")
	assert_eq(bt.actions.flex, 0)
	assert_eq(tl.cell, Vector2i(4, 8))


func test_cannot_select_enemies() -> void:
	var enemy := _unit_named("Shambler")
	await battle.controller.click_cell(enemy.cell)
	assert_null(battle.controller.selected)


func test_ending_the_turn_with_actions_left_asks_first() -> void:
	var c := battle.controller
	c.end_turn_from_input()
	await wait_until(func() -> bool: return battle.hud.prompt.is_open(), 2.0)
	assert_string_contains(battle.hud.prompt._text.text, "still")
	battle.hud.prompt.pick(DecisionRequest.DECLINED)
	await wait_process_frames(2)
	assert_true(c.is_active(), "Kept playing")
	c.end_turn_from_input()
	await wait_until(func() -> bool: return battle.hud.prompt.is_open(), 2.0)
	battle.hud.prompt.pick(0)
	await wait_process_frames(2)
	assert_false(c.is_active(), "Ended the turn")


func test_a_skill_made_free_shows_a_badge() -> void:
	var bt := _unit_named("Bloodthane")
	var potent := load("res://content/statuses/soulweaver/potent.tres") as StatusDef
	await battle.resolver.apply_status(bt, potent, bt)
	for unit in battle.board.units():
		if unit.team == Enums.Team.ENEMY:
			battle.board.move_unit(unit, bt.cell + Vector2i(1, 0))
			break
	await battle.controller.click_cell(bt.cell)
	await wait_process_frames(2)
	var first: Button = battle.hud._skill_bar.get_child(0)
	var badges := 0
	for child in first.get_children():
		if child is Label and (child as Label).text == "FREE":
			badges += 1
	assert_eq(badges, 1, "Blade Fury is free under Potent")
