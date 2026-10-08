class_name AiPlanner
extends RefCounted
## Chooses one action at a time for an AI-controlled unit, using the same
## rule functions the player's UI uses (Pathing, Targeting, the resolver's
## can_use). Pure: no nodes, no awaits. It may move units on the board while
## it thinks, but always puts them back before returning.
##
## Greedy and simple on purpose (milestone 3). Later it can simulate whole
## turns on a copy of the battle.

## Score weights live in AiScore.
const KILL_BONUS := AiScore.KILL_BONUS
## Stop enumerating target combinations past this many per skill.
const MAX_COMBOS := 400
## Score lost per point of health a cell would cost in the enemy phase
## (ActionResolver.danger: Death's Caress).
const DANGER_WEIGHT := 3.0


## One thing to do: a skill with its picks, or a move.
class Plan:
	var skill: SkillDef
	var picks: Array[Vector2i] = []
	var move_to := Vector2i(-1, -1)
	var score: float = 0.0

	func is_move() -> bool:
		return skill == null

	func _to_string() -> String:
		if is_move():
			return "move to %s (%.2f)" % [move_to, score]
		return "%s on %s (%.2f)" % [skill.id, picks, score]


## The best skill [param unit] can use from where it stands now, or null if
## nothing usable would hurt a foe.
static func best_attack(board: BoardState, resolver: ActionResolver, unit: UnitState) -> Plan:
	var best: Plan = null
	for skill in unit.skills():
		if not resolver.can_use(unit, skill) or not knows(skill):
			continue
		var plan := _best_picks(board, unit, skill)
		if plan != null and (best == null or plan.score > best.score):
			best = plan
	return best


## The best cell to move to this action, or null to stay put.
## Prefers a cell from which a skill can hit a foe afterwards; otherwise the
## cell that gets closest to the nearest foe.
static func best_move(board: BoardState, resolver: ActionResolver, unit: UnitState) -> Plan:
	if not resolver.can_move(unit):
		return null
	var reach := Pathing.reachable(board, unit, unit.get_stat(&"move"))
	if reach.destinations.is_empty():
		return null
	var can_attack_after := _can_attack_after_move(resolver, unit)
	var distance := _distance_to_foes(board, unit)
	var home := unit.cell
	var here_distance: int = distance.get(home, 999)
	var danger_here: int = resolver.danger.call(home, unit.team)

	var best: Plan = null
	var best_attack_here := 0.0
	if can_attack_after:
		var here := _best_attack_ignoring_cost(board, resolver, unit)
		best_attack_here = here.score if here != null else 0.0

	var cells: Array[Vector2i] = reach.destinations.duplicate()
	cells.sort()  # Deterministic tie-breaks.
	for cell in cells:
		var score := 0.0
		if can_attack_after:
			board.move_unit(unit, cell)
			var attack := _best_attack_ignoring_cost(board, resolver, unit)
			board.move_unit(unit, home)
			if attack != null:
				score = 100.0 + attack.score
		var danger: int = resolver.danger.call(cell, unit.team)
		if score == 0.0:
			# No attack from there: get closer (or out of danger).
			var d: int = distance.get(cell, 999)
			if d >= here_distance and danger >= danger_here:
				continue
			score = 50.0 - d
		score -= reach.cost[cell] * 0.01  # Prefer shorter walks.
		score -= danger * DANGER_WEIGHT
		if best == null or score > best.score:
			best = Plan.new()
			best.move_to = cell
			best.score = score

	if best == null:
		return null
	# Don't walk away from a spot that's as good: the best attack is already
	# available here, or it's no safer elsewhere.
	var stay := 100.0 + best_attack_here if best_attack_here > 0.0 else 50.0 - here_distance
	stay -= danger_here * DANGER_WEIGHT
	if (best_attack_here > 0.0 or danger_here > 0) and best.score < stay:
		return null
	return best


## The next thing [param unit] should do this turn, or null when done.
static func next_action(board: BoardState, resolver: ActionResolver, unit: UnitState) -> Plan:
	var attack := best_attack(board, resolver, unit)
	if attack != null:
		return attack
	return best_move(board, resolver, unit)


## Held cards worth readying for [param skill], from [param unit]'s hand and
## the shared row. Readied cards replace the skill's lowest-tier draws, so
## readying the best k cards gains their total minus the medians of the k
## lowest tiers; this picks the k that gains most (the fewest on a tie).
## Greedy: it doesn't save cards for later.
static func choose_cards(resolver: ActionResolver, unit: UnitState, skill: SkillDef) -> Array[Card]:
	var chosen: Array[Card] = []
	var slots := skill.card_tiers()
	if slots.is_empty():
		return chosen
	slots.sort()
	var pool: Array[Card] = unit.hand.duplicate()
	pool.append_array(resolver.soulstream(unit.team).row)
	# Highest value first; your own card before a shared one on a tie.
	pool.sort_custom(func(a: Card, b: Card) -> bool:
		return a.value > b.value or (a.value == b.value and unit.hand.has(a) and not unit.hand.has(b)))
	var best_k := 0
	var best_gain := 0
	var gain := 0
	for k in mini(slots.size(), pool.size()):
		gain += pool[k].value - Soulstream.median(slots[k])
		if gain > best_gain:
			best_gain = gain
			best_k = k + 1
	chosen.assign(pool.slice(0, best_k))
	return chosen


## True if the AI can judge [param skill] (it has an effect that scores).
## The AI leaves the rest alone for now.
static func knows(skill: SkillDef) -> bool:
	for effect in skill.effects:
		if effect.has_ai_value():
			return true
	return false


static func _can_attack_after_move(resolver: ActionResolver, unit: UnitState) -> bool:
	for skill in unit.skills():
		if knows(skill) and resolver.can_use_ignoring_points(unit, skill) \
				and unit.actions.can_pay_both(Enums.Cost.MOVE, resolver.cost_of(unit, skill)):
			return true
	return false


## Best attack from the current cell, checking every rule except points.
static func _best_attack_ignoring_cost(board: BoardState, resolver: ActionResolver,
		unit: UnitState) -> Plan:
	var best: Plan = null
	for skill in unit.skills():
		if not resolver.can_use_ignoring_points(unit, skill) or not knows(skill):
			continue
		var plan := _best_picks(board, unit, skill)
		if plan != null and (best == null or plan.score > best.score):
			best = plan
	return best


static func _best_picks(board: BoardState, unit: UnitState, skill: SkillDef) -> Plan:
	var combos: Array = []
	if skill.is_path():
		combos = Targeting.all_paths(board, unit, skill, MAX_COMBOS)
	elif skill.targets.is_empty():
		combos = [[] as Array[Vector2i]]
	else:
		_enumerate(board, unit, skill, [], combos)
	var best: Plan = null
	for combo: Array[Vector2i] in combos:
		var score := score_picks(board, skill, combo, unit)
		if score > 0.0 and (best == null or score > best.score):
			best = Plan.new()
			best.skill = skill
			best.picks = combo
			best.score = score
	return best


static func _enumerate(board: BoardState, unit: UnitState, skill: SkillDef,
		picks: Array[Vector2i], out: Array) -> void:
	if out.size() >= MAX_COMBOS:
		return
	if picks.size() == skill.targets.size():
		out.append(picks.duplicate())
		return
	var cells := Targeting.valid_cells(board, unit, skill, picks.size(), picks)
	cells.sort()
	for cell in cells:
		picks.append(cell)
		_enumerate(board, unit, skill, picks, out)
		picks.pop_back()


## Expected value of using [param skill] with [param picks]: damage dealt to
## foes (capped at their HP), plus bonuses for kills and Provoke, plus
## healing where it's needed (see AiScore).
static func score_picks(board: BoardState, skill: SkillDef, picks: Array[Vector2i],
		attacker: UnitState) -> float:
	var score := AiScore.new(attacker)
	for effect in skill.effects:
		effect.ai_score(score, board, attacker, picks)
	return score.total


## Steps from each cell to the nearest cell next to a foe, walking through
## allies of [param unit] but not through foes or blocked terrain.
static func _distance_to_foes(board: BoardState, unit: UnitState) -> Dictionary[Vector2i, int]:
	var dist: Dictionary[Vector2i, int] = {}
	var frontier: Array[Vector2i] = []
	for other in board.units():
		if other.team == unit.team:
			continue
		for cell in board.cells_around(other):
			if not dist.has(cell) and _walkable(board, unit, cell):
				dist[cell] = 0
				frontier.append(cell)
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		for next in board.neighbors(cell):
			if not dist.has(next) and _walkable(board, unit, next):
				dist[next] = dist[cell] + board.move_cost(next)
				frontier.append(next)
	return dist


static func _walkable(board: BoardState, unit: UnitState, cell: Vector2i) -> bool:
	if board.blocks_move(cell):
		return false
	var occupant := board.unit_at(cell)
	return occupant == null or occupant.team == unit.team
