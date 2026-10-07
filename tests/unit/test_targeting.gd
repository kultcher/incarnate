extends GutTest
## Which cells each kind of targeting step allows.

const BLADE_FURY := preload("res://content/skills/bloodthane/blade_fury.tres")


## Two adjacent-foe picks, like the old Ravage.
func _two_strikes() -> SkillDef:
	var skill := SkillDef.new()
	skill.targets = [TargetStep.new(), TargetStep.new()]
	return skill


func _skill_with(step: TargetStep) -> SkillDef:
	var skill := SkillDef.new()
	skill.targets = [step]
	return skill


func test_adjacent_enemy_only_sees_touching_foes() -> void:
	var f := BoardFixture.parse([
		". E . .",
		"E P A E",
		". . . .",
	] as Array[String])
	var cells := Targeting.valid_cells(f.board, f.mover, BLADE_FURY, 0, [])
	cells.sort()
	assert_eq(cells, [Vector2i(0, 1), Vector2i(1, 0)] as Array[Vector2i],
			"Diagonal-free, ally and distant enemy excluded")


func test_ravage_second_pick_may_repeat_the_first() -> void:
	var f := BoardFixture.parse(["E P E"] as Array[String])
	var picks: Array[Vector2i] = [Vector2i(0, 0)]
	var cells := Targeting.valid_cells(f.board, f.mover, _two_strikes(), 1, picks)
	assert_has(cells, Vector2i(0, 0))
	assert_has(cells, Vector2i(2, 0))


func test_unique_step_excludes_earlier_picks() -> void:
	var f := BoardFixture.parse(["E P E"] as Array[String])
	var step := TargetStep.new()
	step.unique = true
	var skill := SkillDef.new()
	skill.targets = [TargetStep.new(), step]
	var picks: Array[Vector2i] = [Vector2i(0, 0)]
	assert_eq(Targeting.valid_cells(f.board, f.mover, skill, 1, picks),
			[Vector2i(2, 0)] as Array[Vector2i])


func test_within_range_and_empty_filter() -> void:
	var f := BoardFixture.parse([
		". . # . .",
		". . . . .",
		". . P E .",
	] as Array[String])
	var step := TargetStep.new()
	step.shape = Enums.TargetShape.WITHIN
	step.filter = Enums.TargetFilter.EMPTY
	step.range_min = 2
	step.range_max = 2
	var cells := Targeting.valid_cells(f.board, f.mover, _skill_with(step), 0, [])
	cells.sort()
	assert_eq(cells, [Vector2i(0, 2), Vector2i(1, 1), Vector2i(3, 1), Vector2i(4, 2)] as Array[Vector2i],
			"Distance exactly 2, not blocked, not occupied")


func test_previous_origin_chains_from_last_pick() -> void:
	var f := BoardFixture.parse([". P . . E"] as Array[String])
	var first := TargetStep.new()
	first.filter = Enums.TargetFilter.EMPTY
	var second := TargetStep.new()
	second.origin = Enums.TargetOrigin.PREVIOUS
	second.shape = Enums.TargetShape.WITHIN
	second.range_max = 2
	var skill := SkillDef.new()
	skill.targets = [first, second]
	var picks: Array[Vector2i] = [Vector2i(2, 0)]
	assert_eq(Targeting.valid_cells(f.board, f.mover, skill, 1, picks),
			[Vector2i(4, 0)] as Array[Vector2i])


func test_are_valid_picks_checks_count_and_order() -> void:
	var f := BoardFixture.parse(["E P E"] as Array[String])
	assert_true(Targeting.are_valid_picks(f.board, f.mover, _two_strikes(),
			[Vector2i(0, 0), Vector2i(2, 0)] as Array[Vector2i]))
	assert_false(Targeting.are_valid_picks(f.board, f.mover, _two_strikes(),
			[Vector2i(0, 0)] as Array[Vector2i]), "Too few picks")
	assert_false(Targeting.are_valid_picks(f.board, f.mover, _two_strikes(),
			[Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i]), "Can't strike yourself")


func test_new_filters_ally_or_self_and_own_shadow() -> void:
	var f := BoardFixture.parse(["P A E ."] as Array[String])
	assert_true(Targeting.passes_filter(f.board, f.mover, Enums.TargetFilter.ALLY_OR_SELF, Vector2i(0, 0)))
	assert_true(Targeting.passes_filter(f.board, f.mover, Enums.TargetFilter.ALLY_OR_SELF, Vector2i(1, 0)))
	assert_false(Targeting.passes_filter(f.board, f.mover, Enums.TargetFilter.ALLY_OR_SELF, Vector2i(2, 0)))
	f.mover.shadows = [Vector2i(3, 0), Vector2i(2, 0)] as Array[Vector2i]
	assert_true(Targeting.passes_filter(f.board, f.mover, Enums.TargetFilter.OWN_SHADOW, Vector2i(3, 0)))
	assert_false(Targeting.passes_filter(f.board, f.mover, Enums.TargetFilter.OWN_SHADOW, Vector2i(2, 0)),
			"A unit stands on that Shadow")
