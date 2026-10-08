class_name VerveMagnetEffect
extends EffectDef
## Verve Magnet: the caster and the picked unit are each forced
## [member squares] squares toward or away from each other (the caster's
## owner chooses). Each unit that actually moves heals [member amount] if
## it's an ally, or loses [member amount] health if it's a foe.

@export var squares: int = 2
@export var amount: int = 1


func apply(ctx: ActionContext) -> void:
	var other := ctx.unit_at_step(0)
	if other == null:
		return
	var request := DecisionRequest.new()
	request.team = ctx.caster.team
	request.title = ctx.skill.display_name
	request.icon = ctx.skill.icon
	request.text = "Pull %s and %s together, or push them apart?" % [
			ctx.caster.def.display_name, other.def.display_name]
	request.add_option("Pull together", "Each moves %d toward the other." % squares)
	request.add_option("Push apart", "Each moves %d away from the other." % squares)
	request.ai_choice = 0
	var toward := await ctx.resolver.decide(request) != 1
	var r := ctx.resolver
	var forced: Array[UnitState] = []
	var b := ctx.board
	if await r.force_unit(other, b.nearest_cell(ctx.caster, other.cell), squares, toward) > 0:
		forced.append(other)
	if await r.force_unit(ctx.caster, b.nearest_cell(other, ctx.caster.cell), squares, toward) > 0:
		forced.append(ctx.caster)
	for unit in forced:
		if not unit.is_alive():
			continue
		if ctx.caster.is_foe(unit):
			r.lose_health(unit, amount, ctx.skill, ctx.caster)
		else:
			r.heal(unit, amount, ctx.caster)


func describe_values() -> Dictionary:
	return { "squares": squares, "amount": amount }
