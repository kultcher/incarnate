class_name ShiftStrikeRule
extends TargetRule
## Displacer Strike's picks. Step 0: a foe that is in reach before or after
## a shift of up to [member shift_distance] (any of a Large foe's squares can
## be clicked). Step 1: where to shift to (an empty square, or staying put),
## such that the foe is in reach either before or after. Reach counts from
## the foe's nearest square. A Shadow using it shifts [member shadow_bonus]
## squares further.

@export var shift_distance: int = 2
@export var shadow_bonus: int = 2


func cells(board: BoardState, caster: UnitState, step_index: int,
		picks: Array[Vector2i]) -> Array[Vector2i]:
	var dests := destinations(board, caster)
	var result: Array[Vector2i] = []
	if step_index == 0:
		for unit in board.units():
			if caster.is_foe(unit) and _in_reach(board, unit, caster.cell, dests):
				result.append_array(board.cells_of(unit))
		return result
	var foe := board.unit_at(picks[0])
	if foe == null:
		return result
	var adjacent_now := board.distance_to(foe, caster.cell) == 1
	if adjacent_now:
		result.append(caster.cell)  # "Up to": striking without moving is allowed.
	for d in dests:
		if adjacent_now or board.distance_to(foe, d) == 1:
			result.append(d)
	return result


func reach_for(caster: UnitState) -> int:
	return shift_distance + (shadow_bonus if caster.shadow_of != null else 0)


func destinations(board: BoardState, caster: UnitState) -> Array[Vector2i]:
	return Pathing.reachable(board, caster, reach_for(caster), MoveRules.shift()).destinations


func _in_reach(board: BoardState, foe: UnitState, from: Vector2i, dests: Array[Vector2i]) -> bool:
	if board.distance_to(foe, from) == 1:
		return true
	for d in dests:
		if board.distance_to(foe, d) == 1:
			return true
	return false
