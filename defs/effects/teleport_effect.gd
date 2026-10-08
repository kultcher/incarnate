class_name TeleportEffect
extends EffectDef
## The unit picked in [member unit_step] teleports to the square picked in
## [member dest_step] (Essence Shift).

@export var unit_step: int = 0
@export var dest_step: int = 1


func apply(ctx: ActionContext) -> void:
	var unit := ctx.unit_at_step(unit_step)
	if unit != null and dest_step < ctx.picks.size():
		await ctx.resolver.teleport_unit(unit, ctx.picks[dest_step])
