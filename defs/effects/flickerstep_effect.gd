class_name FlickerstepEffect
extends EffectDef
## Flickerstep: the caster may teleport up to [member tiers]' value +
## [member bonus] squares this turn, as a free action (the
## granted Flicker skill reads the range from [member status]'s stacks).

@export var tiers: Array[Enums.Tier] = [Enums.Tier.GOLD]
@export var bonus: int = 2
@export var status: StatusDef


func apply(ctx: ActionContext) -> void:
	var reach := ctx.resolver.card_value(ctx.caster, tiers, bonus, false)
	var inst := await ctx.resolver.apply_status(ctx.caster, status, ctx.caster, null, reach)
	# A second Flickerstep before the first Flicker is used replaces its range.
	if inst != null and inst.stacks != reach:
		ctx.resolver.set_stacks(inst, reach)
	ctx.resolver.announce(ctx.caster, "Flicker %d" % reach, Color(1.0, 0.7, 0.3))


func describe_values() -> Dictionary:
	return { "reach": Soulstream.describe(tiers, bonus) }


func card_tiers() -> Array[Enums.Tier]:
	return tiers
