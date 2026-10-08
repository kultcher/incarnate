extends GutTest
## Golgothon's encounter script and the engine pieces it needs: Large units,
## Trample, Sturdy, Resolve, Daze, summons, Drag You Down, Restless Dead.
## Incarnates are fixture units (12 health); cards are medians.

const GOLGOTHON := preload("res://content/units/golgothon.tres")
const MINION := preload("res://content/units/welcoming_dead.tres")
const CRIPPLE := preload("res://content/statuses/common/cripple.tres")
const SI := Enums.Tier.SILVER

var enc: GolgothonEncounter


## A 10x10 board. P/A are Incarnates; Golgothon stands with his top-left at
## [param boss_at].
func _rig(rows: Array[String], boss_at: Vector2i = Vector2i(4, 1)) -> TestRig:
	var rig := TestRig.make(self, rows)
	var boss := UnitState.new(GOLGOTHON, Enums.Team.ENEMY)
	rig.board.place_unit(boss, boss_at)
	for passive in GOLGOTHON.passives:
		await rig.resolver.apply_status(boss, passive, boss)
	var arena: Node = load("res://levels/golgothon/golgothon_arena.tscn").instantiate()
	enc = arena.get_node("Encounter")
	arena.remove_child(enc)
	arena.free()
	add_child_autofree(enc)
	enc.setup(rig.board, rig.resolver)
	return rig


func _open(rows: int = 10) -> Array[String]:
	var out: Array[String] = []
	for i in rows:
		out.append(". . . . . . . . . .")
	return out


## [param rows] with [param ch] put at [param cell].
func _with(rows: Array[String], ch: String, cell: Vector2i) -> Array[String]:
	var out := rows.duplicate()
	var row: String = out[cell.y]
	var chars := row.split(" ")
	chars[cell.x] = ch
	out[cell.y] = " ".join(chars)
	return out


func _minions(rig: TestRig) -> Array[UnitState]:
	var out: Array[UnitState] = []
	for unit in rig.board.units():
		if unit.def == MINION:
			out.append(unit)
	return out


#region Large units and traits

func test_golgothon_fills_a_2x2_block() -> void:
	var rig := await _rig(_with(_open(), "P", Vector2i(4, 4)))
	var boss := enc.boss()
	for cell: Vector2i in [Vector2i(4, 1), Vector2i(5, 1), Vector2i(4, 2), Vector2i(5, 2)]:
		assert_eq(rig.board.unit_at(cell), boss)
	assert_eq(rig.board.units().count(boss), 1, "Listed once")
	assert_eq(rig.board.distance_to(boss, Vector2i(4, 4)), 2, "From his nearest square")
	assert_false(Pathing.reachable(rig.board, rig.player(), 4).can_reach(Vector2i(5, 2)))


func test_resolve_absorbs_the_first_debuff_of_each_kind() -> void:
	var rig := await _rig(_with(_open(), "P", Vector2i(4, 4)))
	var boss := enc.boss()
	await rig.resolver.apply_status(boss, CRIPPLE, rig.player())
	assert_false(boss.has_status(&"cripple"), "Resolve 1 of 2")
	await rig.resolver.apply_status(boss, CRIPPLE, rig.player())
	assert_true(boss.has_status(&"cripple"), "The second one takes hold")


func test_sturdy_shortens_forced_movement() -> void:
	var rig := await _rig(_with(_open(), "P", Vector2i(4, 9)), Vector2i(4, 4))
	var moved := await rig.resolver.force_unit(enc.boss(), Vector2i(4, 9), 3, false)
	assert_eq(moved, 2, "3 squares minus Sturdy 1")
	moved = await rig.resolver.force_unit(enc.boss(), Vector2i(4, 9), 1, false)
	assert_eq(moved, 1, "Never less than 1")

#endregion

#region The timeline

func test_scripted_steps_follow_the_booklet() -> void:
	var steps: Array[StringName] = []
	for n in range(1, 8):
		steps.append(GolgothonEncounter.scripted_step(n))
	assert_eq(steps, [&"", &"deaths_grasp", &"deaths_caress", &"unquenched",
			&"deaths_grasp", &"deaths_caress", &"unquenched"] as Array[StringName])


func test_deaths_grasp_strikes_and_pulls_everyone_close() -> void:
	var rows := _with(_with(_open(), "P", Vector2i(4, 7)), "A", Vector2i(0, 9))
	var rig := await _rig(rows)
	await enc._deaths_grasp()
	assert_eq(rig.player().hp, 10, "Struck for Bronze 2")
	assert_eq(rig.player().cell, Vector2i(4, 3), "Pulled up against him")
	assert_eq(rig.ally().hp, 12, "Out of the burst (9 + 1 squares away)")


func test_deaths_caress_costs_seven_minus_distance() -> void:
	var rows := _with(_with(_open(), "P", Vector2i(4, 3)), "A", Vector2i(4, 6))
	var rig := await _rig(rows)
	enc.round_number = 3
	assert_eq(enc.danger(Vector2i(4, 3), Enums.Team.PLAYER), 6)
	assert_eq(enc.danger(Vector2i(9, 9), Enums.Team.PLAYER), 0)
	await enc._deaths_caress()
	assert_eq(rig.player().hp, 6, "Adjacent: lose 6")
	assert_eq(rig.ally().hp, 9, "4 squares away: lose 3")


func test_intents_show_the_caress_numbers_and_targets() -> void:
	var rig := await _rig(_with(_open(), "P", Vector2i(4, 4)))
	enc.round_number = 3
	var intents := enc.intents()
	var titles: Array[String] = []
	for intent in intents:
		titles.append(intent.title)
	assert_eq(titles, ["Death's Caress", "Grave Smash", "Carrion Spew", "Welcoming Dead"] as Array[String])
	assert_eq(intents[0].numbers[Vector2i(4, 3)], 6)
	assert_eq(intents[1].target, rig.player())

#endregion

#region Every turn

func test_grave_smash_goes_for_the_top_damage_dealer() -> void:
	var rows := _with(_with(_open(), "P", Vector2i(4, 4)), "A", Vector2i(4, 7))
	var rig := await _rig(rows)
	var boss := enc.boss()
	var spec := StrikeSpec.cards([SI] as Array[Enums.Tier], null, false)
	await rig.resolver.strike(rig.player(), boss, spec)
	await rig.resolver.strike(rig.ally(), boss, spec)
	await rig.resolver.strike(rig.ally(), boss, spec)
	assert_eq(enc.smash_target(), rig.ally(), "6 damage beats 3")
	await enc._grave_smash()
	assert_eq(rig.board.gap(boss, rig.ally()), 1, "Walked 4 toward the ally")
	assert_ne(rig.player().cell, Vector2i(4, 4), "Trampled out of the way")
	assert_eq(rig.ally().hp, 12 - 8, "Silver + Silver + Bronze")
	assert_true(rig.ally().has_status(&"daze"))


func test_grave_smash_spews_when_it_cant_reach() -> void:
	var rig := await _rig(_with(_open(), "P", Vector2i(4, 9)))
	await enc._grave_smash()
	assert_eq(enc.boss().cell, Vector2i(4, 5), "Moved 4")
	assert_eq(rig.player().hp, 12 - 5, "Carrion Spew instead: Silver + Bronze")


func test_daze_skips_the_next_recharge() -> void:
	var rig := await _rig(_with(_open(), "P", Vector2i(4, 4)))
	var p := rig.player()
	p.cooldowns[&"x"] = 2
	await rig.resolver.apply_status(p, enc.daze_status, enc.boss())
	await rig.new_turn(p)
	assert_eq(p.cooldowns[&"x"], 2, "No tick while Dazed")
	assert_false(p.has_status(&"daze"))
	await rig.new_turn(p)
	assert_eq(p.cooldowns[&"x"], 1)


func test_carrion_spew_picks_the_healthiest_in_range() -> void:
	var rows := _with(_with(_open(), "P", Vector2i(4, 4)), "A", Vector2i(5, 5))
	var rig := await _rig(rows)
	rig.player().hp = 5
	assert_eq(enc.spew_target(), rig.ally())


func test_welcoming_dead_rise_around_the_furthest_foe() -> void:
	var rows := _with(_with(_open(), "P", Vector2i(4, 4)), "A", Vector2i(8, 9))
	var rig := await _rig(rows)
	await enc._welcoming_dead()
	var minions := _minions(rig)
	assert_eq(minions.size(), 3)
	for m in minions:
		assert_eq(rig.board.distance_to(m, rig.ally().cell), 1, "Next to the ally")
	assert_true(Pathing.is_held(rig.board, rig.ally()), "Drag You Down")
	assert_false(rig.resolver.can_move(rig.ally()))


func test_drag_you_down_still_allows_teleports() -> void:
	var rows := _with(_with(_open(), "P", Vector2i(4, 4)), "A", Vector2i(8, 9))
	var rig := await _rig(rows)
	await enc._welcoming_dead()
	await rig.resolver.teleport_unit(rig.ally(), Vector2i(0, 9))
	assert_eq(rig.ally().cell, Vector2i(0, 9))


func test_minions_strike_and_move_once_unquenched() -> void:
	var rows := _with(_with(_open(), "P", Vector2i(4, 4)), "A", Vector2i(8, 9))
	var rig := await _rig(rows)
	await enc._welcoming_dead()
	var hp := rig.ally().hp
	for m in _minions(rig):
		await enc._welcoming_arms(m)
	assert_eq(rig.ally().hp, hp - 3 * 2, "Three Welcoming Arms for 2")
	var far := await rig.resolver.summon(MINION, Enums.Team.ENEMY, Vector2i(0, 0))
	await enc._welcoming_arms(far)
	assert_eq(far.cell, Vector2i(0, 0), "No Unquenched stacks: they don't move")
	await rig.resolver.apply_status(enc.boss(), enc.unquenched_status, enc.boss())
	await enc._welcoming_arms(far)
	assert_eq(far.cell, Vector2i(1, 0), "One stack: one square")

#endregion

#region Unquenched

func test_slain_minions_leave_gravestones_that_unquenched_raises() -> void:
	var rows := _with(_open(), "P", Vector2i(4, 9))
	var rig := await _rig(rows)
	var m1 := await rig.resolver.summon(MINION, Enums.Team.ENEMY, Vector2i(0, 5))
	var m2 := await rig.resolver.summon(MINION, Enums.Team.ENEMY, Vector2i(9, 5))
	rig.resolver.lose_health(m1, 99)
	rig.resolver.lose_health(m2, 99)
	assert_eq(rig.resolver.marks_of(&"restless_dead").size(), 2)
	var boss := enc.boss()
	var hp := boss.hp
	await enc._unquenched()
	assert_eq(_minions(rig).size(), 2, "Both rise again")
	assert_true(rig.resolver.marks_of(&"restless_dead").is_empty())
	assert_eq(boss.hp, hp - 2, "1 health per gravestone")
	assert_eq(enc.stacks(), 1)
	assert_eq(boss.get_stat(&"power"), 1, "+1 Power per stack")


func test_the_battle_is_won_when_golgothon_falls() -> void:
	var rig := await _rig(_with(_open(), "P", Vector2i(4, 9)))
	await rig.resolver.summon(MINION, Enums.Team.ENEMY, Vector2i(0, 5))
	assert_false(enc.is_won())
	rig.resolver.lose_health(enc.boss(), 999)
	assert_true(enc.is_won(), "Even with minions left")

#endregion
