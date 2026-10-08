class_name TetherEffect
extends EffectDef
## The caster becomes Tethered to the ally picked in step 0, ending any
## Tether it had (Fates Intertwined).

@export var tether_status: StatusDef
@export var tethered_status: StatusDef


func apply(ctx: ActionContext) -> void:
	var ally := ctx.unit_at_step(0)
	if ally == null:
		return
	var r := ctx.resolver
	for inst: StatusInstance in ctx.caster.statuses.duplicate():
		if inst.def.id == Tethers.TETHER:
			var old := inst.link
			await r.remove_status(inst)
			if old != null:
				for other: StatusInstance in old.statuses.duplicate():
					if other.def.id == Tethers.TETHERED and other.link == ctx.caster:
						await r.remove_status(other)
	await r.apply_status(ctx.caster, tether_status, ctx.caster, ally)
	await r.apply_status(ally, tethered_status, ctx.caster, ctx.caster)
	# Fates Intertwined: a new ally gets this turn's Infusions.
	for inst: StatusInstance in ctx.caster.statuses.duplicate():
		if inst.def.behavior is FatesIntertwinedBehavior:
			await (inst.def.behavior as FatesIntertwinedBehavior).on_tethered(inst, ally, r)


## The AI tethers first thing when it has no living Tether.
func ai_score(score: AiScore, board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> void:
	var ally := picked_unit(board, caster, picks, 0)
	if ally == null or not Tethers.allies_of(caster, board).is_empty():
		return
	score.total += 30.0 - BoardState.distance(caster.cell, ally.cell) * 0.1


func has_ai_value() -> bool:
	return true
