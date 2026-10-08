class_name ActionContext
extends RefCounted
## Everything an effect needs while a skill resolves.

var caster: UnitState
var skill: SkillDef
var picks: Array[Vector2i] = []
var board: BoardState
var resolver: ActionResolver
## The skill was made free by Ignite (Kindleborne's Rising Heat).
var ignited: bool = false
## The skill is a free replay of an Ignited skill (Burnout).
var copied: bool = false
## The caster paid an action for it (not free, not made free by a status).
var paid: bool = false
## 0 = the base skill, 1 = its boon, 2 = its Heroic (primed cards paid).
var boon_level: int = 0
## Units standing on each pick when the skill was used. Kept so a pick still
## means the same unit even if something moves during resolution.
var _picked_units: Array[UnitState] = []


func _init(p_caster: UnitState, p_skill: SkillDef, p_picks: Array[Vector2i],
		p_board: BoardState, p_resolver: ActionResolver) -> void:
	caster = p_caster
	skill = p_skill
	picks = p_picks.duplicate()
	board = p_board
	resolver = p_resolver
	for cell in picks:
		_picked_units.append(board.unit_at(cell))


## The unit picked in step [param i], or null if there was none or it has
## died. Step -1 means the caster.
func unit_at_step(i: int) -> UnitState:
	if i < 0:
		return caster
	if i >= _picked_units.size():
		return null
	var unit := _picked_units[i]
	if unit == null or not unit.is_alive():
		return null
	return unit
