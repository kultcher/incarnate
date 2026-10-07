class_name BloodrageEffect
extends EffectDef
## Bloodrage: the caster gains a skill action, and its strikes get +X Power
## until end of turn, X = the damage it has dealt so far this turn.

@export var status: StatusDef


func apply(ctx: ActionContext) -> void:
	ctx.resolver.gain_action(ctx.caster, Enums.Cost.SKILL)
	var x := ctx.caster.turn_damage
	if x > 0:
		await ctx.resolver.apply_status(ctx.caster, status, ctx.caster, null, x)
		ctx.resolver.announce(ctx.caster, "+%d Power" % x, Color(1.0, 0.45, 0.4))
