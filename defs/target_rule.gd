class_name TargetRule
extends Resource
## Custom legal cells for one targeting step, for picks the shape/filter
## fields can't express. Subclasses override cells().


func cells(_board: BoardState, _caster: UnitState, _step_index: int,
		_picks: Array[Vector2i]) -> Array[Vector2i]:
	return []
