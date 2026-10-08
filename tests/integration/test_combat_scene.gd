extends GutTest
## Combat in the real battle scene: clicking out a path skill (Bloody Rush
## between two Shamblers), stepping back through picks, and kills.

const SPEED := 8.0

var battle: Battle


func before_each() -> void:
	Engine.time_scale = SPEED
	battle = load("res://battle/battle.tscn").instantiate()
	battle.fixed_deck = true  # Known cards.
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


func _index(unit: UnitState, id: StringName) -> int:
	for i in unit.skills().size():
		if unit.skills()[i].id == id:
			return i
	return -1


func test_gate_bloody_rush_clicked_out_between_two_shamblers() -> void:
	var bt := _unit(&"bloodthane")
	var top := battle.board.unit_at(Vector2i(6, 6))
	var bottom := battle.board.unit_at(Vector2i(6, 8))
	var c := battle.controller
	var p := battle.presenter

	await c.click_cell(bt.cell)
	await c.click_cell(Vector2i(4, 7))
	assert_eq(bt.cell, Vector2i(4, 7))

	p.played.clear()
	c.begin_targeting_index(_index(bt, &"bloody_rush"))
	assert_eq(c.state, PlayerController.State.TARGETING)
	await c.click_cell(Vector2i(5, 7))
	await c.click_cell(Vector2i(6, 7))
	assert_eq(c.state, PlayerController.State.TARGETING, "Still clicking out the path")
	await c.click_cell(Vector2i(7, 7))  # Third square: the path is full and runs.

	assert_eq(bt.cell, Vector2i(7, 7))
	assert_eq(top.hp, 5, "Silver 3")
	assert_eq(bottom.hp, 5)
	var combat := p.played.filter(func(t: StringName) -> bool:
		return t in [GameEvent.SKILL_USED, GameEvent.UNIT_MOVED, GameEvent.STRIKE, GameEvent.DAMAGED])
	assert_eq(combat, [GameEvent.SKILL_USED, GameEvent.UNIT_MOVED,
			GameEvent.STRIKE, GameEvent.DAMAGED, GameEvent.STRIKE, GameEvent.DAMAGED] as Array[StringName],
			"Shift, then the strikes, in rules order")
	assert_false(p.is_busy())
	assert_eq(c.state, PlayerController.State.UNIT_SELECTED)


func test_a_path_can_stop_early_by_clicking_its_end_again() -> void:
	var bt := _unit(&"bloodthane")
	var c := battle.controller
	await c.click_cell(bt.cell)
	await c.click_cell(Vector2i(4, 7))
	c.begin_targeting_index(_index(bt, &"bloody_rush"))
	await c.click_cell(Vector2i(5, 7))
	await c.click_cell(Vector2i(5, 7))
	assert_eq(bt.cell, Vector2i(5, 7))


func test_right_click_steps_back_through_picks() -> void:
	var bt := _unit(&"bloodthane")
	var c := battle.controller
	await c.click_cell(bt.cell)
	c.begin_targeting_index(_index(bt, &"bloody_rush"))
	await c.click_cell(Vector2i(3, 7))
	assert_eq(c.picks.size(), 1)
	c.back()
	assert_eq(c.picks.size(), 0, "Undid the pick")
	assert_eq(c.state, PlayerController.State.TARGETING)
	c.back()
	assert_eq(c.state, PlayerController.State.UNIT_SELECTED, "Cancelled targeting")
	assert_eq(bt.actions.skill, 1, "Nothing spent")


func test_cannot_target_without_a_foe_in_reach() -> void:
	var bt := _unit(&"bloodthane")
	var c := battle.controller
	await c.click_cell(bt.cell)
	c.begin_targeting_index(_index(bt, &"blade_fury"))
	assert_eq(c.state, PlayerController.State.UNIT_SELECTED, "No adjacent foe at the start")


func test_killing_blow_removes_the_shambler_and_its_view() -> void:
	var bt := _unit(&"bloodthane")
	var foe := battle.board.unit_at(Vector2i(6, 6))
	var c := battle.controller
	var view := battle.presenter.view_for(foe)
	await c.click_cell(bt.cell)
	await c.click_cell(Vector2i(6, 7))
	c.begin_targeting_index(_index(bt, &"rage_strike"))
	await c.click_cell(foe.cell)
	assert_eq(foe.hp, 1, "8 HP Shambler takes Gold + Silver = 7")
	c.begin_targeting_index(_index(bt, &"blade_fury"))
	await c.click_cell(foe.cell)
	assert_false(battle.board.units().has(foe))
	assert_eq(battle.presenter.played[-1], GameEvent.DIED)
	await wait_process_frames(2)
	assert_false(is_instance_valid(view), "View faded out and was freed")


func test_double_clicking_a_card_activates_it() -> void:
	var bt := _unit(&"bloodthane")
	var c := battle.controller
	var stream := battle.resolver.soulstream(Enums.Team.PLAYER)
	assert_eq(bt.hand.size(), 1, "One card dealt at the start of the phase")
	assert_eq(stream.row.size(), 1, "One card in the shared row")
	var held := bt.hand[0]
	assert_eq(str(held), "Orb", "The fixed deck: the row got the Blade")
	await c.click_cell(bt.cell)
	var blade := stream.row[0]
	await c.activate_card(blade)
	assert_true(bt.has_status(&"honed"), "Blade: +1 on the next attack")
	assert_true(stream.row.is_empty())
	await c.click_cell(Vector2i(5, 8))
	c.begin_targeting_index(_index(bt, &"blade_fury"))
	await c.click_cell(Vector2i(6, 8))
	assert_false(bt.has_status(&"honed"), "Spent on the attack")
	assert_string_contains(battle.hud._log_label.text, "+3 Power", "+2 for closing in, +1 Blade")


func test_priming_a_card_and_switching_units_unprimes_it() -> void:
	var bt := _unit(&"bloodthane")
	var tl := _unit(&"traceless")
	var c := battle.controller
	await c.click_cell(bt.cell)
	c.prime_card(bt.hand[0])
	assert_eq(c.primed, [bt.hand[0]] as Array[Card])
	assert_true(battle.hud._primed.has(bt.hand[0]), "The HUD shows it primed")
	await c.click_cell(tl.cell)
	assert_true(c.primed.is_empty())
	c.prime_card(bt.hand[0])
	assert_true(c.primed.is_empty(), "Can't prime another unit's card")


func test_a_primed_card_stays_when_the_skill_has_no_boon() -> void:
	var bt := _unit(&"bloodthane")
	var c := battle.controller
	var held := bt.hand[0]
	await c.click_cell(bt.cell)
	await c.click_cell(Vector2i(5, 8))
	c.prime_card(held)
	c.begin_targeting_index(_index(bt, &"blade_fury"))
	await c.click_cell(Vector2i(6, 8))
	assert_true(bt.hand.has(held), "No boons yet: nothing to pay")
	assert_true(c.primed.is_empty())
