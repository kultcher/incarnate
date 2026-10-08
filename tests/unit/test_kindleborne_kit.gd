extends GutTest
## The Kindleborne's 2014 kit (cards at their medians: Bronze 2, Silver 3,
## Gold 4): Rising Heat, Stoke (Ignite and Dissipate) and every skill.

const KB := preload("res://content/units/kindleborne.tres")
const BT := preload("res://content/units/bloodthane.tres")

const IGNITE := 0
const DISSIPATE := 1


## The Kindleborne is P; A (if any) is a Bloodthane.
func _rig(rows: Array[String]) -> TestRig:
	var rig := TestRig.make(self, rows)
	await rig.equip(rig.player(), KB)
	await rig.new_turn(rig.player())
	if not rig.fixture.allies.is_empty():
		await rig.equip(rig.ally(), BT)
		await rig.new_turn(rig.ally())
	return rig


func _heat(rig: TestRig, values: Array) -> void:
	rig.player().heat.clear()
	for v: int in values:
		rig.player().heat.append(Card.new(Enums.Tier.SILVER, v))


func _values(cards: Array[Card]) -> Array[int]:
	var out: Array[int] = []
	for card in cards:
		out.append(card.value)
	return out


func _points(unit: UnitState) -> int:
	return unit.actions.move + unit.actions.skill + unit.actions.flex


#region Rising Heat

func test_unveiled_cards_are_stored_as_heat() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 40
	assert_true(await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell]))
	assert_eq(_values(rig.player().heat), [3, 3] as Array[int], "Both Silver cards stored")


func test_heat_keeps_the_best_five() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	_heat(rig, [5, 4, 4, 2, 1])
	rig.enemy().hp = 40
	await rig.use(rig.player(), &"tinderbolt", [rig.enemy().cell])
	assert_eq(_values(rig.player().heat), [5, 4, 4, 2, 2] as Array[int], "The 1 dropped for a 2")


func test_stored_cards_leave_the_discards() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.resolver.use_decks(3)
	rig.enemy().hp = 40
	await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell])
	var silver := rig.resolver.soulstream(Enums.Team.PLAYER).deck(Enums.Tier.SILVER)
	assert_eq(silver.discard_pile.size(), 0, "Held as Heat, not discarded")
	assert_eq(silver.draw_pile.size(), 58)


func test_stoke_needs_enough_heat() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	var stoke := rig.skill(rig.player(), &"stoke")
	_heat(rig, [2, 2])
	assert_false(rig.resolver.can_use(rig.player(), stoke), "4 isn't enough")
	_heat(rig, [3, 2])
	assert_true(rig.resolver.can_use(rig.player(), stoke))


func test_ignite_makes_the_next_skill_free_and_costs_more_each_time() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 60
	_heat(rig, [4, 3, 2, 1])
	rig.answers.answers = [IGNITE]
	assert_true(await rig.use(rig.player(), &"stoke"))
	assert_eq(_values(rig.player().heat), [4] as Array[int], "Lowest first: 1 + 2 + 3 = 6")
	assert_true(rig.player().has_status(&"ignite"))
	var points := _points(rig.player())
	assert_true(await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell]))
	assert_eq(_points(rig.player()), points, "Free")
	assert_false(rig.player().has_status(&"ignite"), "Used up")
	var heat := rig.player().find_status(&"rising_heat")
	assert_eq((heat.def.behavior as RisingHeatBehavior).current_ignite_cost(heat), 6, "+1 this turn")
	await rig.new_turn(rig.player())
	assert_eq((heat.def.behavior as RisingHeatBehavior).current_ignite_cost(heat), 5, "Back to 5")


func test_dissipate_heals_and_grants_evasion() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.player().hp = 5
	_heat(rig, [5])
	rig.answers.answers = [DISSIPATE]
	assert_true(await rig.use(rig.player(), &"stoke"))
	assert_eq(rig.player().hp, 8, "Healed Silver 3")
	assert_eq(rig.player().get_stat(&"evasion"), 1)
	assert_eq(_values(rig.player().heat), [3] as Array[int], "The heal's card became Heat")


func test_stoking_blast_recharges_when_ignited() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 60
	var blast := rig.skill(rig.player(), &"stoking_blast")
	_heat(rig, [5])
	rig.answers.answers = [IGNITE]
	await rig.use(rig.player(), &"stoke")
	await rig.use(rig.player(), &"stoking_blast", [rig.enemy().cell])
	assert_eq(rig.player().cooldown_left(blast), 1, "Recharge 2, recharged by 1")


func test_igniting_recharges_flickerstep() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	var step := rig.skill(rig.player(), &"flickerstep")
	rig.player().cooldowns[step.id] = 3
	_heat(rig, [5])
	rig.answers.answers = [IGNITE]
	await rig.use(rig.player(), &"stoke")
	assert_eq(rig.player().cooldown_left(step), 2)

#endregion

#region Skills

func test_tinderbolt_gains_power_per_prior_attack() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 60
	assert_true(await rig.use(rig.player(), &"tinderbolt", [rig.enemy().cell]))
	assert_eq(rig.enemy().hp, 58, "Bronze 2")
	assert_true(await rig.use(rig.player(), &"tinderbolt", [rig.enemy().cell]))
	assert_eq(rig.enemy().hp, 55, "One attack before: +1 Power")


func test_wracking_flame_gains_power_from_the_highest_heat() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 60
	_heat(rig, [2, 5, 3])
	await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell])
	assert_eq(rig.enemy().hp, 60 - 11, "Silver + Silver, +5 Power")


func test_cinder_wave_strikes_each_foe_in_the_wave() -> void:
	var rig := await _rig([
		". . . . . .",
		"P . . . E E",
		". . . E . .",
	] as Array[String])
	var skill := rig.skill(rig.player(), &"cinder_wave")
	var cells := skill.area.cells(rig.board, rig.player(), TestRig.cells([Vector2i(1, 1)]))
	assert_eq(cells.size(), 12, "3 wide, 4 deep")
	assert_true(await rig.use(rig.player(), &"cinder_wave", [Vector2i(1, 1)]))
	assert_eq(rig.enemy(0).hp, 9, "In the wave")
	assert_eq(rig.enemy(1).hp, 12, "Beyond 4 squares")
	assert_eq(rig.enemy(2).hp, 9, "Edge of the wave")


func test_ember_shield_shields_and_strikes_back() -> void:
	var rig := await _rig(["P E"] as Array[String])
	assert_true(await rig.use(rig.player(), &"ember_shield"))
	assert_eq(rig.player().find_status(&"shield").stacks, 4, "Gold")
	var claw := StrikeSpec.cards([Enums.Tier.GOLD, Enums.Tier.GOLD] as Array[Enums.Tier])
	await rig.resolver.strike(rig.enemy(), rig.player(), claw)
	await rig.resolver._drain_followups()
	assert_eq(rig.player().hp, 8, "8 - 4 shield")
	assert_eq(rig.enemy().hp, 9, "Struck back for Silver 3")


func test_flickerstep_unveils_a_gold_and_grants_a_teleport() -> void:
	var rig := await _rig(["P . . . . . . . . E"] as Array[String])
	assert_true(await rig.use(rig.player(), &"flickerstep"))
	assert_eq(rig.player().find_status(&"flicker").stacks, 6, "Gold 4 + 2")
	assert_eq(_values(rig.player().heat), [4] as Array[int], "The Gold became Heat")
	assert_true(await rig.use(rig.player(), &"flicker", [Vector2i(6, 0)]))
	assert_eq(rig.player().cell, Vector2i(6, 0))
	assert_null(rig.skill(rig.player(), &"flicker"), "One use")
	assert_eq(rig.player().actions.move + rig.player().actions.flex, 1, "Flickerstep cost the move")


func test_ash_augur_upgrades_heat() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.player().heat.clear()
	rig.player().heat.append(Card.new(Enums.Tier.BRONZE, 1))
	rig.player().heat.append(Card.new(Enums.Tier.SILVER, 2))
	rig.player().heat.append(Card.new(Enums.Tier.GOLD, 5))
	assert_true(await rig.use(rig.player(), &"ash_augur"))
	var tiers: Array[int] = []
	for card in rig.player().heat:
		tiers.append(int(card.tier))
	tiers.sort()
	assert_eq(tiers, [1, 2, 2] as Array[int], "Bronze to Silver, Silver to Gold, Gold stays")
	assert_eq(_values(rig.player().heat), [5, 4, 3] as Array[int], "Medians: Gold 4, Silver 3")


func test_cauterizing_brand_costs_health_then_heals_big() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	var bt := rig.ally()
	assert_true(await rig.use(rig.player(), &"cauterizing_brand", [bt.cell]))
	await rig.resolver.strike(rig.enemy(), bt, StrikeSpec.cards([Enums.Tier.BRONZE] as Array[Enums.Tier]))
	assert_eq(bt.hp, 12 - 2 - 3, "Struck for 2, then loses Silver 3 more")
	await rig.new_round()
	assert_eq(bt.hp, 12, "Healed Gold x3 (12), capped")
	assert_false(bt.has_status(&"cauterizing_brand"))


func test_burnout_lets_ignited_skills_be_replayed_free() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 80
	var wracking := rig.skill(rig.player(), &"wracking_flame")
	assert_true(await rig.use(rig.player(), &"burnout"))
	_heat(rig, [5])
	rig.answers.answers = [IGNITE]
	await rig.use(rig.player(), &"stoke")
	await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell])
	assert_eq(rig.player().cooldown_left(wracking), 2)
	assert_true(rig.resolver.can_use(rig.player(), wracking), "Replay ignores the recharge")
	var points := _points(rig.player())
	var heat_before := rig.player().heat.size()
	assert_true(await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell]))
	assert_eq(_points(rig.player()), points, "Free")
	assert_eq(rig.player().heat.size(), heat_before, "Replay cards don't become Heat")
	assert_false(rig.resolver.can_use(rig.player(), wracking), "Only once")
	assert_eq(rig.player().find_status(&"burnout").stacks, 2, "Two Ignites left")

#endregion


func test_the_ai_ignites_for_extra_attacks() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.answers.use_ai = true
	rig.enemy().def.max_hp = 80  # The AI's scoring assumes HP <= max.
	rig.enemy().hp = 80
	_heat(rig, [5, 5])
	var used: Array[StringName] = []
	for i in 8:
		var plan := AiPlanner.next_action(rig.board, rig.resolver, rig.player())
		if plan == null:
			break
		if plan.is_move():
			await rig.resolver.request_move(rig.player(), plan.move_to)
			continue
		used.append(plan.skill.id)
		await rig.resolver.request_skill(rig.player(), plan.skill, plan.picks,
				AiPlanner.choose_cards(rig.resolver, rig.player(), plan.skill))
	assert_has(used, &"stoke", "Spent Heat: %s" % [used])
	var attacks := used.filter(func(id: StringName) -> bool: return id != &"stoke")
	assert_gt(attacks.size(), 2, "Skill, flex, then Ignited attacks: %s" % [used])
	var heat := rig.player().find_status(&"rising_heat")
	assert_gt((heat.def.behavior as RisingHeatBehavior).current_ignite_cost(heat), 5,
			"Each Ignite this turn costs more")
