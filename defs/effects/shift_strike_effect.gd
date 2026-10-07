class_name ShiftStrikeEffect
extends EffectDef
## Displacer Strike: shift to the square picked in step 1 and strike the foe
## picked in step 0, before the shift if the foe is already in reach, after
## it otherwise. Picks come from ShiftStrikeRule.

@export var tiers: Array[Enums.Tier] = [Enums.Tier.SILVER]
@export var shift_distance: int = 2
@export var describe_key: String = "damage"


func apply(ctx: ActionContext) -> void:
	var foe := ctx.unit_at_step(0)
	var dest := ctx.picks[1]
	var reach := Pathing.reachable(ctx.board, ctx.caster, shift_distance, MoveRules.shift())
	var path := reach.path_to(dest)
	var strike_first := foe != null and BoardState.distance(ctx.caster.cell, foe.cell) == 1
	if strike_first:
		await _strike(ctx, foe)
	if ctx.caster.is_alive():
		await ctx.resolver.shift_unit(ctx.caster, path)
	if not strike_first and foe != null and foe.is_alive() and ctx.caster.is_alive():
		await _strike(ctx, foe)


func _strike(ctx: ActionContext, foe: UnitState) -> void:
	await ctx.resolver.strike(ctx.caster, foe, StrikeSpec.cards(tiers, ctx.skill, true))


func describe_values() -> Dictionary:
	return { describe_key: Soulstream.describe(tiers), "shift": shift_distance }


func ai_score(score: AiScore, board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> void:
	var foe := picked_unit(board, caster, picks, 0)
	if foe != null:
		score.damage(foe, score.expected_strike(foe, tiers))


func has_ai_value() -> bool:
	return true
