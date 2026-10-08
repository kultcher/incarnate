class_name HeatBonus
extends PowerBonus
## Wracking Flame: +[member per] Power for each Heat the caster has.

@export var per: int = 1


func power(caster: UnitState, _target: UnitState, _r: ActionResolver = null) -> int:
	return caster.heat * per
