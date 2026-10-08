class_name ActionResolver
extends Node
## The one place rules run. Every action from the player or the AI comes
## through here: validate, pay, change the model, then hand events to the
## event sink (the Presenter in a real battle).
##
## The model changes immediately; the Presenter plays events behind it.
## The resolver waits for playback only before asking for a decision and at
## the end of an action, so it can also run with no Presenter at all (tests,
## AI simulation).
##
## Statuses join in through hooks (StatusBehavior): before a hit lands, after
## it lands, when their owner moves, at the start of a turn or round...
## Anything a hook wants to do *after* the current action (Bound in Blood's
## Pact prompt, a Shadow copying an attack) goes on the follow-up queue,
## which drains before the action ends.

## Emitted after every action has resolved and finished playing.
signal action_finished

## Follow-ups queued by follow-ups queued by... stop here (a trigger loop).
const MAX_FOLLOWUPS := 32
## Recovery skills the whole team can use per battle.
const RECOVERIES_PER_BATTLE := 2

var board: BoardState
var events: EventSink
## Answers the player's decisions (the PromptDialog). Null = answer like the
## AI, which is what tests and autoplay use.
var player_decisions: DecisionProvider
## Answers everyone else's decisions.
var ai_decisions := DecisionProvider.new()
## Each side's Soulstream (decks, and the Incarnates' shared row), by team.
## Medians until use_decks() is called, so rules tests get fixed numbers.
var soulstreams: Dictionary[int, Soulstream] = {
	Enums.Team.PLAYER: Soulstream.new(),
	Enums.Team.ENEMY: Soulstream.new(),
}
## Health a unit of a team would lose on a cell when the enemy phase comes,
## (cell, team) -> int, set by a boss encounter. The AI steps out of it.
var danger: Callable = func(_cell: Vector2i, _team: Enums.Team) -> int: return 0
## Marks on the board by kind (Restless Dead), as lists of cells. They
## don't block anything. Change them through add_mark / set_marks.
var marks: Dictionary[StringName, Array] = {}
var _mark_icons: Dictionary[StringName, Texture2D] = {}
## Recovery skills used this battle, by team.
var recoveries_used: Dictionary[int, int] = {}

var _followups: Array[Callable] = []
## Counts skill uses this battle; 0 while none is resolving. Shadows
## remember the use that made them.
var action_number: int = 0
## The skill being resolved is a Burnout replay (its cards can't become Heat).
var action_is_copy: bool = false
var _uses_so_far: int = 0


func _ready() -> void:
	if ai_decisions.get_parent() == null:
		add_child(ai_decisions)


#region Actions

## Moves [param unit] to [param to] as a move action. Returns false and
## changes nothing if the move isn't legal.
func request_move(unit: UnitState, to: Vector2i) -> bool:
	if not can_move(unit):
		return false
	var reach := Pathing.reachable(board, unit, unit.get_stat(&"move"))
	if not reach.can_reach(to):
		return false

	var path := reach.path_to(to)
	var from := unit.cell
	unit.actions.pay(Enums.Cost.MOVE)
	board.move_unit(unit, to)
	unit.last_action_was_move = true

	_emit(GameEvent.unit_moved(unit, path))
	_emit(GameEvent.actions_changed(unit))
	await _after_moved(unit, Enums.MoveKind.WALK, from, path)
	await _finish_action()
	return true


func can_move(unit: UnitState) -> bool:
	return unit.is_alive() and unit.actions.can_pay(Enums.Cost.MOVE) \
			and not Pathing.is_held(board, unit)


## True if [param caster] could start [param skill] now (ignores targets).
func can_use(caster: UnitState, skill: SkillDef) -> bool:
	return caster.actions.can_pay(cost_of(caster, skill)) and can_use_ignoring_points(caster, skill)


## What [param skill] costs [param unit] now: free while a status makes it
## free (see _free_source), else the skill's own cost.
func cost_of(unit: UnitState, skill: SkillDef) -> Enums.Cost:
	if _free_source(unit, skill) != null:
		return Enums.Cost.FREE
	return skill.cost


## The status that would make [param skill] free for [param unit], used up
## when the skill is: a Burnout replay of that skill (tag echo), a free
## basic attack (tag free_basic: Potent Infusion, Spirit Flare), or Ignite
## (tag ignite: the next skill that costs an action).
func _free_source(unit: UnitState, skill: SkillDef) -> StatusInstance:
	if skill.cost == Enums.Cost.FREE:
		return null
	var echo := _echo_for(unit, skill)
	if echo != null:
		return echo
	if skill.slot == Enums.Slot.BASIC and skill.has_tag(&"attack"):
		var basic := unit.find_status_tag(&"free_basic")
		if basic != null:
			return basic
	return unit.find_status_tag(&"ignite")


## A Burnout replay of [param skill] waiting on [param unit] (free, and it
## ignores the skill's recharge).
func _echo_for(unit: UnitState, skill: SkillDef) -> StatusInstance:
	for inst in unit.statuses:
		if inst.def.has_tag(&"echo") and inst.data.get("skill", &"") == skill.id:
			return inst
	return null


## Every rule of can_use except action points (the AI plans a move first).
func can_use_ignoring_points(caster: UnitState, skill: SkillDef) -> bool:
	if not caster.is_alive() or not caster.skills().has(skill):
		return false
	if caster.cooldown_left(skill) > 0 and _echo_for(caster, skill) == null:
		return false
	if skill.condition != null and not skill.condition.allows(caster, self):
		return false
	if skill.requires_status != &"" and not caster.has_status(skill.requires_status):
		return false
	if skill.uses_per_battle > 0 and caster.uses.get(skill.id, 0) >= skill.uses_per_battle:
		return false
	if skill.slot == Enums.Slot.RECOVERY and recoveries_left(caster.team) <= 0:
		return false
	return true


func recoveries_left(team: Enums.Team) -> int:
	return RECOVERIES_PER_BATTLE - recoveries_used.get(team, 0)


## True if [param skill] has at least one legal first pick right now.
func has_targets(caster: UnitState, skill: SkillDef) -> bool:
	return Targeting.has_any(board, caster, skill)


## Uses [param skill] with one picked cell per targeting step (or the path's
## squares, for path skills). [param cards] are readied from the caster's
## hand or the shared row: the skill's draws use them first (see
## Soulstream.draw_for), and any it doesn't use go back. Returns false and
## changes nothing if anything is illegal.
func request_skill(caster: UnitState, skill: SkillDef, picks: Array[Vector2i],
		cards: Array[Card] = []) -> bool:
	if not can_use(caster, skill):
		return false
	if not Targeting.are_valid_picks(board, caster, skill, picks):
		return false
	var stream := soulstream(caster.team)
	if not stream.can_ready(caster, cards):
		return false

	if not cards.is_empty():
		stream.ready_cards(caster, cards)
		_emit(GameEvent.cards_changed(caster.team))
	var free := _free_source(caster, skill)
	var ignited := free != null and free.def.has_tag(&"ignite")
	var copied := free != null and free.def.has_tag(&"echo")
	if free != null:
		await remove_status(free)
	else:
		caster.actions.pay(skill.cost)
	if not copied:
		await _start_cooldown(caster, skill)
		caster.uses[skill.id] = caster.uses.get(skill.id, 0) + 1
		if skill.slot == Enums.Slot.RECOVERY:
			recoveries_used[caster.team] = recoveries_used.get(caster.team, 0) + 1

	# Statuses on the caster may change its targets (Tactical Distortion).
	for inst: StatusInstance in caster.statuses.duplicate():
		if inst.def.behavior != null and caster.statuses.has(inst):
			var changed := await inst.def.behavior.before_skill_targets(inst, skill, picks, self)
			if Targeting.are_valid_picks(board, caster, skill, changed):
				picks = changed

	_emit(GameEvent.skill_used(caster, skill, picks))
	_emit(GameEvent.actions_changed(caster))

	var ctx := ActionContext.new(caster, skill, picks, board, self)
	ctx.ignited = ignited
	ctx.copied = copied
	_uses_so_far += 1
	action_number = _uses_so_far
	action_is_copy = copied
	for effect in skill.effects:
		await effect.apply(ctx)
	if skill.has_tag(&"attack"):
		caster.turn_attacks += 1
	# After the effects, so Blade Fury can see the move right before it.
	caster.last_action_was_move = false

	if caster.is_alive():
		for inst: StatusInstance in caster.statuses.duplicate():
			if inst.def.behavior != null and caster.statuses.has(inst):
				await inst.def.behavior.after_skill(inst, ctx, self)

	# Shadow copies (follow-ups) may still use readied cards.
	await _drain_followups()
	action_number = 0
	action_is_copy = false
	if stream.release() > 0:
		_emit(GameEvent.cards_changed(caster.team))
	await _finish_action()
	return true


func _start_cooldown(caster: UnitState, skill: SkillDef) -> void:
	if skill.cooldown <= 0:
		return
	if skill.is_standard():
		# Adrenal Surge: the next standard skill isn't exhausted.
		var spared := caster.find_status_tag(&"no_cooldown_next")
		if spared != null:
			await remove_status(spared)
			announce(caster, "Not exhausted", Color(1.0, 0.85, 0.4))
			return
	# Ticks down at the start of each of the caster's turns: cooldown 2 used
	# in round 1 is ready again in round 3.
	caster.cooldowns[skill.id] = skill.cooldown


## Recharge: one turn off the skill's cooldown.
func recharge_skill(unit: UnitState, skill: SkillDef, turns: int = 1) -> void:
	if unit.cooldown_left(skill) <= 0:
		return
	unit.cooldowns[skill.id] = maxi(unit.cooldown_left(skill) - turns, 0)
	_emit(GameEvent.actions_changed(unit))


## Refresh: the skill is ready again at once.
func refresh_skill(unit: UnitState, skill: SkillDef) -> void:
	unit.cooldowns.erase(skill.id)
	_emit(GameEvent.actions_changed(unit))


## An extra action point this turn (Adrenal Surge, Bloodrage).
func gain_action(unit: UnitState, cost: Enums.Cost) -> void:
	match cost:
		Enums.Cost.SKILL:
			unit.actions.skill += 1
		Enums.Cost.MOVE:
			unit.actions.move += 1
	_emit(GameEvent.actions_changed(unit))

#endregion

#region Damage and healing

## One strike from [param attacker] on [param target]. Effects call this.
## Draws the cards, applies Power, Armor and dodges, lets the target's
## statuses change or cancel it (Chimeric Cloak), deals the damage, then lets
## the attacker's statuses react (Bound in Blood).
func strike(attacker: UnitState, target: UnitState, spec: StrikeSpec) -> Hit:
	var hit := Hit.new(attacker, target, spec)
	if not target.is_alive():
		hit.cancelled = true
		return hit
	hit.cards = _stream_of(attacker, target).draw_for(spec.tiers)
	_unveiled(attacker, hit.cards)
	if attacker != null:
		hit.power = spec.power + attacker.get_stat(&"power") + attacker.get_stat(&"strike_power")
	else:
		hit.power = spec.power
	hit.armor = target.get_stat(&"armor")
	if attacker != null and attacker.is_foe(target):
		var blind := attacker.find_status_tag(&"blind")
		if blind != null:
			hit.dodge()
			await remove_status(blind)
			announce(attacker, "Blinded", Color(0.75, 0.75, 0.85))
		var dodges_before := target.dodges_used
		if not hit.grazed and _try_dodge(attacker, target):
			hit.dodge()
			hit.dodges_spent = target.dodges_used - dodges_before
			announce(target, "Graze" if hit.grazed else "Dodge", Color(0.7, 0.9, 1.0))
	hit.compute()

	for inst: StatusInstance in target.statuses.duplicate():
		if inst.def.behavior != null and target.statuses.has(inst):
			await inst.def.behavior.before_damage_taken(inst, hit, self)
		if hit.cancelled:
			break
	if hit.cancelled or not target.is_alive():
		# A strike that never landed doesn't use up the target's dodges.
		target.dodges_used -= hit.dodges_spent
		return hit

	_emit(GameEvent.strike(attacker, target, hit))
	hit.dealt = lose_health(target, hit.amount, spec.skill)
	hit.killed = not target.is_alive()

	if attacker != null:
		attacker.turn_damage += hit.dealt
		attacker.turn_strikes[target.id] = attacker.strikes_on(target) + 1

	if target.is_alive():
		if attacker != null and attacker.is_foe(target):
			for skill in target.skills():
				if skill.recharge_when_struck:
					recharge_skill(target, skill)
		for inst: StatusInstance in target.statuses.duplicate():
			if inst.def.behavior != null and target.statuses.has(inst):
				await inst.def.behavior.after_damage_taken(inst, hit, self)

	if attacker != null and attacker.is_alive():
		for inst: StatusInstance in attacker.statuses.duplicate():
			if inst.def.behavior != null and attacker.statuses.has(inst):
				await inst.def.behavior.after_damage_dealt(inst, hit, self)
	return hit


## Spends the target's dodges if it has enough: one, plus one per point of
## the attacker's Accuracy.
func _try_dodge(attacker: UnitState, target: UnitState) -> bool:
	var needed := 1 + attacker.get_stat(&"accuracy")
	if target.dodges_left() < needed:
		return false
	target.dodges_used += needed
	return true


## Health loss: no strike, no Armor, no reactions (Vampiric Pact, Violent
## Transfusion, drains). Returns the HP actually lost.
func lose_health(target: UnitState, amount: int, skill: SkillDef = null) -> int:
	if not target.is_alive() or amount <= 0:
		return 0
	var dealt := mini(amount, target.hp)
	target.hp -= dealt
	_emit(GameEvent.damaged(target, amount, target.hp, skill))
	if not target.is_alive():
		_kill(target)
	return dealt


## Returns the HP actually restored (capped at max HP). [param healer]'s
## statuses hear about it (after_heal_given).
func heal(target: UnitState, amount: int, healer: UnitState = null) -> int:
	if not target.is_alive() or amount <= 0:
		return 0
	var healed := mini(amount, target.get_stat(&"max_hp") - target.hp)
	if healed <= 0:
		return 0
	target.hp += healed
	_emit(GameEvent.healed(target, healed, target.hp))
	if healer != null:
		for inst: StatusInstance in healer.statuses.duplicate():
			if inst.def.behavior != null and healer.statuses.has(inst):
				inst.def.behavior.after_heal_given(inst, target, healed, self)
	return healed


## Heals for Soulstream cards. The healer's Power raises the cards.
func heal_cards(healer: UnitState, target: UnitState, tiers: Array[Enums.Tier],
		bonus: int = 0) -> int:
	return heal(target, card_value(healer, tiers, bonus), healer)


## The value of a set of cards drawn now from [param user]'s Soulstream,
## plus its Power unless [param with_power] is false (Violent Transfusion).
func card_value(user: UnitState, tiers: Array[Enums.Tier], bonus: int = 0,
		with_power: bool = true) -> int:
	var total := bonus
	var cards := _stream_of(user, null).draw_for(tiers)
	_unveiled(user, cards)
	for card in cards:
		total += card.value
	if user != null and with_power and not tiers.is_empty():
		total += user.get_stat(&"power")
	return total


## Lets [param user]'s statuses react to the cards it just unveiled.
func _unveiled(user: UnitState, cards: Array[Card]) -> void:
	if user == null or cards.is_empty():
		return
	for inst: StatusInstance in user.statuses.duplicate():
		if inst.def.behavior != null and user.statuses.has(inst):
			inst.def.behavior.on_cards_unveiled(inst, cards, self)


## The Soulstream [param team] draws from.
func soulstream(team: Enums.Team) -> Soulstream:
	return soulstreams[team]


## Real shuffled decks for both sides (battles); tests keep the medians.
func use_decks(seed_value: int) -> void:
	soulstream(Enums.Team.PLAYER).use_decks(seed_value)
	soulstream(Enums.Team.ENEMY).use_decks(seed_value + 1)


## Tells the HUD that [param team]'s hands, row or Heat changed.
func cards_changed(team: Enums.Team) -> void:
	_emit(GameEvent.cards_changed(team))


## Hand income: one card for [param unit] if its hand has room.
func deal_card(unit: UnitState) -> void:
	if unit.is_alive() and soulstream(unit.team).deal_to(unit) != null:
		_emit(GameEvent.cards_changed(unit.team))


## Row income: one card into [param team]'s shared row if it has room.
func refill_row(team: Enums.Team) -> void:
	if soulstream(team).refill_row() != null:
		_emit(GameEvent.cards_changed(team))


## [param unit] takes [param card] from its side's shared row into its hand
## (Well of Souls). The hand limit only stops income, not this.
func claim_row_card(unit: UnitState, card: Card) -> bool:
	var stream := soulstream(unit.team)
	if not unit.is_alive() or not stream.row.has(card):
		return false
	stream.row.erase(card)
	unit.hand.append(card)
	_emit(GameEvent.cards_changed(unit.team))
	return true


## A strike with no attacker (none yet) draws from the side opposing its target.
func _stream_of(user: UnitState, target: UnitState) -> Soulstream:
	if user != null:
		return soulstream(user.team)
	if target != null and target.team == Enums.Team.PLAYER:
		return soulstream(Enums.Team.ENEMY)
	return soulstream(Enums.Team.PLAYER)


func _kill(unit: UnitState) -> void:
	var cell := unit.cell
	for inst: StatusInstance in unit.statuses.duplicate():
		if inst.def.behavior != null:
			inst.def.behavior.on_owner_died(inst, cell, self)
	board.remove_unit(unit)
	unit.statuses.clear()
	if not unit.hand.is_empty():
		var stream := soulstream(unit.team)
		for card in unit.hand:
			if stream.deck(card.tier) != null:
				stream.deck(card.tier).discard(card)
		unit.hand.clear()
		_emit(GameEvent.cards_changed(unit.team))
	if not unit.shadows.is_empty():
		unit.shadows.clear()
		unit.shadow_made_in.clear()
		_emit(GameEvent.shadows_changed(unit))
	_emit(GameEvent.died(unit))
	# Linked statuses end with their link: a dead Bloodthane's Provoke leaves
	# the foe too.
	for other in board.units():
		for inst: StatusInstance in other.statuses.duplicate():
			if inst.link == unit:
				remove_status(inst)

#endregion

#region Movement

## Shift along [param path] (each square next to the last). Passes through
## any unit; the last square must be empty. A held unit doesn't move.
func shift_unit(unit: UnitState, path: Array[Vector2i]) -> void:
	if path.is_empty() or not unit.is_alive() or not board.can_stand(unit, path[-1]):
		return
	if Pathing.is_held(board, unit):
		announce(unit, "Held", Color(0.8, 0.7, 0.6))
		return
	var from := unit.cell
	board.move_unit(unit, path[-1])
	_emit(GameEvent.unit_moved(unit, path))
	await _after_moved(unit, Enums.MoveKind.SHIFT, from, path)


## Moves [param unit] square by square along [param path] (scripted
## movement: a boss's walk, a minion's step, a random push). Stops at the
## first square it can't stand on.
func move_along(unit: UnitState, path: Array[Vector2i], kind: Enums.MoveKind) -> void:
	var walked: Array[Vector2i] = []
	for cell in path:
		if not board.can_stand(unit, cell):
			break
		walked.append(cell)
	if walked.is_empty() or not unit.is_alive():
		return
	var from := unit.cell
	board.move_unit(unit, walked[-1])
	_emit(GameEvent.unit_moved(unit, walked))
	await _after_moved(unit, kind, from, walked)


## Instantly to [param to], which must be empty.
func teleport_unit(unit: UnitState, to: Vector2i) -> void:
	if to == unit.cell or not unit.is_alive() or not board.can_stand(unit, to):
		return
	var from := unit.cell
	board.move_unit(unit, to)
	_emit(GameEvent.teleported(unit, to))
	var path: Array[Vector2i] = [to]
	await _after_moved(unit, Enums.MoveKind.TELEPORT, from, path)


## Forced movement: up to [param squares] squares toward (or away from)
## [param reference], one square at a time, stopping at anything in the way.
## Returns the squares actually moved.
func force_unit(unit: UnitState, reference: Vector2i, squares: int, toward: bool) -> int:
	return (await force_unit_path(unit, reference, squares, toward)).size()


## force_unit, returning the squares the unit was forced through, in order.
func force_unit_path(unit: UnitState, reference: Vector2i, squares: int,
		toward: bool) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not unit.is_alive():
		return path
	if squares > 0:
		squares = maxi(1, squares - unit.def.sturdy)
	var at := unit.cell
	var last_dir := Vector2i.ZERO
	for i in squares:
		var best := Vector2i(-1, -1)
		var best_score := -INF
		var here := BoardState.distance(at, reference)
		for dir in BoardState.DIRECTIONS:
			var next := at + dir
			if not board.can_stand(unit, next):
				continue
			var d := BoardState.distance(next, reference)
			var gain := here - d if toward else d - here
			if gain <= 0:
				continue
			# Prefer keeping a straight line, then the longer axis.
			var score := float(gain) + (0.5 if dir == last_dir else 0.0)
			var delta := reference - at
			if absi(delta.x) >= absi(delta.y) and dir.y == 0:
				score += 0.25
			elif absi(delta.y) > absi(delta.x) and dir.x == 0:
				score += 0.25
			if score > best_score:
				best_score = score
				best = next
		if best == Vector2i(-1, -1):
			break
		last_dir = best - at
		at = best
		path.append(at)
	if path.is_empty():
		return path
	var from := unit.cell
	board.move_unit(unit, path[-1])
	_emit(GameEvent.unit_moved(unit, path))
	await _after_moved(unit, Enums.MoveKind.FORCED, from, path)
	return path


func _after_moved(unit: UnitState, kind: Enums.MoveKind, from: Vector2i,
		path: Array[Vector2i]) -> void:
	for inst: StatusInstance in unit.statuses.duplicate():
		if not unit.statuses.has(inst):
			continue
		if kind == Enums.MoveKind.WALK and inst.def.has_tag(&"end_on_move"):
			await remove_status(inst)
		elif inst.def.behavior != null:
			await inst.def.behavior.on_moved(inst, kind, from, path, self)

#endregion

#region Summons and marks

## Puts a new unit of [param def] on [param cell] for [param team] (a boss's
## summon). Its passives are applied. Returns null if it can't stand there.
func summon(def: UnitDef, team: Enums.Team, cell: Vector2i) -> UnitState:
	var unit := UnitState.new(def, team)
	if not board.can_stand(unit, cell):
		return null
	board.place_unit(unit, cell)
	_emit(GameEvent.unit_spawned(unit))
	for passive in def.passives:
		await apply_status(unit, passive, unit)
	return unit


## The open square nearest [param from] (by steps over open ground first,
## then by straight distance) where [param unit] could stand, avoiding
## [param avoid]. (-1, -1) if there is none.
func nearest_open(unit: UnitState, from: Vector2i, avoid: Array[Vector2i] = []) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 1 << 30
	for y in board.size.y:
		for x in board.size.x:
			var cell := Vector2i(x, y)
			if not board.can_stand(unit, cell):
				continue
			var clash := false
			for c in BoardState.footprint_cells(cell, unit.def.footprint):
				if avoid.has(c):
					clash = true
			if clash:
				continue
			var d := BoardState.distance(cell, from)
			if d < best_d:
				best_d = d
				best = cell
	return best


## Forces [param unit] into the nearest open square, avoiding [param avoid]
## (Trample: units in a Large unit's way are pushed aside).
func displace(unit: UnitState, avoid: Array[Vector2i]) -> void:
	var to := nearest_open(unit, unit.cell, avoid)
	if to == Vector2i(-1, -1) or not unit.is_alive():
		return
	var from := unit.cell
	board.move_unit(unit, to)
	var path: Array[Vector2i] = [to]
	_emit(GameEvent.unit_moved(unit, path))
	await _after_moved(unit, Enums.MoveKind.FORCED, from, path)


func add_mark(id: StringName, cell: Vector2i, icon: Texture2D = null) -> void:
	var cells: Array[Vector2i] = []
	cells.assign(marks.get(id, []))
	if not cells.has(cell):
		cells.append(cell)
	set_marks(id, cells, icon)


func set_marks(id: StringName, cells: Array[Vector2i], icon: Texture2D = null) -> void:
	if icon != null:
		_mark_icons[id] = icon
	marks[id] = cells.duplicate()
	_emit(GameEvent.marks_changed(id, cells, _mark_icons.get(id)))


func marks_of(id: StringName) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign(marks.get(id, []))
	return cells

#endregion

#region Shadows

## Puts one of [param owner]'s Shadows on [param cell]. Past
## [param max_count], the oldest fades. The Shadow remembers the skill use
## being resolved (if any) as the one that made it.
func place_shadow(owner: UnitState, cell: Vector2i, max_count: int = 3) -> void:
	if owner.shadows.has(cell):
		return
	owner.shadows.append(cell)
	_set_source(owner, cell)
	while owner.shadows.size() > max_count:
		owner.shadow_made_in.erase(owner.shadows.pop_front())
	_emit(GameEvent.shadows_changed(owner))


func remove_shadow(owner: UnitState, cell: Vector2i) -> void:
	if owner.shadows.has(cell):
		owner.shadows.erase(cell)
		owner.shadow_made_in.erase(cell)
		_emit(GameEvent.shadows_changed(owner))


## The Shadow keeps the use that made it.
func move_shadow(owner: UnitState, from: Vector2i, to: Vector2i) -> void:
	var i := owner.shadows.find(from)
	if i < 0:
		return
	var made_in: int = owner.shadow_made_in.get(from, 0)
	owner.shadow_made_in.erase(from)
	if owner.shadows.has(to):
		owner.shadows.remove_at(i)  # Already a Shadow there: the two merge.
	else:
		owner.shadows[i] = to
		if made_in != 0:
			owner.shadow_made_in[to] = made_in
	_emit(GameEvent.shadows_changed(owner))


func set_shadows(owner: UnitState, cells: Array[Vector2i]) -> void:
	owner.shadows = cells.duplicate()
	owner.shadow_made_in.clear()
	for cell in cells:
		_set_source(owner, cell)
	_emit(GameEvent.shadows_changed(owner))


func _set_source(owner: UnitState, cell: Vector2i) -> void:
	if action_number != 0:
		owner.shadow_made_in[cell] = action_number
	else:
		owner.shadow_made_in.erase(cell)

#endregion

#region Statuses

## Puts [param def] on [param target], following its stacking rule.
## Returns the instance that now holds it, or null if it was blocked.
func apply_status(target: UnitState, def: StatusDef, source: UnitState = null,
		link: UnitState = null, stacks: int = 1) -> StatusInstance:
	if not target.is_alive():
		return null
	if source != null and source.is_foe(target):
		for inst: StatusInstance in target.statuses.duplicate():
			if inst.def.behavior != null and target.statuses.has(inst):
				if await inst.def.behavior.before_status_received(inst, def, source, self):
					return null
	if def.stacking != Enums.Stacking.INDEPENDENT:
		var existing := target.find_status(def.id)
		if existing != null:
			existing.turns_left = def.duration
			if def.stacking == Enums.Stacking.ADD and existing.stacks < def.max_stacks:
				existing.stacks = mini(existing.stacks + stacks, def.max_stacks)
			_emit(GameEvent.status_changed(existing))
			return existing
	var inst := StatusInstance.new(def, target, source, link)
	inst.stacks = clampi(stacks, 1, maxi(def.max_stacks, 1))
	target.statuses.append(inst)
	_emit(GameEvent.status_applied(inst))
	if def.behavior != null:
		await def.behavior.on_applied(inst, self)
	return inst


func remove_status(inst: StatusInstance) -> void:
	var owner := inst.owner
	if owner == null or not owner.statuses.has(inst):
		return
	owner.statuses.erase(inst)
	_emit(GameEvent.status_removed(inst))
	if inst.def.behavior != null:
		await inst.def.behavior.on_removed(inst, self)


func set_stacks(inst: StatusInstance, stacks: int) -> void:
	inst.stacks = clampi(stacks, 1, maxi(inst.def.max_stacks, 1))
	_emit(GameEvent.status_changed(inst))


## A short message floating over a unit ("Cloaked!", "Pact bound").
func announce(unit: UnitState, text: String, color: Color = Color.WHITE) -> void:
	_emit(GameEvent.floating_text(unit, text, color))

#endregion

#region Turns

## Start of a new round, before the player's phase: "at end of turn" effects
## run (Acute Coagulant), then round-clock statuses count down.
func start_round() -> void:
	for unit in board.units():
		for inst: StatusInstance in unit.statuses.duplicate():
			if not unit.is_alive():
				break
			if inst.def.behavior != null and unit.statuses.has(inst):
				await inst.def.behavior.on_round_start(inst, self)
	for unit in board.units():
		await _tick(unit, Enums.StatusClock.ROUND)
	await _drain_followups()


## Start-of-turn upkeep for one unit: points refresh, cooldowns tick, status
## hooks run, then owner-turn durations count down.
func start_turn(unit: UnitState) -> void:
	# Daze: this turn's cooldown tick doesn't happen, and a stack clears.
	var daze := unit.find_status_tag(&"daze")
	unit.start_turn(daze == null)
	if daze != null:
		announce(unit, "Dazed", Color(0.85, 0.8, 0.6))
		if daze.stacks > 1:
			set_stacks(daze, daze.stacks - 1)
		else:
			await remove_status(daze)
	_emit(GameEvent.actions_changed(unit))
	for inst: StatusInstance in unit.statuses.duplicate():
		if not unit.is_alive():
			break
		if inst.def.behavior != null and unit.statuses.has(inst):
			await inst.def.behavior.on_turn_start(inst, self)
	if unit.is_alive():
		await _tick(unit, Enums.StatusClock.OWNER_TURN)
	await _drain_followups()


func _tick(unit: UnitState, clock: Enums.StatusClock) -> void:
	for inst: StatusInstance in unit.statuses.duplicate():
		if inst.is_permanent() or inst.def.clock != clock or not unit.statuses.has(inst):
			continue
		inst.turns_left -= 1
		if inst.turns_left <= 0:
			await remove_status(inst)


## Announces a new phase. Waits for playback, so the banner shows first.
func announce_phase(team: Enums.Team, round_number: int) -> void:
	_emit(GameEvent.phase_started(team, round_number))
	if events != null:
		await events.wait_idle()


func announce_outcome(outcome: Enums.Outcome) -> void:
	_emit(GameEvent.battle_ended(outcome))
	if events != null:
		await events.wait_idle()

#endregion

#region Follow-ups and decisions

## Runs [param work] (an async Callable) once the current action's effects
## are done, before the action finishes.
func queue_followup(work: Callable) -> void:
	_followups.append(work)


## Asks the owner of a decision. Waits for the screen to catch up first, so
## the player sees the hit that caused the question.
func decide(request: DecisionRequest) -> int:
	var provider := ai_decisions
	if request.team == Enums.Team.PLAYER and player_decisions != null:
		provider = player_decisions
	if events != null and provider != ai_decisions:
		await events.wait_idle()
	var answer: int = await provider.choose(request)
	return answer


func _drain_followups() -> void:
	var count := 0
	while not _followups.is_empty():
		count += 1
		if count > MAX_FOLLOWUPS:
			push_error("Follow-up limit reached; dropping %d queued effects." % _followups.size())
			_followups.clear()
			return
		var work: Callable = _followups.pop_front()
		await work.call()

#endregion


func _emit(event: GameEvent) -> void:
	if events != null:
		events.enqueue(event)


## Ends a step of an encounter script like any other action: follow-ups,
## playback, then action_finished (the battle checks for an outcome).
func finish_scripted_action() -> void:
	await _finish_action()


func _finish_action() -> void:
	await _drain_followups()
	if events != null:
		await events.wait_idle()
	action_finished.emit()
