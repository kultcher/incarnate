extends GutTest
## The Soulweaver's 2014 kit (cards at their medians: Bronze 2, Silver 3,
## Gold 4): Tether, Fates Intertwined's Infusions and every skill.

const SW := preload("res://content/units/soulweaver.tres")
const BT := preload("res://content/units/bloodthane.tres")

## Fates Intertwined's Infusions, in order.
const POTENT := 0
const STALWART := 1
const SAGE := 2
const ELUSIVE := 3


## The Soulweaver is P; A (if any) is a Bloodthane.
func _rig(rows: Array[String]) -> TestRig:
	var rig := TestRig.make(self, rows)
	await rig.equip(rig.player(), SW)
	await rig.new_turn(rig.player())
	if not rig.fixture.allies.is_empty():
		await rig.equip(rig.ally(), BT)
		await rig.new_turn(rig.ally())
	return rig


## Tethers to the first ally, outside the turn's action points (it's free).
func _tether(rig: TestRig) -> void:
	assert_true(await rig.use(rig.player(), &"tether", [rig.ally().cell]))


#region Tether

func test_tether_links_the_soulweaver_and_an_ally() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	await _tether(rig)
	assert_eq(Tethers.allies_of(rig.player(), rig.board), [rig.ally()] as Array[UnitState])
	assert_true(rig.ally().has_status(Tethers.TETHERED))
	assert_eq(rig.player().actions.skill + rig.player().actions.flex, 2, "Free")
	assert_false(rig.resolver.can_use(rig.player(), rig.skill(rig.player(), &"tether")),
			"Once per turn")


func test_a_new_tether_ends_the_old_one() -> void:
	var rig := await _rig(["P A A E"] as Array[String])
	await _tether(rig)
	await rig.new_turn(rig.player())
	await rig.equip(rig.ally(1), BT)
	assert_true(await rig.use(rig.player(), &"tether", [rig.ally(1).cell]))
	assert_eq(Tethers.allies_of(rig.player(), rig.board), [rig.ally(1)] as Array[UnitState])
	assert_false(rig.ally(0).has_status(Tethers.TETHERED))


func test_the_tether_ends_when_the_ally_dies() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	await _tether(rig)
	rig.resolver.lose_health(rig.ally(), 99)
	assert_true(Tethers.allies_of(rig.player(), rig.board).is_empty())
	assert_false(rig.player().has_status(Tethers.TETHER))

#endregion

#region Spirit Flare

func test_spirit_flare_strikes_a_foe_or_heals_an_ally() -> void:
	var rig := await _rig([". E", "P A"] as Array[String])
	assert_true(await rig.use(rig.player(), &"spirit_flare", [rig.enemy().cell]))
	assert_eq(rig.enemy().hp, 9, "Silver 3")
	rig.ally().hp = 5
	await rig.new_turn(rig.player())
	assert_true(await rig.use(rig.player(), &"spirit_flare", [rig.ally().cell]))
	assert_eq(rig.ally().hp, 8, "Healed Silver 3")


func test_a_kill_makes_the_next_spirit_flare_free_once_per_turn() -> void:
	var rig := await _rig(["P E E"] as Array[String])
	rig.enemy(0).hp = 3
	assert_true(await rig.use(rig.player(), &"spirit_flare", [rig.enemy(0).cell]))
	assert_true(rig.player().has_status(&"flare_ready"))
	var points := rig.player().actions.skill + rig.player().actions.flex
	assert_eq(rig.resolver.cost_of(rig.player(), rig.skill(rig.player(), &"spirit_flare")),
			Enums.Cost.FREE)
	rig.enemy(1).hp = 3
	assert_true(await rig.use(rig.player(), &"spirit_flare", [rig.enemy(1).cell]))
	assert_eq(rig.player().actions.skill + rig.player().actions.flex, points, "Free")
	assert_false(rig.player().has_status(&"flare_ready"), "Used up, and only once per turn")


func test_healing_an_ally_to_full_readies_spirit_flare() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	rig.ally().hp = rig.ally().get_stat(&"max_hp") - 2
	assert_true(await rig.use(rig.player(), &"spirit_flare", [rig.ally().cell]))
	assert_true(rig.player().has_status(&"flare_ready"))

#endregion

#region Fates Intertwined

func test_unveiling_a_card_offers_an_infusion_once_per_turn() -> void:
	var rig := await _rig([". E", "P A"] as Array[String])
	rig.enemy().hp = 40
	await _tether(rig)
	rig.answers.answers = [STALWART]
	await rig.use(rig.player(), &"spirit_flare", [rig.enemy().cell])
	assert_eq(rig.answers.titles(), ["Fates Intertwined"] as Array[String])
	assert_eq(rig.player().find_status(&"shield").stacks, 1)
	assert_eq(rig.ally().find_status(&"shield").stacks, 1, "The Tethered ally too")
	await rig.use(rig.player(), &"spirit_flare", [rig.enemy().cell])
	assert_eq(rig.answers.asked.size(), 1, "Once per turn")
	await rig.new_turn(rig.player())
	await rig.use(rig.player(), &"spirit_flare", [rig.enemy().cell])
	assert_eq(rig.answers.asked.size(), 2, "Again next turn")


func test_declining_keeps_the_infusion_for_a_later_unveil() -> void:
	var rig := await _rig(["P E"] as Array[String])
	rig.enemy().hp = 40
	await rig.use(rig.player(), &"spirit_flare", [rig.enemy().cell])
	rig.answers.answers = [STALWART]
	await rig.use(rig.player(), &"spirit_flare", [rig.enemy().cell])
	assert_eq(rig.answers.asked.size(), 2)
	assert_true(rig.player().has_status(&"shield"), "Untethered: just the Soulweaver")


func test_potent_gives_a_free_basic_attack_to_both() -> void:
	var rig := await _rig([". E", "P A"] as Array[String])
	rig.enemy().hp = 40
	await _tether(rig)
	rig.answers.answers = [POTENT]
	await rig.use(rig.player(), &"spirit_flare", [rig.enemy().cell])
	var bt := rig.ally()
	assert_eq(rig.resolver.cost_of(bt, rig.skill(bt, &"blade_fury")), Enums.Cost.FREE)
	assert_eq(rig.resolver.cost_of(bt, rig.skill(bt, &"rending_claws")), Enums.Cost.SKILL,
			"Only basic attacks")
	assert_true(await rig.use(bt, &"blade_fury", [rig.enemy().cell]))
	assert_eq(bt.actions.skill, 1, "The Blade Fury was free")
	assert_eq(rig.resolver.cost_of(bt, rig.skill(bt, &"blade_fury")), Enums.Cost.SKILL, "Once")


func test_sage_recharges_a_skill_each() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	rig.enemy().hp = 40
	await _tether(rig)
	var rending := rig.skill(rig.ally(), &"rending_claws")
	rig.ally().cooldowns[rending.id] = 2
	rig.player().cooldowns[&"soul_echo"] = 2
	rig.answers.answers = [SAGE]
	assert_true(await rig.use(rig.player(), &"spirit_flare", [rig.enemy().cell]))
	assert_eq(rig.ally().cooldown_left(rending), 1)
	assert_eq(rig.player().cooldowns[&"soul_echo"], 1)


func test_elusive_grants_a_free_shift_of_two() -> void:
	var rig := await _rig([". . . E", "P A . ."] as Array[String])
	rig.enemy().hp = 40
	await _tether(rig)
	rig.answers.answers = [ELUSIVE]
	await rig.use(rig.player(), &"spirit_flare", [rig.enemy().cell])
	var bt := rig.ally()
	var shift := rig.skill(bt, &"elusive_shift")
	assert_not_null(shift, "On the ally's bar while Elusive lasts")
	assert_true(await rig.use(bt, &"elusive_shift", [Vector2i(3, 1)]))
	assert_eq(bt.cell, Vector2i(3, 1))
	assert_null(rig.skill(bt, &"elusive_shift"), "One use")
	assert_eq(bt.actions.move + bt.actions.skill + bt.actions.flex, 3, "Free")

#endregion

#region Skills

func test_soul_echo_gains_power_per_blade_in_the_row() -> void:
	var rig := await _rig(["P . . E"] as Array[String])
	rig.enemy().hp = 40
	var row := rig.resolver.soulstream(Enums.Team.PLAYER).row
	row.append(Card.new(Enums.Tier.SILVER, 3, Enums.Suit.BLADE))
	row.append(Card.new(Enums.Tier.GOLD, 4, Enums.Suit.BLADE))
	row.append(Card.new(Enums.Tier.GOLD, 4, Enums.Suit.WARD))
	assert_true(await rig.use(rig.player(), &"soul_echo", [rig.enemy().cell]))
	assert_eq(rig.enemy().hp, 40 - (6 + 4), "Silver + Silver, +2 Power per Blade")


func test_dread_diffusion_forces_the_target_and_splashes() -> void:
	var rig := await _rig([
		"P E . . .",
		". . E . .",
	] as Array[String])
	var target := rig.enemy(0)
	var bystander := rig.enemy(1)
	target.hp = 20
	assert_true(await rig.use(rig.player(), &"dread_diffusion", [target.cell]))
	assert_eq(target.hp, 15, "Silver + Bronze")
	assert_eq(target.cell, Vector2i(4, 0), "Forced 3 away")
	assert_eq(bystander.hp, 10, "Next to the path: struck for Bronze")
	assert_ne(bystander.cell, Vector2i(2, 1), "And forced 1")


func test_strength_in_unity_shields_and_recharges_when_tethered() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	var unity := rig.skill(rig.player(), &"strength_in_unity")
	assert_true(await rig.use(rig.player(), &"strength_in_unity", [rig.ally().cell]))
	assert_eq(rig.player().find_status(&"shield").stacks, 4, "Gold")
	assert_eq(rig.ally().find_status(&"shield").stacks, 4)
	assert_eq(rig.player().cooldown_left(unity), 3, "Not tethered: full recharge")

	await rig.new_turn(rig.player())
	rig.player().cooldowns.clear()
	await _tether(rig)
	assert_true(await rig.use(rig.player(), &"strength_in_unity", [rig.ally().cell]))
	assert_eq(rig.player().cooldown_left(unity), 2, "Tethered: recharges by 1")
	assert_eq(rig.ally().find_status(&"shield").stacks, 8, "Shields add up")


func test_a_shield_absorbs_strikes_until_used_up() -> void:
	var rig := await _rig(["P E"] as Array[String])
	var shield := load("res://content/statuses/common/shield.tres") as StatusDef
	await rig.resolver.apply_status(rig.player(), shield, rig.player(), null, 4)
	var spec := StrikeSpec.cards([Enums.Tier.SILVER] as Array[Enums.Tier])
	await rig.resolver.strike(rig.enemy(), rig.player(), spec)
	assert_eq(rig.player().hp, 12, "3 absorbed")
	assert_eq(rig.player().find_status(&"shield").stacks, 1)
	await rig.resolver.strike(rig.enemy(), rig.player(), spec)
	assert_eq(rig.player().hp, 10, "1 absorbed, 2 through")
	assert_false(rig.player().has_status(&"shield"))


func test_essence_shift_moves_either_one_next_to_the_other() -> void:
	var rig := await _rig([
		"P . . . A",
		". . . . E",
	] as Array[String])
	assert_false(rig.resolver.has_targets(rig.player(), rig.skill(rig.player(), &"essence_shift")),
			"Needs a Tether")
	await _tether(rig)
	assert_true(await rig.use(rig.player(), &"essence_shift", [rig.player().cell, Vector2i(3, 0)]))
	assert_eq(rig.player().cell, Vector2i(3, 0))
	await rig.new_turn(rig.player())
	rig.player().cooldowns.clear()
	assert_true(await rig.use(rig.player(), &"essence_shift", [rig.ally().cell, Vector2i(2, 0)]))
	assert_eq(rig.ally().cell, Vector2i(2, 0), "The ally came to the Soulweaver")


func test_well_of_souls_lets_both_take_a_row_card() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	await _tether(rig)
	var row := rig.resolver.soulstream(Enums.Team.PLAYER).row
	var low := Card.new(Enums.Tier.BRONZE, 1)
	var high := Card.new(Enums.Tier.GOLD, 5)
	row.append_array([low, high])
	rig.answers.answers = [1, 0]
	assert_true(await rig.use(rig.player(), &"well_of_souls"))
	assert_eq(rig.player().hand, [high] as Array[Card])
	assert_eq(rig.ally().hand, [low] as Array[Card])
	assert_true(row.is_empty())


func test_conveyance_turns_given_health_into_healing() -> void:
	var rig := await _rig(["P A A E"] as Array[String])
	await rig.equip(rig.ally(1), BT)
	var chosen := rig.ally(1)
	chosen.hp = 2
	rig.answers.answers = [0, 0]  # The Soulweaver and the other ally each give 1.
	assert_true(await rig.use(rig.player(), &"conveyance", [chosen.cell]))
	assert_eq(rig.player().hp, 11)
	assert_eq(rig.ally(0).hp, 11)
	assert_eq(chosen.hp, 12, "Healed (Si)(Si) twice: 2 + 12, capped at 12")


func test_anima_nexus_makes_every_ally_tethered() -> void:
	var rig := await _rig(["P A A E"] as Array[String])
	await rig.equip(rig.ally(1), BT)
	rig.enemy().hp = 40
	assert_true(await rig.use(rig.player(), &"anima_nexus"))
	assert_eq(Tethers.allies_of(rig.player(), rig.board).size(), 2)
	rig.answers.answers = [STALWART]
	await rig.use(rig.player(), &"spirit_flare", [rig.enemy().cell])
	for unit: UnitState in [rig.player(), rig.ally(0), rig.ally(1)]:
		assert_true(unit.has_status(&"shield"), "%s infused" % unit)
	await rig.new_round()
	assert_true(Tethers.allies_of(rig.player(), rig.board).is_empty(), "Only this turn")

#endregion
