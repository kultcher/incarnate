extends GutTest


func test_new_board_is_open() -> void:
	var board := BoardState.new(Vector2i(4, 3))
	assert_true(board.in_bounds(Vector2i(3, 2)))
	assert_false(board.in_bounds(Vector2i(4, 0)))
	assert_false(board.in_bounds(Vector2i(-1, 0)))
	assert_false(board.blocks_move(Vector2i(1, 1)))
	assert_true(board.blocks_move(Vector2i(9, 9)), "Off-board cells block movement")


func test_neighbors_are_orthogonal_and_in_bounds() -> void:
	var board := BoardState.new(Vector2i(3, 3))
	assert_eq(board.neighbors(Vector2i(1, 1)).size(), 4)
	assert_eq(board.neighbors(Vector2i(0, 0)).size(), 2)


func test_place_and_move_unit_keeps_one_source_of_truth() -> void:
	var f := BoardFixture.parse(["P . ."] as Array[String])
	var unit := f.mover
	assert_eq(f.board.unit_at(Vector2i(0, 0)), unit)

	f.board.move_unit(unit, Vector2i(2, 0))
	assert_eq(unit.cell, Vector2i(2, 0))
	assert_null(f.board.unit_at(Vector2i(0, 0)), "Old cell is freed")
	assert_eq(f.board.unit_at(Vector2i(2, 0)), unit)
	assert_eq(f.board.units().size(), 1)


func test_remove_unit() -> void:
	var f := BoardFixture.parse(["P ."] as Array[String])
	f.board.remove_unit(f.mover)
	assert_false(f.board.is_occupied(Vector2i(0, 0)))


func test_from_layers_reads_test_arena() -> void:
	var arena: Node = load("res://levels/test_arena.tscn").instantiate()
	add_child_autofree(arena)
	var board := BoardState.from_layers(arena.get_node("Ground"), arena.get_node("Obstacles"))
	assert_eq(board.size, Vector2i(12, 10))
	assert_true(board.blocks_move(Vector2i(5, 3)), "Bush in the wall blocks")
	assert_false(board.blocks_move(Vector2i(0, 0)), "Plain grass is open")
	assert_eq(board.move_cost(Vector2i(0, 0)), 1)
