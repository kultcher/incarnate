class_name WaveArea
extends SkillArea
## A wave: [member width] squares wide and [member depth] deep, starting next
## to the caster and running in the direction picked in step 0.

@export var width: int = 3
@export var depth: int = 4


func cells(board: BoardState, caster: UnitState, picks: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if picks.is_empty():
		return out
	var dir := picks[0] - caster.cell
	if absi(dir.x) + absi(dir.y) != 1:
		return out
	var side := Vector2i(dir.y, dir.x)
	var half := width / 2
	for k in range(1, depth + 1):
		for w in range(-half, width - half):
			var cell := caster.cell + dir * k + side * w
			if board.in_bounds(cell):
				out.append(cell)
	return out
