class_name PowerBonus
extends Resource
## Extra Power a strike gets from its own skill text, worked out as the
## strike happens. Subclasses override power(). [param r] is null when the
## AI is only estimating.


func power(_caster: UnitState, _target: UnitState, _r: ActionResolver = null) -> int:
	return 0


func describe_values() -> Dictionary:
	return {}
