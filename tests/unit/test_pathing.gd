extends GutTest


func _assert_valid_path(board: BoardState, from: Vector2i, path: Array[Vector2i]) -> void:
	var at := from
	for step in path:
		assert_eq(BoardState.distance(at, step), 1, "Each step is one orthogonal square")
		assert_false(board.blocks_move(step), "Path never crosses blocked terrain")
		at = step


func test_open_field_range_is_a_diamond() -> void:
	var f := BoardFixture.parse([
		". . . . .",
		". . . . .",
		". . P . .",
		". . . . .",
		". . . . .",
	] as Array[String])
	var reach := Pathing.reachable(f.board, f.mover, 2)
	assert_eq(reach.destinations.size(), 12)
	assert_false(reach.can_reach(Vector2i(2, 2)), "Can't move onto own cell")
	assert_false(reach.can_reach(Vector2i(0, 0)), "Corner is 4 away")


func test_zero_budget_reaches_nothing() -> void:
	var f := BoardFixture.parse([". P ."] as Array[String])
	assert_eq(Pathing.reachable(f.board, f.mover, 0).destinations.size(), 0)


func test_walks_around_a_wall() -> void:
	var f := BoardFixture.parse([
		". . . . .",
		"P . # . .",
		". . # . .",
		". . . . .",
	] as Array[String])
	var target := Vector2i(3, 1)
	# Straight line is 3, but the wall forces a 5-step detour.
	assert_false(Pathing.reachable(f.board, f.mover, 4).can_reach(target))
	var reach := Pathing.reachable(f.board, f.mover, 5)
	assert_true(reach.can_reach(target))
	var path := reach.path_to(target)
	assert_eq(path.size(), 5)
	assert_eq(path[-1], target)
	_assert_valid_path(f.board, f.mover.cell, path)


func test_enemies_block_walking() -> void:
	var f := BoardFixture.parse([
		"# # # # #",
		"P . E . .",
		"# # # # #",
	] as Array[String])
	var reach := Pathing.reachable(f.board, f.mover, 4)
	assert_true(reach.can_reach(Vector2i(1, 1)))
	assert_false(reach.can_reach(Vector2i(3, 1)), "Can't walk through an enemy")
	assert_false(reach.can_reach(Vector2i(2, 1)), "Can't stop on an enemy")


func test_allies_can_be_passed_but_not_stopped_on() -> void:
	var f := BoardFixture.parse([
		"# # # # #",
		"P . A . .",
		"# # # # #",
	] as Array[String])
	var reach := Pathing.reachable(f.board, f.mover, 4)
	assert_true(reach.can_reach(Vector2i(3, 1)), "Walks through the ally")
	assert_false(reach.can_reach(Vector2i(2, 1)), "Never ends on an occupied cell")
	assert_eq(reach.path_to(Vector2i(3, 1)), [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)] as Array[Vector2i])


func test_shift_passes_through_enemies() -> void:
	var f := BoardFixture.parse([
		"# # # # #",
		"P . E . .",
		"# # # # #",
	] as Array[String])
	var reach := Pathing.reachable(f.board, f.mover, 4, MoveRules.shift())
	assert_true(reach.can_reach(Vector2i(4, 1)))
	assert_false(reach.can_reach(Vector2i(2, 1)), "Even a shift can't end on a unit")


func test_shift_ignores_units_on_every_step_not_just_the_first() -> void:
	# Regression for the 2023 prototype, whose shift only ignored units for one step.
	var f := BoardFixture.parse([
		"# # # # # #",
		"P E E E . .",
		"# # # # # #",
	] as Array[String])
	var reach := Pathing.reachable(f.board, f.mover, 5, MoveRules.shift())
	assert_true(reach.can_reach(Vector2i(4, 1)))


func test_rough_terrain_costs_two() -> void:
	var f := BoardFixture.parse([
		"P ~ .",
		"# . #",
	] as Array[String])
	var reach := Pathing.reachable(f.board, f.mover, 2)
	assert_true(reach.can_reach(Vector2i(1, 0)), "Rough costs 2")
	assert_false(reach.can_reach(Vector2i(2, 0)), "Rough plus one more is 3")
	assert_eq(reach.cost[Vector2i(1, 0)], 2)


func test_prefers_cheaper_path_around_rough() -> void:
	var f := BoardFixture.parse([
		"P ~ ~ ~ .",
		". . . . .",
	] as Array[String])
	var reach := Pathing.reachable(f.board, f.mover, 10)
	# Through the rough row: 2 + 2 + 2 + 1 = 7. Down, across, up: 6.
	assert_eq(reach.cost[Vector2i(4, 0)], 6)
	var path := reach.path_to(Vector2i(4, 0))
	_assert_valid_path(f.board, f.mover.cell, path)
	assert_eq(path[0], Vector2i(0, 1), "Steps off the rough row first")
