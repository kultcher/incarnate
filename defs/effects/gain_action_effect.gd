class_name GainActionEffect
extends EffectDef
## The caster or picked unit gains an extra action point this turn.

@export var cost: Enums.Cost = Enums.Cost.SKILL
## -1 = the caster.
@export var target_step: int = -1


func apply(ctx: ActionContext) -> void:
	var unit := ctx.unit_at_step(target_step)
	if unit != null:
		ctx.resolver.gain_action(unit, cost)
