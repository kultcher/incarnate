class_name RechargeIfIgnitedEffect
extends EffectDef
## Stoking Blast: if this use was Ignited, the skill recharges by 1.


func apply(ctx: ActionContext) -> void:
	if ctx.ignited:
		ctx.resolver.recharge_skill(ctx.caster, ctx.skill)
