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
			ok = await resolver.request_move(unit, plan.move_to)
		else:
			ok = await resolver.request_skill(unit, plan.skill, plan.picks,
					AiPlanner.choose_cards(resolver, unit, plan.skill, plan.picks))
		if not ok:
			push_warning("AI plan was rejected: %s %s" % [unit, plan])
			break
	_mark(unit, false)


func _mark(unit: UnitState, on: bool) -> void:
	if presenter == null:
		return
	var view := presenter.view_for(unit)
	if view != null:
		view.set_selected(on)
