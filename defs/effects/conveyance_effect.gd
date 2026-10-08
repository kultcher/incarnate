class_name ConveyanceEffect
extends EffectDef
## Conveyance: each ally other than the one picked in step 0 (the caster
## included) may lose 1 health. Then the picked ally heals [member tiers]
## for each point lost this way.

@export var tiers: Array[Enums.Tier] = [Enums.Tier.SILVER, Enums.Tier.SILVER]
## The AI only gives health from allies with more than this.
const AI_MIN_HP := 3


func apply(ctx: ActionContext) -> void:
	var chosen := ctx.unit_at_step(0)
	if chosen == null:
		return
	var r := ctx.resolver
	var lost := 0
	for unit in ctx.board.units():
		if unit == chosen or unit.team != ctx.caster.team or unit.hp <= 1:
			continue
		var request := DecisionRequest.new()
		request.team = ctx.caster.team
		request.title = ctx.skill.display_name
		request.icon = ctx.skill.icon
		request.text = "Should %s lose 1 health so %s heals %s more?" % [
				unit.def.display_name, chosen.def.display_name, Soulstream.describe(tiers)]
		request.add_option("Give 1 health", "%s has %d." % [unit.def.display_name, unit.hp])
		request.decline_label = "Keep it"
		request.ai_choice = 0 if unit.hp > AI_MIN_HP else DecisionRequest.DECLINED
		if await r.decide(request) == 0:
			lost += r.lose_health(unit, 1, ctx.skill)
	for i in lost:
		if chosen.is_alive():
			r.heal_cards(ctx.caster, chosen, tiers)


func describe_values() -> Dictionary:
	return { "heal": Soulstream.describe(tiers) }


## A Recovery is scarce: only when the ally is missing a lot.
func ai_score(score: AiScore, board: BoardState, caster: UnitState,
		picks: Array[Vector2i]) -> void:
	var chosen := picked_unit(board, caster, picks, 0)
	if chosen == null:
		return
	var givers := 0
	for unit in board.units():
		if unit != chosen and unit.team == caster.team and unit.hp > AI_MIN_HP:
			givers += 1
	var per := Soulstream.total_of(tiers) + caster.get_stat(&"power")
	var missing := chosen.get_stat(&"max_hp") - score.hp_of(chosen)
	if givers == 0 or missing < per * 2:
		return
	score.heal(chosen, mini(per * givers, missing))


func card_tiers() -> Array[Enums.Tier]:
	return tiers


func has_ai_value() -> bool:
	return true
