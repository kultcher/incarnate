class_name DreadDiffusionEffect
extends EffectDef
## Dread Diffusion: strike the foe picked in step 0 and force it away from
## the caster. Then strike each other foe next to a square it was forced
## through, and force each of those a square away from it.

@export var tiers: Array[Enums.Tier] = [Enums.Tier.SILVER, Enums.Tier.BRONZE]
@export var force: int = 3
@export var splash_tiers: Array[Enums.Tier] = [Enums.Tier.BRONZE]
@export var splash_force: int = 1


func apply(ctx: ActionContext) -> void:
	var target := ctx.unit_at_step(0)
	if target == null:
		return
	var r := ctx.resolver
	await r.strike(ctx.caster, target, StrikeSpec.cards(tiers, ctx.skill, false))
	if not target.is_alive():
		return
	var path := await r.force_unit_path(target, ctx.caster.cell, force, false)
	var struck: Array[UnitState] = []
	for cell in path:
		for next in ctx.board.neighbors(cell):
			var foe := ctx.board.unit_at(next)
			if foe != null and foe != target and ctx.caster.is_foe(foe) and not struck.has(foe):
				struck.append(foe)
	for foe in struck:
		if not foe.is_alive() or not ctx.caster.is_alive():
			continue
		await r.strike(ctx.caster, foe, StrikeSpec.cards(splash_tiers, ctx.skill, false))
		if foe.is_alive() and target.is_alive():
			await r.force_unit(foe, ctx.board.nearest_cell(target, foe.cell), splash_force, false)


func describe_values() -> Dictionary:
	return { "damage": Soulstream.describe(tiers), "force": force,
			"splash": Soulstream.describe(splash_tiers), "splash_force": splash_force }


## Counts the main strike only (where the target lands is hard to guess).
func ai_score(score: AiScore, board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> void:
	var target := picked_unit(board, caster, picks, 0)
	if target != null:
		score.damage(target, score.expected_strike(target, tiers))


func card_tiers() -> Array[Enums.Tier]:
	return tiers


func has_ai_value() -> bool:
	return true
