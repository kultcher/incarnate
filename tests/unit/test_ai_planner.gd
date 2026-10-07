extends GutTest
## AiPlanner choices on small boards, rules only.

const BLADE_FURY := preload("res://content/skills/bloodthane/blade_fury.tres")
const RUSH := preload("res://content/skills/bloodthane/bloody_rush.tres")
const VERVE := preload("res://content/skills/bloodthane/verve_magnet.tres")
const DISPLACER := preload("res://content/skills/traceless/displacer_strike.tres")
const CLAW := preload("res://content/skills/shambler/claw.tres")

var resolver: ActionResolver


func _make(rows: Array[String], skills: Array[SkillDef], move: int = 4) -> BoardFixture:
	var f := BoardFixture.parse(rows, move)
	f.mover.def.skills = skills
	resolver = ActionResolver.new()
	resolver.board = f.board
	add_child_autofree(resolver)
	return f


func test_attacks_an_adjacent_foe() -> void:
	var f := _make(["P E ."] as Array[String], [BLADE_FURY])
	var plan := AiPlanner.next_action(f.board, resolver, f.mover)
	assert_not_null(plan)
	assert_false(plan.is_move())
	assert_eq(plan.picks, [Vector2i(1, 0)] as Array[Vector2i])


func test_prefers_the_kill() -> void:
	var f := _make([
		". E .",
		"E P .",
	] as Array[String], [BLADE_FURY])
	f.enemies[1].hp = 3  # The one at (0, 1).
	var plan := AiPlanner.best_attack(f.board, resolver, f.mover)
	assert_eq(plan.picks, [Vector2i(0, 1)] as Array[Vector2i])


func test_bloody_rush_takes_the_path_that_strikes_the_most_foes() -> void:
	var f := _make([
		"P . E",
		". . .",
		". E .",
	] as Array[String], [RUSH])
	var plan := AiPlanner.best_attack(f.board, resolver, f.mover)
	assert_eq(plan.skill, RUSH)
	assert_eq(plan.score, AiPlanner.score_picks(f.board, RUSH, plan.picks, f.mover))
	var foes := (RUSH.effects[0] as PathStrikeEffect).foes_on_path(f.board, f.mover, plan.picks)
	assert_eq(foes.size(), 2, "A path next to both foes")


func test_displacer_strike_is_planned_with_a_shift() -> void:
	var f := _make(["P . . E"] as Array[String], [DISPLACER])
	var plan := AiPlanner.best_attack(f.board, resolver, f.mover)
	assert_eq(plan.picks, [Vector2i(3, 0), Vector2i(2, 0)] as Array[Vector2i])


func test_skills_the_ai_cant_judge_are_left_alone() -> void:
	var f := _make(["P E"] as Array[String], [VERVE])
	assert_false(AiPlanner.knows(VERVE))
	assert_null(AiPlanner.next_action(f.board, resolver, f.mover))


func test_moves_into_attack_range() -> void:
	var f := _make([
		"P . . . E",
		". . . . .",
	] as Array[String], [BLADE_FURY], 3)
	var plan := AiPlanner.next_action(f.board, resolver, f.mover)
	assert_true(plan.is_move())
	assert_eq(plan.move_to, Vector2i(3, 0), "Shortest walk to a cell next to the foe")


func test_approaches_when_no_attack_is_in_reach() -> void:
	var f := _make(["P . . . . . . . . E"] as Array[String], [BLADE_FURY], 3)
	var plan := AiPlanner.next_action(f.board, resolver, f.mover)
	assert_true(plan.is_move())
	assert_eq(plan.move_to, Vector2i(3, 0))


func test_walks_around_walls_to_reach_a_foe() -> void:
	var f := _make([
		"P # E",
		". . .",
	] as Array[String], [BLADE_FURY], 4)
	var plan := AiPlanner.next_action(f.board, resolver, f.mover)
	assert_true(plan.is_move())
	assert_eq(plan.move_to, Vector2i(2, 1), "Below the foe; (1,0) is a wall")


func test_stays_put_with_nothing_to_do() -> void:
	var f := _make(["P . ."] as Array[String], [BLADE_FURY])
	assert_null(AiPlanner.next_action(f.board, resolver, f.mover), "No foes at all")


func test_planning_leaves_the_board_unchanged() -> void:
	var f := _make([
		"P . . . E",
		". . . . .",
	] as Array[String], [BLADE_FURY], 3)
	AiPlanner.next_action(f.board, resolver, f.mover)
	assert_eq(f.mover.cell, Vector2i(0, 0))
	assert_eq(f.board.unit_at(Vector2i(0, 0)), f.mover)


func test_monster_without_flex_attacks_once() -> void:
	var f := _make(["P E"] as Array[String], [CLAW])
	f.mover.def.flex_points = 0
	f.mover.actions = ActionEconomy.new(1, 1, 0)
	var foe := f.enemies[0]
	var ai := EnemyAI.new()
	ai.board = f.board
	ai.resolver = resolver
	add_child_autofree(ai)
	await ai.take_unit_turn(f.mover)
	assert_eq(foe.hp, 9, "One Claw for 3, no second hit")
