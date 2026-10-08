class_name DamageEffect
extends EffectDef
## Strikes the unit picked in a targeting step for Soulstream cards.

## The strike's cards, e.g. [Silver, Silver] for "(Si)(Si)".
@export var tiers: Array[Enums.Tier] = [Enums.Tier.SILVER]
## Flat damage on top of the cards.
@export var bonus: int = 0
## Which targeting step's unit is struck (0 = first pick).
@export var target_step: int = 0
## Melee strikes lunge at the target; ranged ones don't.
@export var melee: bool = true
## Extra Power from the skill's own text (Blade Fury, Rending Claws).
@export var power_bonus: PowerBonus
## Key used in the skill description, so a skill with two damage values can
## name them "{damage}" and "{damage2}".
@export var describe_key: String = "damage"


func apply(ctx: ActionContext) -> void:
	var target := ctx.unit_at_step(target_step)
	if target == null:
		return  # Picked unit already died earlier in this action.
	var spec := StrikeSpec.cards(tiers, ctx.skill, melee)
	spec.bonus = bonus
	if power_bonus != null:
		spec.power = power_bonus.power(ctx.caster, target, ctx.resolver)
	await ctx.resolver.strike(ctx.caster, target, spec)


func describe_values() -> Dictionary:
	var values := { describe_key: Soulstream.describe(tiers, bonus) }
	if power_bonus != null:
		values.merge(power_bonus.describe_values())
	return values


func ai_score(score: AiScore, board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> void:
	var target := picked_unit(board, caster, picks, target_step)
	if target == null:
		return
	var power := power_bonus.power(caster, target) if power_bonus != null else 0
	score.damage(target, score.expected_strike(target, tiers, bonus, power))


func card_tiers() -> Array[Enums.Tier]:
	return tiers


func has_ai_value() -> bool:
	return true
