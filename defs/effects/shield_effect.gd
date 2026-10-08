class_name ShieldEffect
extends EffectDef
## Shields the caster and/or the unit picked in a step against damage worth
## Soulstream cards (the caster's Power raises them), drawn for each.
## Strength in Unity also recharges itself if the ally is Tethered.

@export var tiers: Array[Enums.Tier] = [Enums.Tier.GOLD]
@export var shield_status: StatusDef
@export var shield_caster: bool = true
## Also shield the unit picked in this step. -1 = no one else.
@export var target_step: int = 0
@export var recharge_if_tethered: bool = false


func apply(ctx: ActionContext) -> void:
	var r := ctx.resolver
	var units: Array[UnitState] = []
	if shield_caster:
		units.append(ctx.caster)
	var ally := ctx.unit_at_step(target_step) if target_step >= 0 else null
	if ally != null and not units.has(ally):
		units.append(ally)
	for unit in units:
		var amount := r.card_value(ctx.caster, tiers)
		await r.apply_status(unit, shield_status, ctx.caster, null, amount)
	if recharge_if_tethered and ally != null and Tethers.is_tethered(ctx.caster, ally, ctx.board):
		r.recharge_skill(ctx.caster, ctx.skill)


func describe_values() -> Dictionary:
	return { "shield": Soulstream.describe(tiers) }


func card_tiers() -> Array[Enums.Tier]:
	return tiers
