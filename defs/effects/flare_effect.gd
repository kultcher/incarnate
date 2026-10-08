class_name FlareEffect
extends EffectDef
## Spirit Flare: strikes the unit picked in step 0 if it's a foe, heals it
## if it's an ally, for the same cards. Under Anima Nexus the heal reaches
## every ally (each draws its own cards).

@export var tiers: Array[Enums.Tier] = [Enums.Tier.SILVER]


func apply(ctx: ActionContext) -> void:
	var target := ctx.unit_at_step(0)
	if target == null:
		return
	if ctx.caster.is_foe(target):
		await ctx.resolver.strike(ctx.caster, target, StrikeSpec.cards(tiers, ctx.skill, false))
	else:
		for ally in Tethers.fan_out(ctx.caster, target, ctx.board):
			ctx.resolver.heal_cards(ctx.caster, ally, tiers)


func describe_values() -> Dictionary:
	return { "flare": Soulstream.describe(tiers) }


func ai_score(score: AiScore, board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> void:
	var target := picked_unit(board, caster, picks, 0)
	if target == null:
		return
	if caster.is_foe(target):
		score.damage(target, score.expected_strike(target, tiers))
	else:
		score.heal(target, Soulstream.median_sum(tiers) + caster.get_stat(&"power"))


func card_tiers() -> Array[Enums.Tier]:
	return tiers


func has_ai_value() -> bool:
	return true
