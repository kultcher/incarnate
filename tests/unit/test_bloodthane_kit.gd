extends GutTest
## The Bloodthane's 2014 kit, one skill at a time (cards at their medians:
## Bronze 2, Silver 3, Gold 4).

const BT := preload("res://content/units/bloodthane.tres")
const CLAW := preload("res://content/skills/shambler/claw.tres")

## Bound in Blood's Pacts, in order.
const DOMINANCE := 0
const VAMPIRIC := 1
const PREDATION := 2


func _rig(rows: Array[String], move: int = 4) -> TestRig:
	var rig := TestRig.make(self, rows, move)
	await rig.equip(rig.player(), BT)
	await rig.new_turn(rig.player())
	return rig


func _hp(unit: UnitState, hp: int) -> void:
	unit.hp = hp


#region Attacks

func test_blade_fury_strikes_for_two_bronze() -> void:
	var rig := await _rig(["P E"] as Array[String])
	assert_true(await rig.use(rig.player(), &"blade_fury", [Vector2i(1, 0)]))
	assert_eq(rig.enemy().hp, 8, "Bronze + Bronze = 4")


func test_blade_fury_gains_power_after_closing_in() -> void:
	var rig := await _rig(["P . . . . E"] as Array[String])
	assert_true(await rig.resolver.request_move(rig.player(), Vector2i(4, 0)))
	assert_true(await rig.use(rig.player(), &"blade_fury", [Vector2i(5, 0)]))
	assert_eq(rig.enemy().hp, 6, "4 squares closed: +2 Power, 6 damage")


func test_blade_fury_bonus_needs_the_move_right_before() -> void:
	var rig := await _rig(["P . . . E E"] as Array[String])
	assert_true(await rig.resolver.request_move(rig.player(), Vector2i(3, 0)))
	assert_true(await rig.use(rig.player(), &"blade_fury", [Vector2i(4, 0)]))
	assert_eq(rig.enemy(0).hp, 7, "3 squares closed: +1 Power, 5")
	var other := rig.enemy(0)
	other.hp = 20
	assert_true(await rig.use(rig.player(), &"blade_fury", [Vector2i(4, 0)]))
	assert_eq(other.hp, 16, "Not right after a move: no bonus")


func test_rending_claws_gains_power_from_damage_dealt_this_turn() -> void:
	var rig := await _rig(["P E"] as Array[String])
	rig.enemy().hp = 30
	await rig.use(rig.player(), &"rending_claws", [Vector2i(1, 0)])
	assert_eq(rig.enemy().hp, 24, "Fresh turn: Silver + Silver = 6")
	rig.player().cooldowns.clear()
	await rig.use(rig.player(), &"rending_claws", [Vector2i(1, 0)])
	assert_eq(rig.enemy().hp, 15, "6 dealt already: +3 Power, 9")
	assert_eq(rig.player().cooldown_left(rig.skill(rig.player(), &"rending_claws")), 2)


func test_rage_strike_hits_hard_and_recharges_when_struck() -> void:
	var rig := await _rig(["P E"] as Array[String])
	rig.enemy().hp = 20
	await rig.use(rig.player(), &"rage_strike", [Vector2i(1, 0)])
	assert_eq(rig.enemy().hp, 13, "Gold + Silver = 7")
	var rage := rig.skill(rig.player(), &"rage_strike")
	assert_eq(rig.player().cooldown_left(rage), 3)
	await rig.resolver.strike(rig.enemy(), rig.player(), StrikeSpec.cards([Enums.Tier.BRONZE] as Array[Enums.Tier]))
	assert_eq(rig.player().cooldown_left(rage), 2, "A foe's strike recharges it by 1")


func test_bloody_rush_strikes_foes_passed_and_beside_the_path() -> void:
	var rig := await _rig([
		"P E . .",
		". . . E",
		". . . .",
	] as Array[String])
	var path := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	assert_true(await rig.use(rig.player(), &"bloody_rush", path))
	assert_eq(rig.player().cell, Vector2i(2, 1))
	assert_eq(rig.enemy(0).hp, 9, "Shifted through: Silver 3")
	assert_eq(rig.enemy(1).hp, 9, "Next to the last square")
	assert_false(rig.player().has_status(&"bloody_rush_armor"), "Only 2 foes struck")


func test_bloody_rush_armor_for_three_foes() -> void:
	var rig := await _rig([
		". E .",
		"P . E",
		". E .",
	] as Array[String])
	assert_true(await rig.use(rig.player(), &"bloody_rush", [Vector2i(1, 1)]))
	assert_true(rig.player().has_status(&"bloody_rush_armor"))
	assert_eq(rig.player().get_stat(&"armor"), 1)
	await rig.new_round()
	assert_eq(rig.player().get_stat(&"armor"), 0, "Until end of turn")

#endregion

#region Defense, mobility, utility

func test_acute_coagulant_heals_now_at_end_of_turn_and_when_struck() -> void:
	var rig := await _rig(["P E"] as Array[String])
	_hp(rig.player(), 3)
	await rig.use(rig.player(), &"acute_coagulant")
	assert_eq(rig.player().hp, 6, "Heal Silver 3")
	await rig.resolver.strike(rig.enemy(), rig.player(), StrikeSpec.cards([Enums.Tier.BRONZE] as Array[Enums.Tier]))
	assert_eq(rig.player().hp, 6, "Struck for 2, healed Bronze 2")
	await rig.resolver.strike(rig.enemy(), rig.player(), StrikeSpec.flat(1))
	assert_eq(rig.player().hp, 5, "Struck for 1: below the threshold")
	await rig.new_round()
	assert_eq(rig.player().hp, 7, "End of turn: heal 2")
	await rig.new_round()
	assert_eq(rig.player().hp, 9, "Second turn")
	assert_false(rig.player().has_status(&"acute_coagulant"), "Lasts 2 turns")


func test_verve_magnet_pulls_together_and_drains_the_foe() -> void:
	var rig := await _rig(["P . . . . E ."] as Array[String])
	_hp(rig.player(), 10)
	rig.answers.answers = [0]  # Pull together.
	assert_true(await rig.use(rig.player(), &"verve_magnet", [Vector2i(5, 0)]))
	assert_eq(rig.enemy().cell, Vector2i(3, 0), "Foe forced 2 toward")
	assert_eq(rig.player().cell, Vector2i(2, 0), "Bloodthane forced 2 toward, up to the foe")
	assert_eq(rig.enemy().hp, 11, "Forced foe loses 1")
	assert_eq(rig.player().hp, 11, "Forced ally (himself) heals 1")
	assert_eq(rig.player().actions.move, 0, "Maneuver: paid with the move action")


func test_verve_magnet_can_push_apart_and_stops_at_walls() -> void:
	var rig := await _rig(["# . P E . #"] as Array[String])
	rig.answers.answers = [1]  # Push apart.
	await rig.use(rig.player(), &"verve_magnet", [Vector2i(3, 0)])
	assert_eq(rig.enemy().cell, Vector2i(4, 0), "Only 1 square before the wall")
	assert_eq(rig.player().cell, Vector2i(1, 0))


func test_adrenal_surge_refreshes_and_spares_the_next_skill() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	var ally := rig.ally()
	await rig.equip(ally, BT)
	var rage := rig.skill(ally, &"rage_strike")
	ally.cooldowns[rage.id] = 3
	rig.answers.answers = [0]  # Refresh Rage Strike (the only one waiting).
	assert_true(await rig.use(rig.player(), &"adrenal_surge", [ally.cell]))
	assert_eq(ally.cooldown_left(rage), 0, "Refreshed")
	assert_eq(ally.actions.skill, 2, "Gained a skill action")
	assert_true(await rig.use(ally, &"rage_strike", [Vector2i(2, 0)]))
	assert_eq(ally.cooldown_left(rage), 0, "Not exhausted after use")
	assert_true(await rig.use(ally, &"rending_claws", [Vector2i(2, 0)]))
	assert_eq(ally.cooldown_left(rig.skill(ally, &"rending_claws")), 2, "Only the next one")
	assert_eq(rig.player().cooldown_left(rig.skill(rig.player(), &"adrenal_surge")), 4)


func test_verve_magnet_only_affects_units_that_moved() -> void:
	var rig := await _rig(["P E"] as Array[String])
	_hp(rig.player(), 10)
	rig.answers.answers = [0]  # Pull together: already touching.
	await rig.use(rig.player(), &"verve_magnet", [Vector2i(1, 0)])
	assert_eq(rig.enemy().hp, 12)
	assert_eq(rig.player().hp, 10)


func test_adrenal_surge_needs_another_ally() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	var surge := rig.skill(rig.player(), &"adrenal_surge")
	assert_false(rig.resolver.has_targets(rig.player(), surge), "Not on himself")

#endregion

#region Recovery and Ultimate

func test_violent_transfusion_drains_a_foe_into_an_ally() -> void:
	var rig := await _rig(["P . A . E"] as Array[String])
	rig.enemy().hp = 20
	_hp(rig.ally(), 2)
	assert_true(await rig.use(rig.player(), &"violent_transfusion", [Vector2i(4, 0), rig.ally().cell]))
	assert_eq(rig.enemy().hp, 12, "Loses Gold + Gold = 8")
	assert_eq(rig.ally().hp, 10, "Heals what was lost")


func test_violent_transfusion_kill_bonus_and_self_target() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 5
	_hp(rig.player(), 1)
	await rig.use(rig.player(), &"violent_transfusion", [Vector2i(2, 0), rig.player().cell])
	assert_false(rig.enemy().is_alive())
	assert_eq(rig.player().hp, 8, "5 lost + 2 for the kill")


func test_only_two_recoveries_per_team_per_battle() -> void:
	var rig := await _rig(["P . A . E"] as Array[String])
	rig.enemy().hp = 99
	var transfusion := rig.skill(rig.player(), &"violent_transfusion")
	for i in 2:
		rig.player().actions.refresh()
		assert_true(await rig.use(rig.player(), &"violent_transfusion", [Vector2i(4, 0), rig.ally().cell]))
	rig.player().actions.refresh()
	assert_false(rig.resolver.can_use(rig.player(), transfusion), "Team limit reached")
	assert_eq(rig.resolver.recoveries_left(Enums.Team.PLAYER), 0)
	assert_eq(rig.resolver.recoveries_left(Enums.Team.ENEMY), 2)


func test_ai_doesnt_freeze_when_its_recovery_is_used_up() -> void:
	# The foe is within Transfusion's 5 squares but out of every other reach.
	var rig := await _rig(["P . . . . E"] as Array[String])
	_hp(rig.player(), 4)
	rig.resolver.recoveries_used[Enums.Team.PLAYER] = 2
	rig.player().cooldowns[&"acute_coagulant"] = 1  # Otherwise it would heal first.
	var plan := AiPlanner.next_action(rig.board, rig.resolver, rig.player())
	assert_not_null(plan, "Moves in to attack instead of waiting for Transfusion")
	assert_true(plan.is_move())


func test_bloodrage_turns_damage_dealt_into_power_once_per_battle() -> void:
	var rig := await _rig(["P E"] as Array[String])
	rig.enemy().hp = 50
	await rig.use(rig.player(), &"blade_fury", [Vector2i(1, 0)])
	var points := rig.player().actions.skill + rig.player().actions.flex
	assert_true(await rig.use(rig.player(), &"bloodrage"))
	assert_eq(rig.player().actions.skill + rig.player().actions.flex, points + 1, "Free, and +1 skill action")
	assert_eq(rig.player().get_stat(&"strike_power"), 4, "4 damage dealt so far")
	await rig.use(rig.player(), &"blade_fury", [Vector2i(1, 0)])
	assert_eq(rig.enemy().hp, 50 - 4 - 8, "Blade Fury 4 + 4 Power")
	assert_false(rig.resolver.can_use(rig.player(), rig.skill(rig.player(), &"bloodrage")), "Once per battle")
	_hp(rig.player(), 1)
	rig.player().cooldowns.clear()
	await rig.use(rig.player(), &"acute_coagulant")
	assert_eq(rig.player().hp, 4, "Strikes only: heals don't get the bonus")
	await rig.new_round()
	assert_eq(rig.player().get_stat(&"strike_power"), 0, "Until end of turn")

#endregion

#region Bound in Blood

func _second_hit(rig: TestRig) -> void:
	rig.enemy().hp = 30
	await rig.use(rig.player(), &"blade_fury", [rig.enemy().cell])
	await rig.use(rig.player(), &"blade_fury", [rig.enemy().cell])


func test_no_pact_on_the_first_strike() -> void:
	var rig := await _rig(["P E"] as Array[String])
	rig.enemy().hp = 30
	await rig.use(rig.player(), &"blade_fury", [Vector2i(1, 0)])
	assert_eq(rig.answers.asked.size(), 0)


func test_second_strike_on_the_same_foe_offers_a_pact() -> void:
	var rig := await _rig(["P E"] as Array[String])
	rig.answers.answers = [VAMPIRIC]
	_hp(rig.player(), 5)
	await _second_hit(rig)
	assert_eq(rig.answers.titles(), ["Bound in Blood"] as Array[String])
	assert_eq(rig.answers.asked[0].options.size(), 3)
	assert_eq(rig.enemy().hp, 30 - 4 - 4 - 1, "Vampiric: the foe loses 1")
	assert_eq(rig.player().hp, 6, "and he heals 1")
	assert_lt(rig.answers.events_when_asked[0], rig.log.types.size(), "Asked after the hits played")


func test_dominance_provokes_and_armors() -> void:
	var rig := await _rig(["P E"] as Array[String])
	rig.answers.answers = [DOMINANCE]
	await _second_hit(rig)
	var provoke := rig.enemy().find_status(&"provoke")
	assert_not_null(provoke)
	assert_eq(provoke.link, rig.player(), "Provoked by the Bloodthane")
	assert_eq(rig.player().get_stat(&"armor"), 1)
	await rig.new_turn(rig.enemy())
	assert_true(rig.enemy().has_status(&"provoke"), "Lasts through the foe's phase")
	await rig.new_round()
	assert_false(rig.enemy().has_status(&"provoke"))
	assert_eq(rig.player().get_stat(&"armor"), 0)


func test_predation_cripples_then_lets_him_shift() -> void:
	var rig := await _rig([
		". . .",
		"P E .",
	] as Array[String])
	rig.answers.answers = [PREDATION, 0]  # Predation, then "Shift up".
	await _second_hit(rig)
	assert_true(rig.enemy().has_status(&"cripple"))
	assert_eq(rig.answers.asked.size(), 2)
	assert_eq(rig.player().cell, Vector2i(0, 0), "Shifted up 1")


func test_each_pact_once_per_turn() -> void:
	var rig := await _rig(["P E"] as Array[String])
	rig.answers.answers = [VAMPIRIC, 0]  # Then the first of what's left.
	await _second_hit(rig)
	rig.player().actions.refresh()
	await rig.use(rig.player(), &"blade_fury", [rig.enemy().cell])
	assert_eq(rig.answers.asked.size(), 2)
	var labels: Array[String] = []
	for o in rig.answers.asked[1].options:
		labels.append(o.label)
	assert_eq(labels, ["Dominance Pact", "Predation Pact"] as Array[String], "Vampiric used this turn")
	await rig.new_turn(rig.player())
	await _second_hit(rig)
	assert_eq(rig.answers.asked[2].options.size(), 3, "All three again next turn")


func test_remembered_pact_binds_without_asking() -> void:
	var rig := await _rig(["P E"] as Array[String])
	rig.answers.answers = [VAMPIRIC]
	rig.answers.remember_next = true
	await _second_hit(rig)
	var passive := rig.player().find_status(&"bound_in_blood")
	assert_eq(passive.choice, VAMPIRIC)
	await rig.new_turn(rig.player())
	rig.answers.remember_next = false
	await _second_hit(rig)
	assert_eq(rig.answers.asked.size(), 1, "Second turn: no question")
	assert_eq(rig.enemy().hp, 30 - 8 - 1)


func test_killing_blow_binds_nothing() -> void:
	var rig := await _rig(["P E"] as Array[String])
	rig.enemy().hp = 6
	await rig.use(rig.player(), &"blade_fury", [Vector2i(1, 0)])
	await rig.use(rig.player(), &"blade_fury", [Vector2i(1, 0)])
	assert_false(rig.enemy().is_alive())
	assert_eq(rig.answers.asked.size(), 0)


func test_provoked_enemy_ai_attacks_the_bloodthane() -> void:
	var rig := await _rig(["P E A"] as Array[String])
	rig.answers.answers = [DOMINANCE]
	await _second_hit(rig)
	var foe := rig.enemy()
	foe.def.skills = [CLAW]
	rig.ally().hp = 1  # A tempting kill...
	var plan := AiPlanner.best_attack(rig.board, rig.resolver, foe)
	assert_eq(plan.picks, TestRig.cells([rig.player().cell]), "...but Provoke wins")

#endregion
