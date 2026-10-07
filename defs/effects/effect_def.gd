class_name EffectDef
extends Resource
## One thing a skill does. Subclasses override apply(). Effects run in the
## order the skill lists them, each through the resolver, so reactions and
## statuses see every one.


## Changes the battle through [param ctx]. May await.
func apply(_ctx: ActionContext) -> void:
	push_error("%s doesn't implement apply()." % get_script().resource_path)


## Values this effect contributes to the skill's description, e.g.
## {"damage": "6 (Silver + Silver)"} fills "{damage}".
func describe_values() -> Dictionary:
	return {}


## Adds what this effect would achieve to [param score], for the AI.
## Must not change the board. Effects the AI can't judge add nothing.
func ai_score(_score: AiScore, _board: BoardState, _caster: UnitState,
		_picks: Array[Vector2i]) -> void:
	pass


## True if ai_score can report anything. Skills with no such effect are
## skipped by the AI (it doesn't know when to use them yet).
func has_ai_value() -> bool:
	return false


## The unit picked in [param step] (-1 = the caster), for ai_score.
static func picked_unit(board: BoardState, caster: UnitState, picks: Array[Vector2i],
		step: int) -> UnitState:
	if step < 0:
		return caster
	if step >= picks.size():
		return null
	return board.unit_at(picks[step])
