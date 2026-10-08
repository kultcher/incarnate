class_name SkillArea
extends Resource
## The squares a skill affects, given its picks: used by its effects and
## shown to the player while hovering a pick. Subclasses override cells().


func cells(_board: BoardState, _caster: UnitState, _picks: Array[Vector2i]) -> Array[Vector2i]:
	return []
