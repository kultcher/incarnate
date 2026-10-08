class_name BoardState
extends RefCounted
## The only object that knows what is on each cell.
## Pathing, targeting, the AI and the highlights all ask this; nothing else
## tracks occupancy. A Large unit (footprint 2) fills a 2x2 block of cells;
## its own cell is the block's top-left square.

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT,
]

var size: Vector2i
var _terrain: Dictionary[Vector2i, Terrain] = {}
var _occupant: Dictionary[Vector2i, UnitState] = {}
## Every unit on the board, in the order they were placed.
var _units: Array[UnitState] = []


func _init(p_size: Vector2i = Vector2i.ZERO) -> void:
	size = p_size
	for y in size.y:
		for x in size.x:
			_terrain[Vector2i(x, y)] = Terrain.new()


## Builds a board from a level's tile layers. Every used cell on [param ground]
## is part of the board; [param obstacles] cells read their custom data
## ([code]blocks_move[/code], [code]move_cost[/code]).
static func from_layers(ground: TileMapLayer, obstacles: TileMapLayer) -> BoardState:
	var used := ground.get_used_rect()
	assert(used.position == Vector2i.ZERO, "Ground layer must start at cell (0, 0).")
	var board := BoardState.new(used.size)
	for cell in board._terrain:
		var t := board._terrain[cell]
		for layer: TileMapLayer in [ground, obstacles]:
			if layer == null:
				continue
			var data := layer.get_cell_tile_data(cell)
			if data == null:
				continue
			if data.get_custom_data("blocks_move"):
				t.blocks_move = true
			t.move_cost = maxi(t.move_cost, int(data.get_custom_data("move_cost")))
	return board


# --- Terrain -------------------------------------------------------------

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func terrain_at(cell: Vector2i) -> Terrain:
	return _terrain.get(cell)


func set_terrain(cell: Vector2i, terrain: Terrain) -> void:
	assert(in_bounds(cell))
	_terrain[cell] = terrain


func blocks_move(cell: Vector2i) -> bool:
	return not in_bounds(cell) or _terrain[cell].blocks_move


func move_cost(cell: Vector2i) -> int:
	return _terrain[cell].move_cost


## Orthogonal neighbours that are on the board.
func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for d in DIRECTIONS:
		var n := cell + d
		if in_bounds(n):
			result.append(n)
	return result


static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## The cells a unit with [param footprint] fills when its cell is [param anchor].
static func footprint_cells(anchor: Vector2i, footprint: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dy in footprint:
		for dx in footprint:
			cells.append(anchor + Vector2i(dx, dy))
	return cells


## The cells [param unit] fills.
func cells_of(unit: UnitState) -> Array[Vector2i]:
	return footprint_cells(unit.cell, unit.def.footprint)


## Squares from [param cell] to the nearest square of [param unit].
func distance_to(unit: UnitState, cell: Vector2i) -> int:
	var best := 1 << 30
	for c in cells_of(unit):
		best = mini(best, distance(c, cell))
	return best


## Squares between the nearest squares of two units (1 = adjacent).
func gap(a: UnitState, b: UnitState) -> int:
	var best := 1 << 30
	for c in cells_of(a):
		best = mini(best, distance_to(b, c))
	return best


## The squares next to [param unit] (outside it), for Large units too.
func cells_around(unit: UnitState) -> Array[Vector2i]:
	var own := cells_of(unit)
	var out: Array[Vector2i] = []
	for c in own:
		for n in neighbors(c):
			if not own.has(n) and not out.has(n):
				out.append(n)
	return out


## True if [param unit] could stand with its cell at [param anchor]: every
## square on the board, not blocked, and empty or its own.
func can_stand(unit: UnitState, anchor: Vector2i) -> bool:
	for c in footprint_cells(anchor, unit.def.footprint):
		if blocks_move(c):
			return false
		var other: UnitState = _occupant.get(c)
		if other != null and other != unit:
			return false
	return true


# --- Units ---------------------------------------------------------------

func unit_at(cell: Vector2i) -> UnitState:
	return _occupant.get(cell)


func is_occupied(cell: Vector2i) -> bool:
	return _occupant.has(cell)


func units() -> Array[UnitState]:
	return _units.duplicate()


func place_unit(unit: UnitState, cell: Vector2i) -> void:
	assert(in_bounds(cell), "Cell %s is off the board." % cell)
	assert(can_stand(unit, cell), "Unit can't stand at %s." % cell)
	for c in footprint_cells(cell, unit.def.footprint):
		_occupant[c] = unit
	_units.append(unit)
	unit.cell = cell
	unit.turn_start_cell = cell


func move_unit(unit: UnitState, to: Vector2i) -> void:
	assert(_occupant.get(unit.cell) == unit, "Unit is not where it thinks it is.")
	assert(can_stand(unit, to), "Unit can't stand at %s." % to)
	for c in cells_of(unit):
		_occupant.erase(c)
	for c in footprint_cells(to, unit.def.footprint):
		_occupant[c] = unit
	unit.cell = to


func remove_unit(unit: UnitState) -> void:
	for c in cells_of(unit):
		if _occupant.get(c) == unit:
			_occupant.erase(c)
	_units.erase(unit)
