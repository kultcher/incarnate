class_name AreaStrikeEffect
extends EffectDef
## Strikes each foe in [member area] (the skill's area for its picks),
## nearest first (Cinder Wave).

@export var tiers: Array[Enums.Tier] = [Enums.Tier.SILVER]
@export var area: SkillArea
@export var describe_key: String = "damage"


func apply(ctx: ActionContext) -> void:
	for foe in foes_in_area(ctx.board, ctx.caster, ctx.picks):
		if foe.is_alive() and ctx.caster.is_alive():
			await ctx.resolver.strike(ctx.caster, foe, StrikeSpec.cards(tiers, ctx.skill, false))


func foes_in_area(board: BoardState, caster: UnitState, picks: Array[Vector2i]) -> Array[UnitState]:
	var foes: Array[UnitState] = []
	for cell in area.cells(board, caster, picks):
		var unit := board.unit_at(cell)
		if unit != null and caster.is_foe(unit) and not foes.has(unit):
			foes.append(unit)
	foes.sort_custom(func(a: UnitState, b: UnitState) -> bool:
		return board.distance_to(a, caster.cell) < board.distance_to(b, caster.cell))
	return foes


func describe_values() -> Dictionary:
	var values := { describe_key: Soulstream.describe(tiers) }
	var wave := area as WaveArea
	if wave != null:
		values.merge({ "width": wave.width, "depth": wave.depth })
	return values


func ai_score(score: AiScore, board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> void:
	for foe in foes_in_area(board, caster, picks):
		score.damage(foe, score.expected_strike(foe, tiers))


func card_tiers() -> Array[Enums.Tier]:
	return tiers


func card_tiers_for(board: BoardState, caster: UnitState, picks: Array[Vector2i]) -> Array[Enums.Tier]:
	var out: Array[Enums.Tier] = []
	for i in maxi(foes_in_area(board, caster, picks).size(), 1):
		out.append_array(tiers)
	return out


func has_ai_value() -> bool:
	return true
