class_name StatusRangeRule
extends TargetRule
## An empty square within N of the caster, where N is the stacks of the
## caster's [member status_id] status (Flicker: the range Flickerstep drew).

@export var status_id: StringName = &"flicker"


func cells(board: BoardState, caster: UnitState, _step_index: int,
		_picks: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var inst := caster.find_status(status_id)
	if inst == null:
		return out
	for cell in Targeting.cells_within(board, caster.cell, 1, inst.stacks):
		if Targeting.passes_filter(board, caster, Enums.TargetFilter.EMPTY, cell):
			out.append(cell)
	return out
