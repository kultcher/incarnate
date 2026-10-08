class_name DamageDealtBonus
extends PowerBonus
## Rending Claws: +1 Power for every [member per] damage the caster's
## strikes have already dealt this turn.

@export var per: int = 2


func power(caster: UnitState, _target: UnitState, _r: ActionResolver = null) -> int:
	return caster.turn_damage / per


func describe_values() -> Dictionary:
	return { "per_damage": per }
