class_name ShadowstormEffect
extends EffectDef
## Shadowstorm: the caster's Shadows move to the picked squares (new ones
## appear if there are fewer Shadows than picks), and any number of them can
## copy each attack until end of turn.

@export var status: StatusDef


func apply(ctx: ActionContext) -> void:
	ctx.resolver.set_shadows(ctx.caster, ctx.picks)
	await ctx.resolver.apply_status(ctx.caster, status, ctx.caster)
