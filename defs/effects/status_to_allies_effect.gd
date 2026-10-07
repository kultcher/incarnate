class_name StatusToAlliesEffect
extends EffectDef
## Puts a status on every unit on the caster's side, the caster included
## (Perfect Decoy). Each copy's source is the caster.

@export var status: StatusDef


func apply(ctx: ActionContext) -> void:
	for unit in ctx.board.units():
		if unit.team == ctx.caster.team:
			await ctx.resolver.apply_status(unit, status, ctx.caster)
