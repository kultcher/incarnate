class_name HeatCondition
extends SkillCondition
## Stoke: usable when there's enough Heat for Ignite or Dissipate.

@export var passive_id: StringName = &"rising_heat"


func allows(caster: UnitState, _r: ActionResolver) -> bool:
	var inst := caster.find_status(passive_id)
	if inst == null:
		return false
	var heat := inst.def.behavior as RisingHeatBehavior
	return heat.can_ignite(inst) or heat.can_dissipate(inst)
