class_name HeatCondition
extends SkillCondition
## Stoke: usable when the Heat store can pay for Ignite or Dissipate.

@export var passive_id: StringName = &"rising_heat"


func allows(caster: UnitState, _r: ActionResolver) -> bool:
	var inst := caster.find_status(passive_id)
	if inst == null:
		return false
	var heat := inst.def.behavior as RisingHeatBehavior
	var total := RisingHeatBehavior.heat_total(caster)
	return total >= mini(heat.current_ignite_cost(inst), heat.dissipate_cost)
