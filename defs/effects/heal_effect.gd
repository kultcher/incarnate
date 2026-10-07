class_name HealEffect
extends EffectDef
## Restores HP to the caster or to the unit picked in a targeting step, for
## Soulstream cards (the caster's Power raises them).

@export var tiers: Array[Enums.Tier] = [Enums.Tier.SILVER]
@export var bonus: int = 0
## Which targeting step's unit is healed. -1 = the caster.
@export var target_step: int = -1
@export var describe_key: String = "heal"


func apply(ctx: ActionContext) -> void:
	var target := ctx.unit_at_step(target_step)
	if target != null:
		ctx.resolver.heal_cards(ctx.caster, target, tiers, bonus)


func describe_values() -> Dictionary:
	return { describe_key: Soulstream.describe(tiers, bonus) }


func ai_score(score: AiScore, board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> void:
	var target := picked_unit(board, caster, picks, target_step)
	var amount := Soulstream.median_sum(tiers) + bonus + caster.get_stat(&"power")
	score.heal(target, amount)


func has_ai_value() -> bool:
	return true
