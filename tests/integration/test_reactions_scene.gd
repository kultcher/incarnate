extends GutTest
## Prompts in the real scene: Bound in Blood's Pact on the 2nd strike,
## Chimeric Cloak negating a Shambler's Claw in the enemy phase, and a
## Shadow copying the Traceless's attack.

const SPEED := 8.0

var battle: Battle


func before_each() -> void:
	Engine.time_scale = SPEED
	battle = load("res://battle/battle.tscn").instantiate()
	battle.median_cards = true  # Exact damage numbers.
	add_child_autofree(battle)
	await wait_process_frames(2)


func after_each() -> void:
	Engine.time_scale = 1.0
	await wait_process_frames(2)


func _unit(id: StringName) -> UnitState:
	for unit in battle.board.units():
		if unit.def.id == id:
			return unit
	return null


func _at(cell: Vector2i) -> UnitState:
	return battle.board.unit_at(cell)


func _index(unit: UnitState, id: StringName) -> int:
	for i in unit.skills().size():
		if unit.skills()[i].id == id:
			return i
	return -1


func _idle() -> void:
	await wait_until(func() -> bool:
		return battle.controller.state == PlayerController.State.UNIT_SELECTED, 5.0)


func test_gate_pact_prompt_on_the_second_strike() -> void:
	var c := battle.controller
	var bt := _unit(&"bloodthane")
	var foe := _at(Vector2i(6, 6))
	foe.hp = 20
	assert_true(bt.has_status(&"bound_in_blood"), "Passive applied at battle start")

	await c.click_cell(bt.cell)
	await c.click_cell(Vector2i(6, 7))
	c.begin_targeting_index(_index(bt, &"blade_fury"))
	await c.click_cell(foe.cell)
	assert_false(battle.hud.prompt.is_open(), "No prompt after one strike")

	c.begin_targeting_index(_index(bt, &"blade_fury"))
	c.click_cell(foe.cell)  # Blocks on the prompt; don't await.
	await wait_until(func() -> bool: return battle.hud.prompt.is_open(), 5.0, "Pact prompt")
	assert_eq(battle.presenter.played.count(GameEvent.STRIKE), 2, "Both strikes had played first")

	battle.hud.prompt.set_remember(true)
	battle.hud.prompt.pick(0)  # Dominance
	await _idle()
	assert_true(foe.has_status(&"provoke"))
	assert_eq(bt.get_stat(&"armor"), 1)
	assert_eq(bt.find_status(&"bound_in_blood").choice, 0, "Remembered")
	var icons: Array = battle.presenter.view_for(foe)._icons
	assert_eq(icons.size(), 1, "Provoke icon over the Shambler")


func test_gate_cloak_negates_a_claw_in_the_enemy_phase() -> void:
	var c := battle.controller
	var tl := _unit(&"traceless")
	await c.click_cell(tl.cell)
	await c.click_cell(Vector2i(5, 8))  # Next to the lower Shambler.
	c.begin_targeting_index(_index(tl, &"chimeric_cloak"))
	await _idle()
	assert_true(tl.has_status(&"chimeric_cloak"))

	c.request_end_turn()
	await wait_until(func() -> bool: return battle.hud.prompt.is_open(), 10.0, "Cloak prompt")
	assert_eq(battle.hud.prompt._title.text, "Chimeric Cloak")
	var hp_before := tl.hp
	battle.hud.prompt.pick(0)
	await wait_until(func() -> bool: return not tl.has_status(&"chimeric_cloak"), 5.0)
	assert_eq(tl.hp, hp_before, "The Claw had no effect")

	while not c.is_active():
		if battle.hud.prompt.is_open():
			battle.hud.prompt.pick(DecisionRequest.DECLINED)
		await wait_process_frames(1)


func test_gate_a_shadow_copies_displacer_strike() -> void:
	var c := battle.controller
	var tl := _unit(&"traceless")
	var foe := _at(Vector2i(6, 8))
	await c.click_cell(tl.cell)
	await c.click_cell(Vector2i(5, 8))
	c.begin_targeting_index(_index(tl, &"displacer_strike"))
	await c.click_cell(foe.cell)
	c.click_cell(Vector2i(7, 8))  # Shift through the Shambler; blocks on the prompt.
	await wait_until(func() -> bool: return battle.hud.prompt.is_open(), 5.0, "Shadowstrike prompt")
	assert_eq(battle.hud.prompt._title.text, "Shadowstrike")
	assert_eq(tl.shadows, [Vector2i(5, 8)] as Array[Vector2i])
	assert_not_null(battle.arena.shadows.ghost_at(tl, Vector2i(5, 8)), "Ghost drawn on the Shadow")
	var choices := IllusiveShadowsBehavior.copy_choices(battle.board, tl,
			tl.skills()[_index(tl, &"displacer_strike")])
	assert_eq(choices[0][1], foe, "Nearest foe listed first")
	battle.hud.prompt.pick(0)
	await _idle()
	assert_eq(foe.hp, 2, "8 - 3 - 3")
	assert_true(tl.shadows.is_empty(), "Used up")


func test_pact_preference_from_the_passive_icon() -> void:
	var bt := _unit(&"bloodthane")
	var passive := bt.find_status(&"bound_in_blood")
	battle.hud.status_clicked.emit(passive)
	await wait_until(func() -> bool: return battle.hud.prompt.is_open(), 2.0)
	battle.hud.prompt.pick(1)
	await wait_process_frames(2)
	assert_eq(passive.choice, 1, "Vampiric chosen in advance")

	battle.hud.status_clicked.emit(passive)
	await wait_until(func() -> bool: return battle.hud.prompt.is_open(), 2.0)
	battle.hud.prompt.pick(DecisionRequest.DECLINED)
	await wait_process_frames(2)
	assert_eq(passive.choice, -1, "Back to asking each time")
