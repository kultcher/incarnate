class_name Pathing
extends RefCounted
## Movement range and paths, from one Dijkstra flood fill.
## The same result drives the highlight, the hover path and the rule check,
## so what the player sees is exactly what the rules accept.


class Reach:
	extends RefCounted
	var origin: Vector2i
	## Movement spent to reach each visited cell (origin included, cost 0).
	var cost: Dictionary[Vector2i, int] = {}
	## Previous cell on the cheapest path to each visited cell.
	var prev: Dictionary[Vector2i, Vector2i] = {}
	## Cells the unit may stop on (visited, not occupied, not the origin).
	var destinations: Array[Vector2i] = []

	func can_reach(cell: Vector2i) -> bool:
		return destinations.has(cell)

	## Path from the origin (excluded) to [param cell] (included).
	func path_to(cell: Vector2i) -> Array[Vector2i]:
		var path: Array[Vector2i] = []
		if not cost.has(cell):
			return path
		var c := cell
		while c != origin:
			path.push_front(c)
			c = prev[c]
		return path


## Every cell [param unit] can move to with [param budget] movement.
static func reachable(board: BoardState, unit: UnitState, budget: int,
		rules: MoveRules = null) -> Reach:
	if rules == null:
		rules = MoveRules.walk()
	var reach := Reach.new()
	reach.origin = unit.cell
	reach.cost[unit.cell] = 0
	var frontier: Array[Vector2i] = [unit.cell]

	while not frontier.is_empty():
		# Pop the cheapest cell. Boards are small, so a sorted array is fine.
		frontier.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return reach.cost[a] < reach.cost[b])
		var current: Vector2i = frontier.pop_front()

		for n in board.neighbors(current):
			if board.blocks_move(n):
				continue
			if not _can_pass(board, unit, n, rules):
				continue
			var step := 1 if rules.ignore_terrain_cost else board.move_cost(n)
			var new_cost := reach.cost[current] + step
			if new_cost > budget:
				continue
			if not reach.cost.has(n) or new_cost < reach.cost[n]:
				reach.cost[n] = new_cost
				reach.prev[n] = current
				if not frontier.has(n):
					frontier.append(n)

	for cell in reach.cost:
		if cell != unit.cell and not board.is_occupied(cell):
			reach.destinations.append(cell)
	return reach


static func _can_pass(board: BoardState, mover: UnitState, cell: Vector2i,
		rules: MoveRules) -> bool:
	var other := board.unit_at(cell)
	if other == null:
		return true
	match rules.pass_through:
		Enums.PassThrough.ALL:
			return true
		Enums.PassThrough.ALLIES:
			return other.team == mover.team
		_:
			return false
