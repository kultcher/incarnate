class_name PowerBonus
extends Resource
## Extra Power a strike gets from its own skill text, worked out as the
## strike happens. Subclasses override power().


func power(_caster: UnitState, _target: UnitState) -> int:
	return 0


func describe_values() -> Dictionary:
	return {}
