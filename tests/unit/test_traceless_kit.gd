extends GutTest
## The Traceless's 2014 kit: Shadows and everything that uses them.

const TL := preload("res://content/units/traceless.tres")
const CLAW := preload("res://content/skills/shambler/claw.tres")
const PROVOKE := preload("res://content/statuses/common/provoke.tres")


func _rig(rows: Array[String], move: int = 4) -> TestRig:
	var rig := TestRig.make(self, rows, move)
	await rig.equip(rig.player(), TL)
	await rig.new_turn(rig.player())
	return rig


#region Illusive Shadows

func test_shifting_leaves_a_shadow_and_walking_does_not() -> void:
	var rig := await _rig(["P . . . E"] as Array[String])
	var tl := rig.player()
	assert_true(await rig.resolver.request_move(tl, Vector2i(1, 0)))
	assert_true(tl.shadows.is_empty(), "A walk isn't a shift")
	await rig.resolver.shift_unit(tl, TestRig.cells([Vector2i(2, 0)]))
	assert_eq(tl.shadows, TestRig.cells([Vector2i(1, 0)]), "Left where the shift began")
	assert_true(rig.log.types.has(GameEvent.SHADOWS_CHANGED))


func test_at_most_three_shadows_the_oldest_fades() -> void:
	var rig := await _rig(["P . . . . E"] as Array[String])
	var tl := rig.player()
	for x in range(1, 5):
		await rig.resolver.shift_unit(tl, TestRig.cells([Vector2i(x, 0)]))
	assert_eq(tl.shadows, TestRig.cells([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]))
	rig.resolver.place_shadow(tl, Vector2i(0, 0))
	assert_eq(tl.shadows, TestRig.cells([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]).slice(1)
			+ TestRig.cells([Vector2i(0, 0)]))


func test_probability_armor_is_a_dodge_per_shadow() -> void:
	var rig := await _rig(["P . . E"] as Array[String])
	var tl := rig.player()
	assert_eq(tl.get_stat(&"evasion"), 0)
	rig.resolver.place_shadow(tl, Vector2i(1, 0))
	rig.resolver.place_shadow(tl, Vector2i(2, 0))
	assert_eq(tl.get_stat(&"evasion"), 2)
	var hit := await rig.resolver.strike(rig.enemy(), tl,
			StrikeSpec.cards([Enums.Tier.GOLD, Enums.Tier.SILVER] as Array[Enums.Tier]))
	assert_eq(hit.amount, 4, "Dodged: the Silver is cancelled")


func test_shadows_vanish_when_the_traceless_dies() -> void:
	var rig := await _rig(["P . E"] as Array[String])
	rig.resolver.place_shadow(rig.player(), Vector2i(1, 0))
	rig.resolver.lose_health(rig.player(), 99)
	assert_true(rig.player().shadows.is_empty())

#endregion

#region Displacer Strike and Shadowstrike

func test_displacer_strikes_then_shifts_when_already_adjacent() -> void:
	var rig := await _rig([
		". . .",
		"P E .",
	] as Array[String])
	assert_true(await rig.use(rig.player(), &"displacer_strike", [Vector2i(1, 1), Vector2i(2, 1)]))
	assert_eq(rig.enemy().hp, 9, "Silver 3")
	assert_eq(rig.player().cell, Vector2i(2, 1), "Shifted through the foe to the far side")
	assert_eq(rig.player().shadows, TestRig.cells([Vector2i(0, 1)]))
	var types := rig.log.types
	assert_lt(types.find(GameEvent.STRIKE), types.find(GameEvent.UNIT_MOVED), "Strike first")


func test_displacer_shifts_then_strikes_a_foe_out_of_reach() -> void:
	var rig := await _rig(["P . . E"] as Array[String])
	assert_true(await rig.use(rig.player(), &"displacer_strike", [Vector2i(3, 0), Vector2i(2, 0)]))
	assert_eq(rig.enemy().hp, 9)
	var types := rig.log.types
	assert_lt(types.find(GameEvent.UNIT_MOVED), types.find(GameEvent.STRIKE), "Shift first")


func test_displacer_can_strike_without_moving_when_boxed_in() -> void:
	var rig := await _rig([
		"# # #",
		"P E #",
		"# # #",
	] as Array[String])
	assert_true(await rig.use(rig.player(), &"displacer_strike", [Vector2i(1, 1), Vector2i(0, 1)]))
	assert_eq(rig.enemy().hp, 9)
	assert_eq(rig.player().cell, Vector2i(0, 1))
	assert_true(rig.player().shadows.is_empty(), "No shift, no Shadow")


func test_a_shadow_copies_an_attack_then_fades() -> void:
	var rig := await _rig([
		"P E .",
		". . .",
	] as Array[String])
	var tl := rig.player()
	rig.resolver.place_shadow(tl, Vector2i(1, 1))
	rig.enemy().hp = 20
	rig.answers.answers = [0]
	assert_true(await rig.use(tl, &"gloom_edge", [Vector2i(1, 0)]))
	assert_eq(rig.answers.titles(), ["Shadowstrike"] as Array[String])
	assert_eq(rig.enemy().hp, 20 - 6 - 6, "Gloom Edge 6, and the copy 6")
	assert_true(rig.enemy().has_status(&"blind"), "Struck by a copying Shadow: Blinded")
	assert_true(tl.shadows.is_empty(), "The Shadow is used up")
	var strike_from_shadow := false
	for e in rig.log.events:
		if e.type == GameEvent.STRIKE and e.path == TestRig.cells([Vector2i(1, 1)]):
			strike_from_shadow = true
	assert_true(strike_from_shadow, "The copy's strike comes from the Shadow's square")


func test_declining_keeps_the_shadow() -> void:
	var rig := await _rig(["P E ."] as Array[String])
	rig.resolver.place_shadow(rig.player(), Vector2i(2, 0))
	rig.enemy().hp = 20
	await rig.use(rig.player(), &"gloom_edge", [Vector2i(1, 0)])
	assert_eq(rig.enemy().hp, 14)
	assert_eq(rig.player().shadows.size(), 1)
	assert_false(rig.enemy().has_status(&"blind"))


func test_no_offer_when_no_shadow_is_in_reach() -> void:
	var rig := await _rig(["P E . . . ."] as Array[String])
	rig.resolver.place_shadow(rig.player(), Vector2i(5, 0))
	await rig.use(rig.player(), &"gloom_edge", [Vector2i(1, 0)])
	assert_eq(rig.answers.asked.size(), 0, "Gloom Edge copies reach 1 square")


func test_a_shadow_cant_copy_the_use_that_made_it() -> void:
	var rig := await _rig([
		". . . . . .",
		"P E . . . .",
	] as Array[String])
	var tl := rig.player()
	rig.enemy().hp = 20
	rig.answers.answers = [0]
	# Strike, shift to the far side: the Shadow left behind can't copy it.
	assert_true(await rig.use(tl, &"displacer_strike", [Vector2i(1, 1), Vector2i(2, 1)]))
	assert_eq(rig.answers.asked.size(), 0, "No offer: the only Shadow came from this use")
	assert_eq(rig.enemy().hp, 20 - 3)

	# The next use of the same skill can be copied by it.
	tl.start_turn()
	rig.answers.answers = [0]
	assert_true(await rig.use(tl, &"displacer_strike", [Vector2i(1, 1), Vector2i(1, 0)]))
	assert_eq(rig.answers.titles(), ["Shadowstrike"] as Array[String], "The older Shadow copies")
	assert_eq(rig.enemy().hp, 20 - 3 - 3 - 3)
	assert_eq(tl.shadows, TestRig.cells([Vector2i(2, 1)]), "This use's own Shadow is left")


func test_displacer_copies_reach_further() -> void:
	var rig := await _rig([
		". . . . . .",
		"P E . . . .",
	] as Array[String])
	rig.enemy().hp = 20
	rig.resolver.place_shadow(rig.player(), Vector2i(5, 0))
	rig.answers.answers = [0]
	assert_true(await rig.use(rig.player(), &"displacer_strike", [Vector2i(1, 1), Vector2i(0, 0)]))
	assert_eq(rig.answers.titles(), ["Shadowstrike"] as Array[String], "5 squares away, reach 5")
	assert_eq(rig.enemy().hp, 20 - 3 - 3)


func test_shadowstorm_lets_every_shadow_copy() -> void:
	var rig := await _rig([
		". E .",
		". . .",
		"P . .",
	] as Array[String])
	var tl := rig.player()
	rig.enemy().hp = 40
	rig.answers.answers = [0]
	assert_true(await rig.use(tl, &"shadowstorm", [Vector2i(0, 0), Vector2i(2, 0), Vector2i(1, 1)]))
	assert_eq(tl.shadows.size(), 3, "Three Shadows placed")
	assert_true(tl.has_status(&"shadowstorm"))
	assert_eq(tl.actions.skill, 1, "Free")
	rig.answers.answers = [0, 0, 0]
	assert_true(await rig.use(tl, &"displacer_strike", [Vector2i(1, 0), Vector2i(1, 1)]))
	# The shift's new Shadow pushed out the oldest, and can't copy the skill
	# that made it.
	assert_eq(rig.answers.asked.size(), 2, "Each other Shadow offered in turn")
	assert_eq(rig.enemy().hp, 40 - 3 * 3, "Displacer 3, then two copies of 3")
	assert_eq(tl.shadows, TestRig.cells([Vector2i(0, 2)]), "Displacer's own Shadow is left")


func test_shadowstep_teleports_and_uses_up_the_shadow() -> void:
	var rig := await _rig(["P . . . E"] as Array[String])
	var tl := rig.player()
	rig.resolver.place_shadow(tl, Vector2i(3, 0))
	assert_true(await rig.use(tl, &"shadowstep", [Vector2i(3, 0)]))
	assert_eq(tl.cell, Vector2i(3, 0))
	assert_true(tl.shadows.is_empty())
	assert_eq(tl.actions.skill + tl.actions.flex + tl.actions.move, 3, "Free")
	assert_true(rig.log.types.has(GameEvent.TELEPORTED))
	assert_true(tl.shadows.is_empty(), "A teleport isn't a shift: no new Shadow")

#endregion

#region Other skills

func test_phantom_dash_strikes_each_foe_passed_through() -> void:
	var rig := await _rig(["P E . E . . ."] as Array[String])
	var path := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0)]
	assert_true(await rig.use(rig.player(), &"phantom_dash", path))
	assert_eq(rig.player().cell, Vector2i(5, 0), "2 + 2 per foe")
	assert_eq(rig.enemy(0).hp, 9)
	assert_eq(rig.enemy(1).hp, 9)
	assert_eq(rig.player().shadows, TestRig.cells([Vector2i(0, 0)]))


func test_chimeric_cloak_negates_the_next_strike() -> void:
	var rig := await _rig(["P E"] as Array[String])
	var tl := rig.player()
	assert_true(await rig.use(tl, &"chimeric_cloak"))
	rig.answers.answers = [0]
	var hit := await rig.resolver.strike(rig.enemy(), tl,
			StrikeSpec.cards([Enums.Tier.GOLD] as Array[Enums.Tier]))
	assert_true(hit.cancelled)
	assert_eq(tl.hp, 12)
	assert_false(tl.has_status(&"chimeric_cloak"), "Used up")
	await rig.resolver.strike(rig.enemy(), tl, StrikeSpec.cards([Enums.Tier.GOLD] as Array[Enums.Tier]))
	assert_eq(tl.hp, 8)


func test_chimeric_cloak_can_be_saved_and_blocks_a_debuff() -> void:
	var rig := await _rig(["P E"] as Array[String])
	var tl := rig.player()
	await rig.use(tl, &"chimeric_cloak")
	rig.answers.answers = [DecisionRequest.DECLINED, 0]
	await rig.resolver.strike(rig.enemy(), tl, StrikeSpec.flat(1))
	assert_eq(tl.hp, 11, "Saved it for something worse")
	assert_true(tl.has_status(&"chimeric_cloak"))
	var applied := await rig.resolver.apply_status(tl, PROVOKE, rig.enemy(), rig.enemy())
	assert_null(applied, "Provoke had no effect")
	assert_false(tl.has_status(&"provoke"))
	assert_false(tl.has_status(&"chimeric_cloak"))


func test_a_negated_strike_doesnt_use_up_dodges() -> void:
	var rig := await _rig(["P E"] as Array[String])
	var tl := rig.player()
	tl.def.evasion = 1
	await rig.use(tl, &"chimeric_cloak")
	rig.answers.answers = [0]
	await rig.resolver.strike(rig.enemy(), tl, StrikeSpec.cards([Enums.Tier.GOLD] as Array[Enums.Tier]))
	assert_eq(tl.dodges_left(), 1, "Given back: the strike never landed")


func test_chimeric_cloak_lasts_until_end_of_turn() -> void:
	var rig := await _rig(["P E"] as Array[String])
	await rig.use(rig.player(), &"chimeric_cloak")
	await rig.new_turn(rig.enemy())
	assert_true(rig.player().has_status(&"chimeric_cloak"), "Still up in the enemy phase")
	await rig.new_round()
	assert_false(rig.player().has_status(&"chimeric_cloak"))


func test_mirage_shift_places_a_shadow_and_allows_free_swaps() -> void:
	var rig := await _rig(["P . . . . . . E"] as Array[String])
	var tl := rig.player()
	var swap := rig.skill(tl, &"shadow_swap")
	assert_false(rig.resolver.can_use(tl, swap), "Needs Mirage Shift first")
	assert_true(await rig.use(tl, &"mirage_shift", [Vector2i(6, 0)]))
	assert_eq(tl.shadows, TestRig.cells([Vector2i(6, 0)]))
	assert_eq(tl.actions.move, 0, "Maneuver")
	assert_true(await rig.use(tl, &"shadow_swap", [Vector2i(6, 0)]))
	assert_eq(tl.cell, Vector2i(6, 0))
	assert_eq(tl.shadows, TestRig.cells([Vector2i(0, 0)]), "The Shadow takes your old square")
	assert_true(await rig.use(tl, &"shadow_swap", [Vector2i(0, 0)]), "Again, still free")
	assert_eq(tl.cell, Vector2i(0, 0))
	await rig.new_round()
	assert_false(rig.resolver.can_use(tl, swap), "Until end of turn")


func test_swapping_onto_a_square_with_a_shadow_merges_them() -> void:
	var rig := await _rig(["P . . . E"] as Array[String])
	var tl := rig.player()
	await rig.use(tl, &"mirage_shift", [Vector2i(2, 0)])
	rig.resolver.place_shadow(tl, Vector2i(0, 0))  # A Shadow under the Traceless.
	await rig.use(tl, &"shadow_swap", [Vector2i(2, 0)])
	assert_eq(tl.shadows, TestRig.cells([Vector2i(0, 0)]), "One Shadow, not two")
	assert_eq(tl.get_stat(&"evasion"), 1)


func test_tactical_distortion_redirects_a_foes_attack_once() -> void:
	var rig := await _rig(["P E A"] as Array[String])
	var tl := rig.player()
	var foe := rig.enemy()
	foe.def.skills = [CLAW]
	assert_true(await rig.use(tl, &"tactical_distortion", [foe.cell]))
	assert_eq(tl.actions.skill, 1, "Free")
	rig.answers.answers = [0]  # The only other valid target: the ally.
	assert_true(await rig.resolver.request_skill(foe, CLAW, TestRig.cells([tl.cell])))
	assert_eq(tl.hp, 12)
	assert_eq(rig.ally().hp, 9, "Claw went to the ally instead")
	assert_false(foe.has_status(&"distorted"), "Once")


func test_perfect_decoy_prevents_a_lethal_strike_and_heals() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	var ally := rig.ally()
	ally.hp = 2
	assert_true(await rig.use(rig.player(), &"perfect_decoy"))
	assert_eq(rig.resolver.recoveries_left(Enums.Team.PLAYER), 1)
	var hit := await rig.resolver.strike(rig.enemy(), ally,
			StrikeSpec.cards([Enums.Tier.SILVER] as Array[Enums.Tier]))
	assert_true(hit.cancelled)
	assert_eq(ally.hp, 9, "Healed Gold + Silver = 7")
	for unit: UnitState in [rig.player(), ally]:
		assert_false(unit.has_status(&"perfect_decoy"), "Only the first time")


func test_perfect_decoy_ignores_hits_that_dont_kill() -> void:
	var rig := await _rig(["P A E"] as Array[String])
	await rig.use(rig.player(), &"perfect_decoy")
	await rig.resolver.strike(rig.enemy(), rig.ally(), StrikeSpec.flat(3))
	assert_eq(rig.ally().hp, 9)
	assert_true(rig.ally().has_status(&"perfect_decoy"), "Still waiting")

#endregion
