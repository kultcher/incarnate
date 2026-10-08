class_name ShiftEffect
extends EffectDef
## The caster shifts to the square picked in step 0 (see ShiftRule), then
## loses [member consume_status] if set (a one-use granted skill).

@export var distance: int = 2
@export var consume_status: StringName = &""


func apply(ctx: ActionContext) -> void:
	var reach := Pathing.reachable(ctx.board, ctx.caster, distance, MoveRules.shift())
	await ctx.resolver.shift_unit(ctx.caster, reach.path_to(ctx.picks[0]))
	if consume_status != &"":
		var inst := ctx.caster.find_status(consume_status)
		if inst != null:
			await ctx.resolver.remove_status(inst)


func describe_values() -> Dictionary:
	return { "shift": distance }
