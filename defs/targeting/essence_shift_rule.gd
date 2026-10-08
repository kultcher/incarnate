class_name EssenceShiftRule
extends TargetRule
## Essence Shift. Step 0: who teleports, the caster or a Tethered ally.
## Step 1: an empty square next to the other one (next to any Tethered
## ally, if the caster is the one moving).


func cells(board: BoardState, caster: UnitState, step_index: int,
		picks: Array[Vector2i]) -> Array[Vector2i]:
	var allies := Tethers.allies_of(caster, board)
	var result: Array[Vector2i] = []
	if allies.is_empty():
		return result
	if step_index == 0:
		result.append(caster.cell)
		for ally in allies:
			result.append(ally.cell)
		return result
	var anchors: Array[Vector2i] = []
	if picks[0] == caster.cell:
		for ally in allies:
			anchors.append(ally.cell)
	else:
		anchors.append(caster.cell)
	for anchor in anchors:
		for cell in board.neighbors(anchor):
			if not result.has(cell) and Targeting.passes_filter(board, caster,
					Enums.TargetFilter.EMPTY, cell):
				result.append(cell)
	return result
