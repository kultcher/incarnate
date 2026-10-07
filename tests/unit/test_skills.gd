extends GutTest
## The skill pipeline through the resolver with no Presenter: costs,
## cooldowns, limits, multi-hit skills and descriptions.

const BLADE_FURY := preload("res://content/skills/bloodthane/blade_fury.tres")
const RENDING := preload("res://content/skills/bloodthane/rending_claws.tres")
const SHADOWSTEP := preload("res://content/skills/traceless/shadowstep.tres")
const VERVE := preload("res://content/skills/bloodthane/verve_magnet.tres")


func _rig(rows: Array[String], skills: Array[SkillDef]) -> TestRig:
	var rig := TestRig.make(self, rows)
	rig.player().def.skills = skills
	return rig


## A test skill: strike two adjacent picks for one Silver each.
func _twin_strike() -> SkillDef:
	var s := SkillDef.new()
	s.id = &"twin"
	s.cooldown = 2
	for i in 2:
		var step := TargetStep.new()
		s.targets.append(step)
		var d := DamageEffect.new()
		d.tiers = [Enums.Tier.SILVER] as Array[Enums.Tier]
		d.target_step = i
		s.effects.append(d)
	return s


func test_blade_fury_strikes_and_pays_a_skill_point() -> void:
	var rig := _rig(["P E"] as Array[String], [BLADE_FURY])
	assert_true(await rig.resolver.request_skill(rig.player(), BLADE_FURY, TestRig.cells([Vector2i(1, 0)])))
	assert_eq(rig.enemy().hp, 8)
	assert_eq(rig.player().actions.skill, 0)
	assert_eq(rig.player().actions.flex, 1, "Dedicated skill point is spent before flex")
	assert_eq(rig.log.types, [GameEvent.SKILL_USED, GameEvent.ACTIONS_CHANGED,
			GameEvent.STRIKE, GameEvent.DAMAGED] as Array[StringName])


func test_two_strikes_can_hit_two_foes_or_one_twice() -> void:
	var twin := _twin_strike()
	var rig := _rig(["E P E"] as Array[String], [twin])
	await rig.resolver.request_skill(rig.player(), twin, TestRig.cells([Vector2i(0, 0), Vector2i(2, 0)]))
	assert_eq(rig.enemy(0).hp, 9)
	assert_eq(rig.enemy(1).hp, 9)
	rig.player().cooldowns.clear()
	await rig.resolver.request_skill(rig.player(), twin, TestRig.cells([Vector2i(0, 0), Vector2i(0, 0)]))
	assert_eq(rig.enemy(0).hp, 3)


func test_second_strike_on_a_dead_foe_is_skipped() -> void:
	var twin := _twin_strike()
	var rig := _rig(["P E"] as Array[String], [twin])
	rig.enemy().hp = 3
	await rig.resolver.request_skill(rig.player(), twin, TestRig.cells([Vector2i(1, 0), Vector2i(1, 0)]))
	assert_false(rig.enemy().is_alive())
	assert_eq(rig.log.types.count(GameEvent.STRIKE), 1, "No swing at a corpse")
	assert_eq(rig.log.types.count(GameEvent.DIED), 1)


func test_lethal_damage_removes_the_unit() -> void:
	var rig := _rig(["P E"] as Array[String], [BLADE_FURY])
	rig.enemy().hp = 4
	await rig.resolver.request_skill(rig.player(), BLADE_FURY, TestRig.cells([Vector2i(1, 0)]))
	assert_false(rig.enemy().is_alive())
	assert_null(rig.board.unit_at(Vector2i(1, 0)), "Cell is free again")
	assert_eq(rig.log.types[-1], GameEvent.DIED)


func test_cooldown_blocks_reuse_until_it_ticks_down() -> void:
	var rig := _rig(["P E"] as Array[String], [RENDING])
	rig.enemy().hp = 99
	var picks := TestRig.cells([Vector2i(1, 0)])
	assert_true(await rig.resolver.request_skill(rig.player(), RENDING, picks), "Round 1")
	assert_eq(rig.player().cooldown_left(RENDING), 2)
	assert_false(rig.resolver.can_use(rig.player(), RENDING), "Still has flex, but recharging")
	rig.player().start_turn()
	assert_false(await rig.resolver.request_skill(rig.player(), RENDING, picks), "Round 2")
	rig.player().start_turn()
	assert_true(await rig.resolver.request_skill(rig.player(), RENDING, picks), "Round 3: ready")


func test_two_skills_in_one_turn_via_flex() -> void:
	var rig := _rig(["P E"] as Array[String], [BLADE_FURY])
	var picks := TestRig.cells([Vector2i(1, 0)])
	assert_true(await rig.resolver.request_skill(rig.player(), BLADE_FURY, picks))
	assert_true(await rig.resolver.request_skill(rig.player(), BLADE_FURY, picks), "Flex pays the second")
	assert_false(await rig.resolver.request_skill(rig.player(), BLADE_FURY, picks), "Out of points")
	assert_eq(rig.enemy().hp, 4)


func test_free_skills_cost_nothing_and_maneuvers_use_the_move_point() -> void:
	var rig := _rig(["P . . E"] as Array[String], [SHADOWSTEP, VERVE])
	rig.player().shadows = TestRig.cells([Vector2i(2, 0)])
	rig.player().actions.spend_all()
	assert_true(await rig.resolver.request_skill(rig.player(), SHADOWSTEP, TestRig.cells([Vector2i(2, 0)])),
			"Free with no points left")
	rig.player().actions.refresh()
	rig.answers.answers = [0]
	assert_true(await rig.resolver.request_skill(rig.player(), VERVE, TestRig.cells([Vector2i(3, 0)])))
	assert_eq(rig.player().actions.move, 0)
	assert_eq(rig.player().actions.skill, 1)


func test_illegal_picks_change_nothing() -> void:
	var rig := _rig(["P . E"] as Array[String], [BLADE_FURY])
	assert_false(await rig.resolver.request_skill(rig.player(), BLADE_FURY, TestRig.cells([Vector2i(2, 0)])))
	assert_eq(rig.enemy().hp, 12)
	assert_eq(rig.player().actions.skill, 1, "Nothing paid")
	assert_true(rig.log.types.is_empty())


func test_cannot_use_a_skill_the_unit_lacks() -> void:
	var rig := _rig(["P E"] as Array[String], [BLADE_FURY])
	assert_false(await rig.resolver.request_skill(rig.player(), RENDING, TestRig.cells([Vector2i(1, 0)])))


func test_descriptions_show_the_cards() -> void:
	assert_string_contains(BLADE_FURY.describe(), "4 (Bronze + Bronze)")
	assert_string_contains(BLADE_FURY.describe(), "every 2 squares")
	assert_string_contains(RENDING.describe(), "6 (Silver + Silver)")
	assert_eq(RENDING.cost_text(), "Skill action · Recharge 2")
	assert_eq(SHADOWSTEP.cost_text(), "Free")
