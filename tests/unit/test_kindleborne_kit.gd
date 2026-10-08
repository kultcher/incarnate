extends GutTest
## The Kindleborne's 2014 kit (flat tiers: Bronze 2, Silver 3, Gold 4):
## Rising Heat (the counter rework), Stoke (Ignite and Dissipate) and every
## skill.

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


func _heat(rig: TestRig, amount: int) -> void:
	rig.player().heat = amount


func _points(unit: UnitState) -> int:
	return unit.actions.move + unit.actions.skill + unit.actions.flex


#region Rising Heat

func test_each_paid_skill_adds_one_heat() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 40
	assert_true(await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell]))
	assert_eq(rig.player().heat, 1)
	assert_true(await rig.use(rig.player(), &"tinderbolt", [rig.enemy().cell]))
	assert_eq(rig.player().heat, 2)


func test_heat_stops_at_five() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	_heat(rig, 5)
	rig.enemy().hp = 40
	await rig.use(rig.player(), &"tinderbolt", [rig.enemy().cell])
	assert_eq(rig.player().heat, 5)


func test_stoke_needs_enough_heat() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	var stoke := rig.skill(rig.player(), &"stoke")
	_heat(rig, 1)
	assert_false(rig.resolver.can_use(rig.player(), stoke), "1 isn't enough")
	_heat(rig, 2)
	assert_true(rig.resolver.can_use(rig.player(), stoke))


func test_ignite_makes_the_next_skill_free_and_costs_more_each_time() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 60
	_heat(rig, 3)
	rig.answers.answers = [IGNITE]
	assert_true(await rig.use(rig.player(), &"stoke"))
	assert_eq(rig.player().heat, 1, "Ignite cost 2")
	assert_true(rig.player().has_status(&"ignite"))
	var points := _points(rig.player())
	assert_true(await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell]))
	assert_eq(_points(rig.player()), points, "Free")
	assert_eq(rig.player().heat, 1, "An Ignited skill makes no Heat")
	assert_false(rig.player().has_status(&"ignite"), "Used up")
	var heat := rig.player().find_status(&"rising_heat")
	assert_eq((heat.def.behavior as RisingHeatBehavior).current_ignite_cost(heat), 3, "+1 this turn")
	await rig.new_turn(rig.player())
	assert_eq((heat.def.behavior as RisingHeatBehavior).current_ignite_cost(heat), 2, "Back to 2")


func test_dissipate_heals_and_grants_evasion() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.player().hp = 5
	_heat(rig, 2)
	rig.answers.answers = [DISSIPATE]
	assert_true(await rig.use(rig.player(), &"stoke"))
	assert_eq(rig.player().hp, 8, "Healed 3")
	assert_eq(rig.player().get_stat(&"evasion"), 1)
	assert_eq(rig.player().heat, 0)


func test_stoking_blast_recharges_when_ignited() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 60
	var blast := rig.skill(rig.player(), &"stoking_blast")
	_heat(rig, 2)
	rig.answers.answers = [IGNITE]
	await rig.use(rig.player(), &"stoke")
	await rig.use(rig.player(), &"stoking_blast", [rig.enemy().cell])
	assert_eq(rig.player().cooldown_left(blast), 1, "Recharge 2, recharged by 1")


func test_igniting_recharges_flickerstep() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	var step := rig.skill(rig.player(), &"flickerstep")
	rig.player().cooldowns[step.id] = 3
	_heat(rig, 2)
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


func test_wracking_flame_gains_power_per_heat() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.enemy().hp = 60
	_heat(rig, 3)
	await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell])
	assert_eq(rig.enemy().hp, 60 - 9, "Silver + Silver, +3 Power")


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


func test_flickerstep_grants_a_teleport() -> void:
	var rig := await _rig(["P . . . . . . . . E"] as Array[String])
	assert_true(await rig.use(rig.player(), &"flickerstep"))
	assert_eq(rig.player().find_status(&"flicker").stacks, 6, "Gold 4 + 2")
	assert_eq(rig.player().heat, 1, "A paid skill (a move action)")
	assert_true(await rig.use(rig.player(), &"flicker", [Vector2i(6, 0)]))
	assert_eq(rig.player().cell, Vector2i(6, 0))
	assert_null(rig.skill(rig.player(), &"flicker"), "One use")
	assert_eq(rig.player().actions.move + rig.player().actions.flex, 1, "Flickerstep cost the move")


func test_ash_augur_gains_two_heat() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	_heat(rig, 1)
	assert_true(await rig.use(rig.player(), &"ash_augur"))
	assert_eq(rig.player().heat, 3, "Free, so no Heat of its own")


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
	_heat(rig, 2)
	rig.answers.answers = [IGNITE]
	await rig.use(rig.player(), &"stoke")
	await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell])
	assert_eq(rig.player().cooldown_left(wracking), 2)
	assert_true(rig.resolver.can_use(rig.player(), wracking), "Replay ignores the recharge")
	var points := _points(rig.player())
	var heat_before := rig.player().heat
	assert_true(await rig.use(rig.player(), &"wracking_flame", [rig.enemy().cell]))
	assert_eq(_points(rig.player()), points, "Free")
	assert_eq(rig.player().heat, heat_before, "Replays make no Heat")
	assert_false(rig.resolver.can_use(rig.player(), wracking), "Only once")
	assert_eq(rig.player().find_status(&"burnout").stacks, 2, "Two Ignites left")

#endregion


func test_the_ai_ignites_for_extra_attacks() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.answers.use_ai = true
	rig.enemy().def.max_hp = 80  # The AI's scoring assumes HP <= max.
	rig.enemy().hp = 80
	_heat(rig, 5)
	var used: Array[StringName] = []
	for i in 8:
		var plan := AiPlanner.next_action(rig.board, rig.resolver, rig.player())
		if plan == null:
			break
		if plan.is_move():
			await rig.resolver.request_move(rig.player(), plan.move_to)
			continue
		used.append(plan.skill.id)
		await rig.resolver.request_skill(rig.player(), plan.skill, plan.picks)
	assert_has(used, &"stoke", "Spent Heat: %s" % [used])
	var attacks := used.filter(func(id: StringName) -> bool: return id != &"stoke")
	assert_gt(attacks.size(), 2, "Skill, flex, then Ignited attacks: %s" % [used])
	var heat := rig.player().find_status(&"rising_heat")
	assert_gt((heat.def.behavior as RisingHeatBehavior).current_ignite_cost(heat), 2,
			"Each Ignite this turn costs more")


func test_a_second_flickerstep_replaces_the_range() -> void:
	var rig := await _rig(["P . . . . . . . . E"] as Array[String])
	var step := rig.skill(rig.player(), &"flickerstep")
	assert_true(await rig.use(rig.player(), &"flickerstep"))
	rig.player().find_status(&"flicker").stacks = 2  # As if the first draw was low.
	rig.player().cooldowns.erase(step.id)
	rig.player().actions.refresh()
	assert_true(await rig.use(rig.player(), &"flickerstep"))
	assert_eq(rig.player().find_status(&"flicker").stacks, 6, "The new draw's range")


func test_a_burnout_replay_ignores_a_spent_recovery_pool() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	var brand := rig.skill(rig.player(), &"cauterizing_brand")
	assert_true(await rig.use(rig.player(), &"burnout"))
	rig.resolver.recoveries_used[Enums.Team.PLAYER] = 1
	_heat(rig, 2)
	rig.answers.answers = [IGNITE]
	await rig.use(rig.player(), &"stoke")
	assert_true(await rig.use(rig.player(), &"cauterizing_brand", [rig.ally().cell]))
	assert_eq(rig.resolver.recoveries_left(Enums.Team.PLAYER), 0, "The team's last Recovery")
	assert_true(rig.resolver.can_use(rig.player(), brand), "The free replay still works")


func test_a_fallen_kindleborne_loses_its_heat() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	_heat(rig, 4)
	rig.resolver.lose_health(rig.player(), 99)
	assert_eq(rig.player().heat, 0)
