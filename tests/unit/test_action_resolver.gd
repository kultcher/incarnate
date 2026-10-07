extends GutTest
## The resolver with no Presenter attached: pure rules.

var resolver: ActionResolver


func _make(rows: Array[String], move: int = 4) -> BoardFixture:
	var f := BoardFixture.parse(rows, move)
	resolver = ActionResolver.new()
	resolver.board = f.board
	add_child_autofree(resolver)
	return f


func test_legal_move_updates_board_and_pays() -> void:
	var f := _make([
		"P . . . .",
	] as Array[String])
	var ok: bool = await resolver.request_move(f.mover, Vector2i(3, 0))
	assert_true(ok)
	assert_eq(f.mover.cell, Vector2i(3, 0))
	assert_eq(f.board.unit_at(Vector2i(3, 0)), f.mover)
	assert_eq(f.mover.actions.move, 0)


func test_out_of_range_move_changes_nothing() -> void:
	var f := _make(["P . . . . . ."] as Array[String], 3)
	var ok: bool = await resolver.request_move(f.mover, Vector2i(5, 0))
	assert_false(ok)
	assert_eq(f.mover.cell, Vector2i(0, 0))
	assert_eq(f.mover.actions.move, 1, "Nothing was paid")


func test_cannot_move_onto_blocked_or_occupied_cells() -> void:
	var f := _make([
		"P # A E",
	] as Array[String])
	for target: Vector2i in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]:
		var ok: bool = await resolver.request_move(f.mover, target)
		assert_false(ok, "Refused move to %s" % target)
	assert_eq(f.mover.cell, Vector2i(0, 0))


func test_second_move_uses_flex_and_third_is_refused() -> void:
	var f := _make(["P . . . . . . . . ."] as Array[String], 3)
	assert_true(await resolver.request_move(f.mover, Vector2i(3, 0)))
	assert_true(await resolver.request_move(f.mover, Vector2i(6, 0)))
	assert_eq(f.mover.actions.flex, 0)
	assert_false(await resolver.request_move(f.mover, Vector2i(9, 0)))
	assert_eq(f.mover.cell, Vector2i(6, 0))


func test_gate_walks_around_obstacles_and_never_enters_occupied_cells() -> void:
	# Milestone 1 gate. A wall of bushes with an enemy in the gap.
	var f := _make([
		". . . # . .",
		"P . . E . .",
		". . . # . .",
		". . . . . .",
	] as Array[String], 8)
	var target := Vector2i(4, 1)
	# The direct route is 4 squares; the only legal route is 8, around row 3.
	var reach := Pathing.reachable(f.board, f.mover, 8)
	assert_eq(reach.cost[target], 8)
	var path := reach.path_to(target)
	for step in path:
		assert_false(f.board.blocks_move(step), "Never steps on a bush")
		assert_false(f.board.is_occupied(step), "Never steps on the enemy")
	assert_true(await resolver.request_move(f.mover, target))
	assert_eq(f.mover.cell, target)
	assert_eq(f.board.unit_at(Vector2i(3, 1)), f.enemies[0], "Enemy didn't move")
