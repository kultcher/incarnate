extends GutTest
## Path skills: the squares a clicked-out shift may take (Bloody Rush,
## Phantom Dash), and custom target rules (Displacer Strike).

const BT := preload("res://content/units/bloodthane.tres")
const TL := preload("res://content/units/traceless.tres")


func _rush(rig: TestRig) -> SkillDef:
	await rig.equip(rig.player(), BT)
	return rig.skill(rig.player(), &"bloody_rush")


func test_path_steps_must_chain_and_stay_on_the_board() -> void:
	var rig := TestRig.make(self, [
		". . . .",
		"P . # .",
	] as Array[String])
	var rush := await _rush(rig)
	var first := Targeting.path_next_cells(rig.board, rig.player(), rush, [])
	first.sort()
	assert_eq(first, TestRig.cells([Vector2i(0, 0), Vector2i(1, 1)]))
	var second := Targeting.path_next_cells(rig.board, rig.player(), rush, TestRig.cells([Vector2i(1, 1)]))
	assert_eq(second, TestRig.cells([Vector2i(1, 0)]), "Wall to the right; can't go back")


func test_a_path_can_pass_a_foe_but_not_end_on_it() -> void:
	var rig := TestRig.make(self, ["P E E ."] as Array[String])
	var rush := await _rush(rig)
	assert_eq(Targeting.path_next_cells(rig.board, rig.player(), rush, []),
			TestRig.cells([Vector2i(1, 0)]), "Through the first foe")
	var two := TestRig.cells([Vector2i(1, 0)])
	assert_false(Targeting.path_can_finish(rig.board, rig.player(), rush, two), "Can't stop on a foe")
	assert_eq(Targeting.path_next_cells(rig.board, rig.player(), rush, two),
			TestRig.cells([Vector2i(2, 0)]))
	var three := TestRig.cells([Vector2i(1, 0), Vector2i(2, 0)])
	assert_eq(Targeting.path_next_cells(rig.board, rig.player(), rush, three),
			TestRig.cells([Vector2i(3, 0)]), "Last square must be empty")
	assert_true(Targeting.is_valid_path(rig.board, rig.player(), rush,
			TestRig.cells([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])))


func test_a_path_may_stop_early_on_an_empty_square() -> void:
	var rig := TestRig.make(self, ["P . . . ."] as Array[String])
	var rush := await _rush(rig)
	assert_true(Targeting.is_valid_path(rig.board, rig.player(), rush, TestRig.cells([Vector2i(1, 0)])))
	assert_false(Targeting.is_valid_path(rig.board, rig.player(), rush, TestRig.cells([Vector2i(2, 0)])),
			"Squares must chain from the caster")
	assert_false(Targeting.is_valid_path(rig.board, rig.player(), rush,
			TestRig.cells([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)])), "Too long")


func test_phantom_dash_gets_two_more_squares_per_foe_passed() -> void:
	var rig := TestRig.make(self, ["P E . . . . ."] as Array[String])
	await rig.equip(rig.player(), TL)
	var dash := rig.skill(rig.player(), &"phantom_dash")
	var path := TestRig.cells([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)])
	assert_eq(Targeting.path_budget(rig.board, rig.player(), dash, path), 4)
	assert_true(Targeting.is_valid_path(rig.board, rig.player(), dash, path))
	path.append(Vector2i(5, 0))
	assert_false(Targeting.is_valid_path(rig.board, rig.player(), dash, path))


func test_all_paths_lists_only_complete_paths() -> void:
	var rig := TestRig.make(self, ["P E ."] as Array[String])
	var rush := await _rush(rig)
	var paths := Targeting.all_paths(rig.board, rig.player(), rush, 100)
	assert_eq(paths.size(), 1)
	assert_eq(paths[0], TestRig.cells([Vector2i(1, 0), Vector2i(2, 0)]))


func test_displacer_rule_offers_foes_in_reach_before_or_after_the_shift() -> void:
	var rig := TestRig.make(self, [
		"P . . E . E",
	] as Array[String])
	await rig.equip(rig.player(), TL)
	var displacer := rig.skill(rig.player(), &"displacer_strike")
	var foes := Targeting.valid_cells(rig.board, rig.player(), displacer, 0, [])
	assert_eq(foes, TestRig.cells([Vector2i(3, 0)]), "(3,0) is reachable after shifting 2; (5,0) isn't")
	var dests := Targeting.valid_cells(rig.board, rig.player(), displacer, 1, TestRig.cells([Vector2i(3, 0)]))
	assert_eq(dests, TestRig.cells([Vector2i(2, 0)]), "Only next to the foe")
