class_name SkillCondition
extends Resource
## An extra rule for when a skill can be used, checked with the others in
## ActionResolver.can_use. Subclasses override allows().


func allows(_caster: UnitState, _r: ActionResolver) -> bool:
	return true
