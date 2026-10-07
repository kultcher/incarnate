class_name BoardState
extends RefCounted
## The only object that knows what is on each cell.
## Pathing, targeting, the AI and the highlights all ask this; nothing else
## tracks occupancy.

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT,
]

var size: Vector2i
var _terrain: Dictionary[Vector2i, Terrain] = {}
var _occupant: Dictionary[Vector2i, UnitState] = {}


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


# --- Units ---------------------------------------------------------------

func unit_at(cell: Vector2i) -> UnitState:
	return _occupant.get(cell)


func is_occupied(cell: Vector2i) -> bool:
	return _occupant.has(cell)


func units() -> Array[UnitState]:
	var result: Array[UnitState] = []
	result.assign(_occupant.values())
	return result


func place_unit(unit: UnitState, cell: Vector2i) -> void:
	assert(in_bounds(cell), "Cell %s is off the board." % cell)
	assert(not blocks_move(cell), "Cell %s is blocked terrain." % cell)
	assert(not is_occupied(cell), "Cell %s is already occupied." % cell)
	_occupant[cell] = unit
	unit.cell = cell
	unit.turn_start_cell = cell


func move_unit(unit: UnitState, to: Vector2i) -> void:
	assert(_occupant.get(unit.cell) == unit, "Unit is not where it thinks it is.")
	assert(to == unit.cell or not is_occupied(to), "Destination %s is occupied." % to)
	_occupant.erase(unit.cell)
	_occupant[to] = unit
	unit.cell = to


func remove_unit(unit: UnitState) -> void:
	if _occupant.get(unit.cell) == unit:
		_occupant.erase(unit.cell)
