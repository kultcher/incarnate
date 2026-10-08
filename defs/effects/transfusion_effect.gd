class_name TransfusionEffect
extends EffectDef
## Violent Transfusion: the foe picked in step 0 loses health; the ally
## picked in step 1 heals that much, plus [member kill_bonus] if the foe died.

@export var tiers: Array[Enums.Tier] = [Enums.Tier.GOLD, Enums.Tier.GOLD]
@export var kill_bonus: int = 2


func apply(ctx: ActionContext) -> void:
	var foe := ctx.unit_at_step(0)
	var ally := ctx.unit_at_step(1)
	if foe == null:
		return
	var lost := ctx.resolver.lose_health(foe, ctx.resolver.card_value(ctx.caster, tiers, 0, false),
			ctx.skill, ctx.caster)
	if ally != null and ally.is_alive():
		ctx.resolver.heal(ally, lost + (kill_bonus if not foe.is_alive() else 0), ctx.caster)


func describe_values() -> Dictionary:
	return { "loss": Soulstream.describe(tiers), "kill_bonus": kill_bonus }


func ai_score(score: AiScore, board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> void:
	var foe := picked_unit(board, caster, picks, 0)
	var ally := picked_unit(board, caster, picks, 1)
	if foe == null or ally == null:
		return
	# A Recovery is scarce: only worth it when the ally needs the healing.
	var missing := ally.get_stat(&"max_hp") - score.hp_of(ally)
	if missing < Soulstream.total_of(tiers) / 2:
		return
	var lost := mini(Soulstream.total_of(tiers), score.hp_of(foe))
	score.damage(foe, Soulstream.total_of(tiers))
	score.heal(ally, lost)


func card_tiers() -> Array[Enums.Tier]:
	return tiers


func has_ai_value() -> bool:
	return true
