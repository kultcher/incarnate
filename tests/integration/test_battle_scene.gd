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
