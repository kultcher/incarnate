class_name TacticalDistortionBehavior
extends StatusBehavior
## On a foe (Traceless's Tactical Distortion): once this turn, when that foe
## uses a skill, the Traceless's owner may change its target to another
## valid target.


func before_skill_targets(inst: StatusInstance, skill: SkillDef,
		picks: Array[Vector2i], r: ActionResolver) -> Array[Vector2i]:
	var foe := inst.owner
	var source := inst.source
	if source == null or skill.is_path() or skill.targets.is_empty() or picks.is_empty():
		return picks
	var current := r.board.unit_at(picks[0])
	var options: Array[Vector2i] = []
	for cell in Targeting.valid_cells(r.board, foe, skill, 0, []):
		if cell == picks[0]:
			continue
		var trial: Array[Vector2i] = picks.duplicate()
		trial[0] = cell
		# Only targets that keep the rest of the skill's picks legal.
		if Targeting.are_valid_picks(r.board, foe, skill, trial):
			options.append(cell)
	if options.is_empty():
		return picks

	var request := DecisionRequest.new()
	request.team = source.team
	request.title = inst.def.display_name
	request.icon = inst.def.icon
	request.text = "%s is about to use %s on %s. Change its target?" % [
			foe.def.display_name, skill.display_name, _name(current)]
	var best := DecisionRequest.DECLINED
	var best_hp := current.hp if current != null and current.team == source.team else -1
	for i in options.size():
		var unit := r.board.unit_at(options[i])
		request.add_option(_name(unit), "%d HP" % unit.hp if unit != null else "")
		# The AI sends the attack to the sturdiest of its own units.
		if unit != null and unit.team == source.team and unit.hp > best_hp:
			best_hp = unit.hp
			best = i
	request.decline_label = "Leave it"
	request.ai_choice = best
	var answer := await r.decide(request)
	if answer < 0 or answer >= options.size():
		return picks
	var changed: Array[Vector2i] = picks.duplicate()
	changed[0] = options[answer]
	r.announce(foe, "Distorted", Color(0.75, 0.6, 1.0))
	await r.remove_status(inst)
	return changed


static func _name(unit: UnitState) -> String:
	return unit.def.display_name if unit != null else "an empty square"
