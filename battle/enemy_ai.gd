class_name EnemyAI
extends TurnDriver
## Plays a whole side's phase through the resolver, one action at a time,
## using AiPlanner's choices. Used for enemies, and for the player's side
## when autoplay (F9) is on.

## Safety cap so a planner bug can't loop forever.
const MAX_ACTIONS_PER_UNIT := 16

var board: BoardState
var resolver: ActionResolver
## Optional: shown on the acting unit so you can follow the enemy turn.
var presenter: Presenter


func take_turn(team: Enums.Team) -> void:
	# Act in a stable order: nearest-to-the-front first would be smarter;
	# board order (by unit id) keeps runs repeatable for now.
	var units: Array[UnitState] = []
	for unit in board.units():
		if unit.team == team:
			units.append(unit)
	units.sort_custom(func(a: UnitState, b: UnitState) -> bool: return a.id < b.id)
	for unit in units:
		if is_over.call():
			return
		if unit.is_alive():
			await take_unit_turn(unit)


func take_unit_turn(unit: UnitState) -> void:
	_mark(unit, true)
	await _use_cards(unit, Enums.Suit.ORB)
	for i in MAX_ACTIONS_PER_UNIT:
		if is_over.call() or not unit.is_alive():
			break
		# Free first: a Shadow using an inherited skill.
		var shadow_plan := AiPlanner.best_shadow_attack(board, resolver, unit)
		if shadow_plan != null:
			if not await resolver.request_shadow_skill(shadow_plan.shadow, shadow_plan.skill,
					shadow_plan.picks):
				push_warning("AI shadow plan was rejected: %s %s" % [unit, shadow_plan])
				break
			continue
		var plan := AiPlanner.next_action(board, resolver, unit)
		if plan == null:
			break
		var ok: bool
		if plan.is_move():
			await _use_cards(unit, Enums.Suit.PORTAL)
			ok = await resolver.request_move(unit, plan.move_to)
		else:
			if plan.skill.has_tag(&"attack"):
				await _use_cards(unit, Enums.Suit.BLADE)
			ok = await resolver.request_skill(unit, plan.skill, plan.picks)
		if not ok:
			push_warning("AI plan was rejected: %s %s" % [unit, plan])
			break
	# Shield up for the other side's phase.
	await _use_cards(unit, Enums.Suit.WARD)
	_mark(unit, false)


## Activates the cards in [param unit]'s hand that have [param suit] (Wilds
## are kept; a full hand activates them when it draws). Orbs only when a
## skill is recharging.
func _use_cards(unit: UnitState, suit: Enums.Suit) -> void:
	if suit == Enums.Suit.ORB and not _recharging(unit):
		return
	for card: Card in unit.hand.duplicate():
		if unit.is_alive() and not card.is_wild() and card.suits.has(suit):
			await resolver.activate_card(unit, card)


func _recharging(unit: UnitState) -> bool:
	for skill in unit.skills():
		if unit.cooldown_left(skill) > 0:
			return true
	return false


func _mark(unit: UnitState, on: bool) -> void:
	if presenter == null:
		return
	var view := presenter.view_for(unit)
	if view != null:
		view.set_selected(on)
