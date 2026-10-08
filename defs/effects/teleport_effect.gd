class_name TeleportEffect
extends EffectDef
## The unit picked in [member unit_step] teleports to the square picked in
## [member dest_step] (Essence Shift). Step -1 is the caster (Flicker).

@export var unit_step: int = 0
@export var dest_step: int = 1
## The caster loses this status afterwards (a one-use granted skill).
@export var consume_status: StringName = &""


func apply(ctx: ActionContext) -> void:
	var unit := ctx.unit_at_step(unit_step)
	if unit != null and dest_step < ctx.picks.size():
		await ctx.resolver.teleport_unit(unit, ctx.picks[dest_step])
	if consume_status != &"":
		var inst := ctx.caster.find_status(consume_status)
		if inst != null:
			await ctx.resolver.remove_status(inst)
