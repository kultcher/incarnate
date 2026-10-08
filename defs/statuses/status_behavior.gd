class_name StatusBehavior
extends Resource
## Hooks a status can react to. The resolver calls these on the statuses of
## the units involved in each event; nothing connects signals by hand.
## Every hook may await (to ask the player something, say).
##
## Hooks change the battle only through [param r], the ActionResolver, so
## every change becomes an event the Presenter plays.


## Just added to [member StatusInstance.owner].
func on_applied(_inst: StatusInstance, _r: ActionResolver) -> void:
	pass


## Start of the owner's turn, before owner-turn durations tick down.
func on_turn_start(_inst: StatusInstance, _r: ActionResolver) -> void:
	pass


## Start of a new round (the end of the previous turn), before round
## durations tick down. "At end of turn" effects run here.
func on_round_start(_inst: StatusInstance, _r: ActionResolver) -> void:
	pass


## The owner is about to be struck. Change [member Hit.amount] to modify the
## damage, or set [member Hit.cancelled].
func before_damage_taken(_inst: StatusInstance, _hit: Hit, _r: ActionResolver) -> void:
	pass


## The owner was just struck ([member Hit.dealt] is the damage that landed).
func after_damage_taken(_inst: StatusInstance, _hit: Hit, _r: ActionResolver) -> void:
	pass


## The owner just struck someone ([member Hit.dealt] is the damage that landed).
func after_damage_dealt(_inst: StatusInstance, _hit: Hit, _r: ActionResolver) -> void:
	pass


## [param def] is about to be put on the owner by [param source]. Return
## true to block it (Chimeric Cloak).
func before_status_received(_inst: StatusInstance, _def: StatusDef,
		_source: UnitState, _r: ActionResolver) -> bool:
	return false


## The owner just moved from [param from] along [param path].
func on_moved(_inst: StatusInstance, _kind: Enums.MoveKind, _from: Vector2i,
		_path: Array[Vector2i], _r: ActionResolver) -> void:
	pass


## The owner is about to use [param skill] on [param picks]. Return the picks
## to use instead (Tactical Distortion redirects a foe's attack).
func before_skill_targets(_inst: StatusInstance, _skill: SkillDef,
		picks: Array[Vector2i], _r: ActionResolver) -> Array[Vector2i]:
	return picks


## The owner just used a skill (its effects have run).
func after_skill(_inst: StatusInstance, _ctx: ActionContext, _r: ActionResolver) -> void:
	pass


## The owner just healed [param target] for [param amount]. Must not await
## (Spirit Flare's free replay).
func after_heal_given(_inst: StatusInstance, _target: UnitState, _amount: int,
		_r: ActionResolver) -> void:
	pass


## The owner just died on [param cell] (its statuses are about to be cleared).
## Must not await (Restless leaves a marker).
func on_owner_died(_inst: StatusInstance, _cell: Vector2i, _r: ActionResolver) -> void:
	pass


## Added to the owner's [param stat] (Probability Armor: Evasion per Shadow).
## Must not await.
func stat_bonus(_inst: StatusInstance, _stat: StringName) -> int:
	return 0


## Removed from the owner (expired, consumed, or its link died).
func on_removed(_inst: StatusInstance, _r: ActionResolver) -> void:
	pass


## Extra values for the description, like SkillDef.describe().
func describe_values() -> Dictionary:
	return {}
