class_name PathStrikeEffect
extends EffectDef
## Shifts the caster along the clicked path, then strikes each foe it passed
## through (and, if [member include_adjacent], each foe next to the path).
## Bloody Rush, Phantom Dash.

@export var tiers: Array[Enums.Tier] = [Enums.Tier.SILVER]
@export var include_adjacent: bool = false
@export var melee: bool = true
## If at least [member reward_threshold] foes are struck, the caster gets
## [member reward_status] (Bloody Rush: +1 Armor until end of turn).
@export var reward_threshold: int = 0
@export var reward_status: StatusDef
@export var describe_key: String = "damage"


func apply(ctx: ActionContext) -> void:
	var foes := foes_on_path(ctx.board, ctx.caster, ctx.picks)
	await ctx.resolver.shift_unit(ctx.caster, ctx.picks)
	var struck := 0
	for foe in foes:
		if not foe.is_alive() or not ctx.caster.is_alive():
			continue
		var hit := await ctx.resolver.strike(ctx.caster, foe,
				StrikeSpec.cards(tiers, ctx.skill, melee))
		if not hit.cancelled:
			struck += 1
	if reward_status != null and struck >= reward_threshold and ctx.caster.is_alive():
		await ctx.resolver.apply_status(ctx.caster, reward_status, ctx.caster)


## Foes the path passes through (or beside), in the order it reaches them.
func foes_on_path(board: BoardState, caster: UnitState,
		path: Array[Vector2i]) -> Array[UnitState]:
	var foes: Array[UnitState] = []
	for cell in path:
		var cells: Array[Vector2i] = [cell]
		if include_adjacent:
			cells.append_array(board.neighbors(cell))
		for c in cells:
			var unit := board.unit_at(c)
			if unit != null and caster.is_foe(unit) and not foes.has(unit):
				foes.append(unit)
	return foes


func describe_values() -> Dictionary:
	return { describe_key: Soulstream.describe(tiers), "threshold": reward_threshold }


func ai_score(score: AiScore, board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> void:
	for foe in foes_on_path(board, caster, picks):
		score.damage(foe, score.expected_strike(foe, tiers))


func has_ai_value() -> bool:
	return true
