class_name DirectionRule
extends TargetRule
## A direction, picked as one of the four squares next to the caster
## (Cinder Wave). Blocked squares count: a wave can start beside a rock.


func cells(board: BoardState, caster: UnitState, _step_index: int,
		_picks: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dir in BoardState.DIRECTIONS:
		if board.in_bounds(caster.cell + dir):
			out.append(caster.cell + dir)
	return out
