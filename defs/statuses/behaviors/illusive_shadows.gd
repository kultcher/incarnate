class_name IllusiveShadowsBehavior
extends StatusBehavior
## Traceless passive (2014).
##   Illusive Shadows   Shifting out of a square leaves a Shadow there (at
##                      most [member max_shadows]; a new one replaces the
##                      oldest). Shadows don't block and can't be targeted.
##   Shadowstrike       After the Traceless uses an attack, one Shadow may
##                      copy it: it strikes one foe within the skill's
##                      copy_range of the Shadow, then is used up. Under
##                      Shadowstorm, any number of Shadows may copy. A
##                      Shadow can't copy the skill that made it.
##   Probability Armor  +1 Evasion (a dodge per round) per Shadow.
## (Shadowstep, the teleport, is its own free skill.)

@export var max_shadows: int = 3
## While the owner has this status, every Shadow may copy (Shadowstorm).
@export var storm_status: StringName = &"shadowstorm"


func on_moved(inst: StatusInstance, kind: Enums.MoveKind, from: Vector2i,
		_path: Array[Vector2i], r: ActionResolver) -> void:
	if kind == Enums.MoveKind.SHIFT:
		r.place_shadow(inst.owner, from, max_shadows)


func stat_bonus(inst: StatusInstance, stat: StringName) -> int:
	if stat == &"evasion":
		return inst.owner.shadows.size()
	return 0


func after_skill(inst: StatusInstance, ctx: ActionContext, r: ActionResolver) -> void:
	var skill := ctx.skill
	if not skill.has_tag(&"attack") or skill.copy_range <= 0 or inst.owner.shadows.is_empty():
		return
	if copy_choices(r.board, inst.owner, skill).is_empty():
		return
	r.queue_followup(_offer_copies.bind(inst, skill, r))


## Asks which Shadow copies the attack, and at whom, until the player
## declines or (without Shadowstorm) one Shadow has copied.
func _offer_copies(inst: StatusInstance, skill: SkillDef, r: ActionResolver) -> void:
	var owner := inst.owner
	var used: Array[Vector2i] = []
	while owner != null and owner.is_alive():
		var choices := copy_choices(r.board, owner, skill, used)
		if choices.is_empty():
			return
		var request := DecisionRequest.new()
		request.team = owner.team
		request.title = "Shadowstrike"
		request.icon = skill.icon
		request.text = "A Shadow can copy %s, striking for %s. The Shadow is used up." % [
				skill.display_name, Soulstream.describe(skill.copy_tiers)]
		var damage := Soulstream.median_sum(skill.copy_tiers)
		var best := 0
		var best_score := -INF
		for i in choices.size():
			var shadow: Vector2i = choices[i][0]
			var foe: UnitState = choices[i][1]
			var gap := BoardState.distance(shadow, foe.cell)
			request.add_option("Shadow %s → %s" % [_where(owner.cell, shadow), foe.def.display_name],
					"%d square%s from the Shadow, %d HP." % [gap, "" if gap == 1 else "s", foe.hp])
			var score := (100.0 if foe.hp <= damage else 0.0) - foe.hp
			if score > best_score:
				best_score = score
				best = i
		request.decline_label = "No copy"
		request.ai_choice = best
		var answer := await r.decide(request)
		if answer < 0 or answer >= choices.size():
			return
		var shadow_cell: Vector2i = choices[answer][0]
		var target: UnitState = choices[answer][1]
		if not owner.shadows.has(shadow_cell) or not target.is_alive():
			return
		var spec := StrikeSpec.cards(skill.copy_tiers, skill, true)
		spec.origin = shadow_cell
		spec.copy = true
		var hit := await r.strike(owner, target, spec)
		if not hit.cancelled and skill.copy_status != null and target.is_alive():
			await r.apply_status(target, skill.copy_status, owner)
		r.remove_shadow(owner, shadow_cell)
		used.append(shadow_cell)
		if not owner.has_status(storm_status):
			return


## Every [Shadow cell, foe] pair that could copy [param skill] now, Shadow
## by Shadow, nearest foes first.
static func copy_choices(board: BoardState, owner: UnitState, skill: SkillDef,
		used: Array[Vector2i] = []) -> Array:
	var choices: Array = []
	for shadow in owner.shadows:
		if used.has(shadow) or owner.shadow_sources.get(shadow, &"") == skill.id:
			continue
		var foes: Array[UnitState] = []
		for unit in board.units():
			if owner.is_foe(unit) and unit.is_alive() \
					and BoardState.distance(shadow, unit.cell) <= skill.copy_range:
				foes.append(unit)
		foes.sort_custom(func(a: UnitState, b: UnitState) -> bool:
			var da := BoardState.distance(shadow, a.cell)
			var db := BoardState.distance(shadow, b.cell)
			return da < db if da != db else a.id < b.id)
		for unit in foes:
			choices.append([shadow, unit])
	return choices


## "2 up, 1 left": where a Shadow is relative to its owner.
static func _where(from: Vector2i, to: Vector2i) -> String:
	var d := to - from
	var parts: Array[String] = []
	if d.y != 0:
		parts.append("%d %s" % [absi(d.y), "up" if d.y < 0 else "down"])
	if d.x != 0:
		parts.append("%d %s" % [absi(d.x), "left" if d.x < 0 else "right"])
	return "(here)" if parts.is_empty() else "(%s)" % ", ".join(parts)


func describe_values() -> Dictionary:
	return { "max": max_shadows }
