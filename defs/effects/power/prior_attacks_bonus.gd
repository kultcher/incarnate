class_name PriorAttacksBonus
extends PowerBonus
## Tinderbolt: +[member per] Power for each attack skill the caster has
## already used this turn.

@export var per: int = 1


func power(caster: UnitState, _target: UnitState, _r: ActionResolver = null) -> int:
	return caster.turn_attacks * per


func describe_values() -> Dictionary:
	return { "per_attack": per }
