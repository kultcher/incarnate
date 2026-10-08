class_name Targeting
extends RefCounted
## Which cells are legal picks for a skill. The UI highlights exactly these
## cells and the resolver accepts exactly these cells.
##
## Most skills have targeting steps (one click each). Path skills (Bloody
## Rush, Phantom Dash) instead take a chain of squares clicked one by one; see
## the path_* functions.


## Legal cells for step [param step_index] of [param skill], given the cells
## already picked in earlier steps.
static func valid_cells(board: BoardState, caster: UnitState, skill: SkillDef,
		step_index: int, picks: Array[Vector2i]) -> Array[Vector2i]:
	var step := skill.targets[step_index]
	if step.rule != null:
		return step.rule.cells(board, caster, step_index, picks)
	var origin := caster.cell
	if step.origin == Enums.TargetOrigin.PREVIOUS and not picks.is_empty():
		origin = picks[-1]

	var result: Array[Vector2i] = []
	for cell in _shape_cells(board, caster, step, origin):
		if step.unique and picks.has(cell):
			continue
		if passes_filter(board, caster, step.filter, cell):
			result.append(cell)
	return result


## True if every pick in [param picks] is legal, in order.
static func are_valid_picks(board: BoardState, caster: UnitState, skill: SkillDef,
		picks: Array[Vector2i]) -> bool:
	if skill.is_path():
		return is_valid_path(board, caster, skill, picks)
	if picks.size() != skill.targets.size():
		return false
	for i in picks.size():
		var earlier: Array[Vector2i] = picks.slice(0, i)
		if not valid_cells(board, caster, skill, i, earlier).has(picks[i]):
			return false
	return true


## True if the skill could be started now: it has a legal first pick (or
## needs none).
static func has_any(board: BoardState, caster: UnitState, skill: SkillDef) -> bool:
	if skill.is_path():
		return not path_next_cells(board, caster, skill, []).is_empty()
	if skill.targets.is_empty():
		return true
	return not valid_cells(board, caster, skill, 0, []).is_empty()


static func passes_filter(board: BoardState, caster: UnitState,
		filter: Enums.TargetFilter, cell: Vector2i) -> bool:
	var unit := board.unit_at(cell)
	match filter:
		Enums.TargetFilter.ANY:
			return not board.blocks_move(cell) or unit != null
		Enums.TargetFilter.EMPTY:
			return unit == null and not board.blocks_move(cell)
		Enums.TargetFilter.UNIT:
			return unit != null
		Enums.TargetFilter.ENEMY:
			return unit != null and unit.team != caster.team
		Enums.TargetFilter.ALLY:
			return unit != null and unit.team == caster.team and unit != caster
		Enums.TargetFilter.ALLY_OR_SELF:
			return unit != null and unit.team == caster.team
		Enums.TargetFilter.OWN_SHADOW:
			return unit == null and caster.shadows.has(cell)
		Enums.TargetFilter.OTHER_UNIT:
			return unit != null and unit != caster
	return false


static func _shape_cells(board: BoardState, caster: UnitState, step: TargetStep,
		origin: Vector2i) -> Array[Vector2i]:
	match step.shape:
		Enums.TargetShape.SELF:
			return [caster.cell]
		Enums.TargetShape.ADJACENT:
			return board.neighbors(origin)
		Enums.TargetShape.WITHIN:
			return cells_within(board, origin, step.range_min, step.range_max)
	return []


## Cells from [param range_min] to [param range_max] squares from [param origin].
static func cells_within(board: BoardState, origin: Vector2i, range_min: int,
		range_max: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dy in range(-range_max, range_max + 1):
		for dx in range(-range_max, range_max + 1):
			var d := absi(dx) + absi(dy)
			var cell := origin + Vector2i(dx, dy)
			if d >= range_min and d <= range_max and board.in_bounds(cell):
				cells.append(cell)
	return cells


#region Paths

## Squares the path may cover: the base budget, plus the extension for each
## different foe it passes through.
static func path_budget(board: BoardState, caster: UnitState, skill: SkillDef,
		picks: Array[Vector2i]) -> int:
	return skill.path.budget + skill.path.extend_per_foe * path_foes(board, caster, picks).size()


## Movement the path has used so far (rough terrain costs 2).
static func path_cost(board: BoardState, picks: Array[Vector2i]) -> int:
	var total := 0
	for cell in picks:
		total += board.move_cost(cell)
	return total


## Different foes standing on the path's squares, in order.
static func path_foes(board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> Array[UnitState]:
	var foes: Array[UnitState] = []
	for cell in picks:
		var unit := board.unit_at(cell)
		if unit != null and caster.is_foe(unit) and not foes.has(unit):
			foes.append(unit)
	return foes


## Squares the path can continue into. A square that would use up the last
## of the budget must be empty, since the path has to end there.
static func path_next_cells(board: BoardState, caster: UnitState, skill: SkillDef,
		picks: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var from := caster.cell if picks.is_empty() else picks[-1]
	var used := path_cost(board, picks)
	for next in board.neighbors(from):
		if board.blocks_move(next) or next == caster.cell or picks.has(next):
			continue
		var trial: Array[Vector2i] = picks.duplicate()
		trial.append(next)
		var budget := path_budget(board, caster, skill, trial)
		var cost := used + board.move_cost(next)
		if cost > budget:
			continue
		if cost == budget and board.is_occupied(next):
			continue
		result.append(next)
	return result


## True if the path may stop where it is now.
static func path_can_finish(board: BoardState, caster: UnitState, skill: SkillDef,
		picks: Array[Vector2i]) -> bool:
	if picks.size() < skill.path.min_steps or picks.is_empty():
		return false
	return not board.is_occupied(picks[-1])


## True if no square can be added (the player's clicks end the path).
static func path_is_full(board: BoardState, caster: UnitState, skill: SkillDef,
		picks: Array[Vector2i]) -> bool:
	return path_next_cells(board, caster, skill, picks).is_empty()


static func is_valid_path(board: BoardState, caster: UnitState, skill: SkillDef,
		picks: Array[Vector2i]) -> bool:
	for i in picks.size():
		var earlier: Array[Vector2i] = picks.slice(0, i)
		if not path_next_cells(board, caster, skill, earlier).has(picks[i]):
			return false
	return path_can_finish(board, caster, skill, picks)


## Every complete path (up to [param limit]), for the AI.
static func all_paths(board: BoardState, caster: UnitState, skill: SkillDef,
		limit: int) -> Array:
	var out: Array = []
	_walk_paths(board, caster, skill, [], out, limit)
	return out


static func _walk_paths(board: BoardState, caster: UnitState, skill: SkillDef,
		picks: Array[Vector2i], out: Array, limit: int) -> void:
	if out.size() >= limit:
		return
	if path_can_finish(board, caster, skill, picks):
		out.append(picks.duplicate())
	for next in path_next_cells(board, caster, skill, picks):
		picks.append(next)
		_walk_paths(board, caster, skill, picks, out, limit)
		picks.pop_back()

#endregion
