class_name ShiftStrikeRule
extends TargetRule
## Displacer Strike's picks. Step 0: a foe that is in reach before or after
## a shift of up to [member shift_distance]. Step 1: where to shift to (an
## empty square, or staying put), such that the foe is in reach either before
## or after.

@export var shift_distance: int = 2


func cells(board: BoardState, caster: UnitState, step_index: int,
		picks: Array[Vector2i]) -> Array[Vector2i]:
	var dests := destinations(board, caster)
	var result: Array[Vector2i] = []
	if step_index == 0:
		for unit in board.units():
			if not caster.is_foe(unit):
				continue
			if _in_reach(unit.cell, caster.cell, dests):
				result.append(unit.cell)
		return result
	var foe_cell := picks[0]
	var adjacent_now := BoardState.distance(foe_cell, caster.cell) == 1
	if adjacent_now:
		result.append(caster.cell)  # "Up to": striking without moving is allowed.
	for d in dests:
		if adjacent_now or BoardState.distance(foe_cell, d) == 1:
			result.append(d)
	return result


func destinations(board: BoardState, caster: UnitState) -> Array[Vector2i]:
	return Pathing.reachable(board, caster, shift_distance, MoveRules.shift()).destinations


func _in_reach(foe_cell: Vector2i, from: Vector2i, dests: Array[Vector2i]) -> bool:
	if BoardState.distance(foe_cell, from) == 1:
		return true
	for d in dests:
		if BoardState.distance(foe_cell, d) == 1:
			return true
	return false
