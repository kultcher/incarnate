class_name ShadowstormEffect
extends EffectDef
## Shadowstorm: the caster's Shadows move to the picked squares (new ones
## appear if there are fewer Shadows than picks), and until end of turn a
## Shadow isn't used up when it uses an inherited skill.

@export var status: StatusDef


func apply(ctx: ActionContext) -> void:
	ctx.resolver.set_shadows(ctx.caster, ctx.picks)
	await ctx.resolver.apply_status(ctx.caster, status, ctx.caster)
