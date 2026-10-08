class_name ShiftRule
extends TargetRule
## An empty square the caster can shift to, up to [member distance] squares
## (through any unit). Elusive Infusion's shift.

@export var distance: int = 2


func cells(board: BoardState, caster: UnitState, _step_index: int,
		_picks: Array[Vector2i]) -> Array[Vector2i]:
	return Pathing.reachable(board, caster, distance, MoveRules.shift()).destinations
