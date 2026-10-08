class_name GolgothonEncounter
extends Encounter
## Golgothon the Restless (see references/golgothon-reference.md). Each
## enemy phase runs the booklet's steps in order:
##   I    the round's scripted skill: Death's Grasp (rounds 2, 5, 8...),
##        Death's Caress (3, 6, 9...) or Unquenched (4, 7, 10...)
##   II   Grave Smash (falls back to Carrion Spew out of reach)
##   III  Carrion Spew
##   IV   Welcoming Dead: summon 3 minions
##   V    each Welcoming Dead acts, starting nearest the north-west corner
## Targets follow the booklet's rules and are shown during the player phase.

const GRASP := &"deaths_grasp"
const CARESS := &"deaths_caress"
const UNQUENCHED := &"unquenched"

@export var boss_id: StringName = &"golgothon"
@export var minion_def: UnitDef
@export var unquenched_status: StatusDef
@export var daze_status: StatusDef
@export var mark_id: StringName = &"restless_dead"
@export var mark_icon: Texture2D

@export_group("Numbers")
@export var burst: int = 6
@export var grasp_tiers: Array[Enums.Tier] = [Enums.Tier.BRONZE]
@export var grasp_pull: int = 5
## Death's Caress: health lost is this minus the distance (6 when adjacent).
@export var caress_base: int = 7
@export var smash_move: int = 4
@export var smash_tiers: Array[Enums.Tier] = [Enums.Tier.SILVER, Enums.Tier.SILVER, Enums.Tier.BRONZE]
@export var spew_range: int = 6
@export var spew_tiers: Array[Enums.Tier] = [Enums.Tier.SILVER, Enums.Tier.BRONZE]
@export var summon_count: int = 3
## Welcoming Arms: flat damage, +1 Power and +1 move per Unquenched stack.
@export var minion_strike: int = 2
## Health Golgothon loses for each Restless Dead raised by Unquenched.
@export var raise_cost: int = 1

@export_group("Icons")
@export var grasp_icon: Texture2D
@export var caress_icon: Texture2D
@export var unquenched_icon: Texture2D
@export var smash_icon: Texture2D
@export var spew_icon: Texture2D
@export var summon_icon: Texture2D

const DARK_GREEN := Color(0.45, 1.0, 0.45)
const PURPLE := Color(0.8, 0.5, 1.0)


#region State

func boss() -> UnitState:
	for unit in board.units():
		if unit.def.id == boss_id and unit.is_alive():
			return unit
	return null


func is_won() -> bool:
	return board != null and boss() == null


## Unquenched stacks on Golgothon.
func stacks() -> int:
	var b := boss()
	if b == null:
		return 0
	var inst := b.find_status(unquenched_status.id) if unquenched_status != null else null
	return inst.stacks if inst != null else 0


## The scripted skill (step I) of round [param n], or &"" on round 1.
static func scripted_step(n: int) -> StringName:
	match n % 3:
		2:
			return GRASP
		0:
			return CARESS
		_:
			return UNQUENCHED if n > 1 else &""


func _foes() -> Array[UnitState]:
	var out: Array[UnitState] = []
	for unit in board.units():
		if unit.is_player() and unit.is_alive():
			out.append(unit)
	return out


func _in_burst(b: UnitState) -> Array[UnitState]:
	var out: Array[UnitState] = []
	for foe in _foes():
		if board.distance_to(b, foe.cell) <= burst:
			out.append(foe)
	return out


## Grave Smash: whoever dealt him the most damage this turn; if nobody has,
## the nearest foe.
func smash_target() -> UnitState:
	var b := boss()
	if b == null:
		return null
	var tally: Dictionary = {}
	for inst in b.statuses:
		if inst.def.behavior is GolgothonTraitsBehavior:
			tally = GolgothonTraitsBehavior.damage_by(inst)
	var best: UnitState = null
	for foe in _foes():
		if best == null:
			best = foe
			continue
		var a := int(tally.get(foe.id, 0))
		var c := int(tally.get(best.id, 0))
		if a > c or (a == c and board.distance_to(b, foe.cell) < board.distance_to(b, best.cell)):
			best = foe
	return best


## Carrion Spew: the foe with the most health within range.
func spew_target() -> UnitState:
	var b := boss()
	if b == null:
		return null
	var best: UnitState = null
	for foe in _foes():
		if board.distance_to(b, foe.cell) > spew_range:
			continue
		if best == null or foe.hp > best.hp or (foe.hp == best.hp and foe.id < best.id):
			best = foe
	return best


## Welcoming Dead: the foe furthest from him.
func summon_target() -> UnitState:
	var b := boss()
	if b == null:
		return null
	var best: UnitState = null
	for foe in _foes():
		if best == null or board.distance_to(b, foe.cell) > board.distance_to(b, best.cell):
			best = foe
	return best

#endregion

#region Intents

func intents() -> Array[Intent]:
	var out: Array[Intent] = []
	var b := boss()
	if b == null or round_number <= 0:
		return out
	var step := scripted_step(round_number)
	if step == GRASP:
		var grasp := Intent.new("Death's Grasp",
				"Strikes each Incarnate within %d for %s, then pulls them %d squares toward him, nearest first. Death's Caress follows next turn." \
				% [burst, Soulstream.describe(grasp_tiers), grasp_pull], grasp_icon)
		grasp.color = DARK_GREEN
		grasp.cells = _burst_cells(b)
		out.append(grasp)
	elif step == CARESS:
		var caress := Intent.new("Death's Caress",
				"Each Incarnate within %d loses %d health minus its distance from him (the numbers). Get away!" \
				% [burst, caress_base], caress_icon)
		caress.color = DARK_GREEN
		for cell in _burst_cells(b):
			var loss := caress_base - board.distance_to(b, cell)
			if loss > 0:
				caress.cells.append(cell)
				caress.numbers[cell] = loss
		out.append(caress)
	elif step == UNQUENCHED:
		var unq := Intent.new("Unquenched",
				"He gains +1 Power, his minions move and hit harder, and each gravestone rises as a Welcoming Dead (he loses %d health for each)." \
				% raise_cost, unquenched_icon)
		unq.color = PURPLE
		unq.cells = resolver.marks_of(mark_id)
		out.append(unq)
	var smash := Intent.new("Grave Smash",
			"Moves %d toward whoever dealt him the most damage this turn (trampling anyone in the way). If he reaches them: %s and Daze. Otherwise he Spews at them." \
			% [smash_move, Soulstream.describe(smash_tiers)], smash_icon)
	smash.target = smash_target()
	out.append(smash)
	var spew := Intent.new("Carrion Spew",
			"Strikes the Incarnate with the most health within %d for %s and knocks it 1 square in a random direction." \
			% [spew_range, Soulstream.describe(spew_tiers)], spew_icon)
	spew.target = spew_target()
	spew.color = Color(1.0, 0.6, 0.3)
	if spew.target != null:
		out.append(spew)
	var summon := Intent.new("Welcoming Dead",
			"Raises %d Welcoming Dead around the Incarnate furthest from him. Two next to you hold you in place." \
			% summon_count, summon_icon)
	summon.target = summon_target()
	summon.color = Color(0.7, 0.7, 0.75)
	out.append(summon)
	return out


func danger(cell: Vector2i, team: Enums.Team) -> int:
	if team != Enums.Team.PLAYER or scripted_step(round_number) != CARESS:
		return 0
	var b := boss()
	if b == null:
		return 0
	return maxi(caress_base - board.distance_to(b, cell), 0)


func _burst_cells(b: UnitState) -> Array[Vector2i]:
	var own := board.cells_of(b)
	var out: Array[Vector2i] = []
	for y in board.size.y:
		for x in board.size.x:
			var cell := Vector2i(x, y)
			if not own.has(cell) and board.distance_to(b, cell) <= burst:
				out.append(cell)
	return out

#endregion

#region The enemy phase

func begin_round(n: int) -> void:
	await super.begin_round(n)
	var b := boss()
	if b != null and scripted_step(n) == CARESS:
		resolver.announce(b, "The necrotic mist thickens...", DARK_GREEN)


func take_turn(_team: Enums.Team) -> void:
	if boss() == null:
		return
	match scripted_step(round_number):
		GRASP:
			await run_step(_deaths_grasp)
		CARESS:
			await run_step(_deaths_caress)
		UNQUENCHED:
			await run_step(_unquenched)
	if boss() != null:
		await run_step(_grave_smash)
	if boss() != null:
		await run_step(_carrion_spew)
	if boss() != null:
		await run_step(_welcoming_dead)
	for minion in _minions_in_order():
		if is_over.call():
			return
		if minion.is_alive():
			await run_step(_welcoming_arms.bind(minion))


func _deaths_grasp() -> void:
	var b := boss()
	resolver.announce(b, "Death's Grasp", DARK_GREEN)
	var caught := _in_burst(b)
	for foe in caught:
		if foe.is_alive() and b.is_alive():
			await resolver.strike(b, foe, StrikeSpec.cards(grasp_tiers, null, false))
	caught.sort_custom(func(x: UnitState, y: UnitState) -> bool:
		return board.distance_to(b, x.cell) < board.distance_to(b, y.cell))
	for foe in caught:
		if foe.is_alive() and b.is_alive():
			await resolver.force_unit(foe, _nearest_cell(b, foe.cell), grasp_pull, true)


func _deaths_caress() -> void:
	var b := boss()
	resolver.announce(b, "Death's Caress", DARK_GREEN)
	for foe in _in_burst(b):
		var loss := caress_base - board.distance_to(b, foe.cell)
		if loss > 0 and foe.is_alive():
			resolver.lose_health(foe, loss)


func _unquenched() -> void:
	var b := boss()
	resolver.announce(b, "Unquenched", PURPLE)
	if unquenched_status != null:
		await resolver.apply_status(b, unquenched_status, b)
	var raised := 0
	for cell in resolver.marks_of(mark_id):
		var at := cell
		if board.is_occupied(at) or board.blocks_move(at):
			var probe := UnitState.new(minion_def, Enums.Team.ENEMY)
			at = resolver.nearest_open(probe, cell)
		if at != Vector2i(-1, -1) and await resolver.summon(minion_def, Enums.Team.ENEMY, at) != null:
			raised += 1
	resolver.set_marks(mark_id, [] as Array[Vector2i], mark_icon)
	if raised > 0:
		resolver.lose_health(b, raised * raise_cost)


func _grave_smash() -> void:
	var b := boss()
	var target := smash_target()
	if target == null:
		return
	resolver.announce(b, "Grave Smash", Color(1.0, 0.45, 0.4))
	for i in smash_move:
		if board.gap(b, target) <= 1 or not b.is_alive():
			break
		var step := _step_toward(b, target)
		if step == Vector2i(-1, -1):
			break
		# Trample: anyone in the way is pushed into the nearest open square.
		var footprint := BoardState.footprint_cells(step, b.def.footprint)
		for cell in footprint:
			var other := board.unit_at(cell)
			if other != null and other != b:
				await resolver.displace(other, footprint)
		if not board.can_stand(b, step):
			break
		await resolver.move_along(b, [step] as Array[Vector2i], Enums.MoveKind.WALK)
	if not target.is_alive() or not b.is_alive():
		return
	if board.gap(b, target) <= 1:
		var hit := await resolver.strike(b, target, StrikeSpec.cards(smash_tiers, null, true))
		if not hit.cancelled and target.is_alive() and daze_status != null:
			await resolver.apply_status(target, daze_status, b)
	elif board.distance_to(b, target.cell) <= spew_range:
		await _spew_at(target)


## The neighbouring anchor that brings [param b] closest to [param target]
## (terrain only: units are trampled), or (-1, -1) if none gets closer.
func _step_toward(b: UnitState, target: UnitState) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_gap := board.gap(b, target)
	for dir in BoardState.DIRECTIONS:
		var anchor := b.cell + dir
		var ok := true
		var g := 1 << 30
		for cell in BoardState.footprint_cells(anchor, b.def.footprint):
			if board.blocks_move(cell):
				ok = false
				break
			g = mini(g, BoardState.distance(cell, target.cell))
		if ok and g < best_gap:
			best_gap = g
			best = anchor
	return best


func _carrion_spew() -> void:
	var target := spew_target()
	if target != null:
		await _spew_at(target)


func _spew_at(target: UnitState) -> void:
	var b := boss()
	resolver.announce(b, "Carrion Spew", Color(1.0, 0.6, 0.3))
	var hit := await resolver.strike(b, target, StrikeSpec.cards(spew_tiers, null, false))
	if hit.cancelled or not target.is_alive():
		return
	var rng := resolver.soulstream(Enums.Team.ENEMY).rng
	var dir: Vector2i = BoardState.DIRECTIONS[rng.randi_range(0, 3)]
	await resolver.move_along(target, [target.cell + dir] as Array[Vector2i], Enums.MoveKind.FORCED)


func _welcoming_dead() -> void:
	var b := boss()
	var target := summon_target()
	if target == null or minion_def == null:
		return
	resolver.announce(b, "Welcoming Dead", Color(0.75, 0.75, 0.8))
	var spots: Array[Vector2i] = []
	for y in board.size.y:
		for x in board.size.x:
			var cell := Vector2i(x, y)
			if not board.blocks_move(cell) and not board.is_occupied(cell):
				spots.append(cell)
	# Nearest the target first; among equals, further from Golgothon.
	spots.sort_custom(func(p: Vector2i, q: Vector2i) -> bool:
		var dp := BoardState.distance(p, target.cell)
		var dq := BoardState.distance(q, target.cell)
		if dp != dq:
			return dp < dq
		var bp := board.distance_to(b, p)
		var bq := board.distance_to(b, q)
		if bp != bq:
			return bp > bq
		return p.y < q.y or (p.y == q.y and p.x < q.x))
	for i in mini(summon_count, spots.size()):
		await resolver.summon(minion_def, Enums.Team.ENEMY, spots[i])


func _minions_in_order() -> Array[UnitState]:
	var out: Array[UnitState] = []
	for unit in board.units():
		if minion_def != null and unit.def == minion_def and unit.is_alive():
			out.append(unit)
	out.sort_custom(func(p: UnitState, q: UnitState) -> bool:
		var dp := p.cell.x + p.cell.y
		var dq := q.cell.x + q.cell.y
		return dp < dq or (dp == dq and p.id < q.id))
	return out


## Welcoming Arms: move (1 per Unquenched stack) toward the nearest foe,
## then strike a random adjacent foe.
func _welcoming_arms(minion: UnitState) -> void:
	if not minion.is_alive():
		return
	var s := stacks()
	if s > 0 and not _has_adjacent_foe(minion):
		var reach := Pathing.reachable(board, minion, s)
		var best := Vector2i(-1, -1)
		var best_d := _nearest_foe_distance(minion.cell)
		for cell in reach.destinations:
			var d := _nearest_foe_distance(cell)
			if d < best_d:
				best_d = d
				best = cell
		if best != Vector2i(-1, -1):
			await resolver.move_along(minion, reach.path_to(best), Enums.MoveKind.WALK)
	var adjacent: Array[UnitState] = []
	for cell in board.cells_around(minion):
		var other := board.unit_at(cell)
		if other != null and minion.is_foe(other) and not adjacent.has(other):
			adjacent.append(other)
	if adjacent.is_empty():
		return
	var rng := resolver.soulstream(Enums.Team.ENEMY).rng
	var victim := adjacent[rng.randi_range(0, adjacent.size() - 1)]
	var spec := StrikeSpec.flat(minion_strike, null, true)
	spec.power = s
	await resolver.strike(minion, victim, spec)


func _has_adjacent_foe(unit: UnitState) -> bool:
	for cell in board.cells_around(unit):
		var other := board.unit_at(cell)
		if other != null and unit.is_foe(other):
			return true
	return false


func _nearest_foe_distance(cell: Vector2i) -> int:
	var best := 1 << 30
	for foe in _foes():
		best = mini(best, BoardState.distance(cell, foe.cell))
	return best


## The square of [param b] nearest [param cell] (the pull's anchor).
func _nearest_cell(b: UnitState, cell: Vector2i) -> Vector2i:
	var best := b.cell
	for c in board.cells_of(b):
		if BoardState.distance(c, cell) < BoardState.distance(best, cell):
			best = c
	return best

#endregion
