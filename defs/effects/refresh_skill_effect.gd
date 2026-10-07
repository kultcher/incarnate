class_name RefreshSkillEffect
extends EffectDef
## The picked unit refreshes one of its skills (ready again at once). Its
## owner picks which; nothing happens if none is recharging.

@export var target_step: int = 0


func apply(ctx: ActionContext) -> void:
	var unit := ctx.unit_at_step(target_step)
	if unit == null:
		return
	var waiting: Array[SkillDef] = []
	for skill in unit.skills():
		if unit.cooldown_left(skill) > 0:
			waiting.append(skill)
	if waiting.is_empty():
		return
	var request := DecisionRequest.new()
	request.team = ctx.caster.team
	request.title = ctx.skill.display_name
	request.icon = ctx.skill.icon
	request.text = "Which of %s's skills should be refreshed?" % unit.def.display_name
	var best := 0
	for i in waiting.size():
		var skill := waiting[i]
		request.add_option(skill.display_name, "Recharging: %d turn%s left." % [
				unit.cooldown_left(skill), "" if unit.cooldown_left(skill) == 1 else "s"],
				skill.icon)
		if unit.cooldown_left(skill) > unit.cooldown_left(waiting[best]):
			best = i
	request.ai_choice = best
	var choice := await ctx.resolver.decide(request)
	if choice >= 0 and choice < waiting.size():
		ctx.resolver.refresh_skill(unit, waiting[choice])
