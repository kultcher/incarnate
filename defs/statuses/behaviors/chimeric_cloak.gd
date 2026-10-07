class_name ChimericCloakBehavior
extends StatusBehavior
## Chimeric Cloak, prepared (Traceless). The next strike or harmful status
## (tagged debuff) from a foe this turn has no effect on the owner. Health
## loss (Vampiric Pact, Verve Magnet) isn't covered yet. Using it is the owner's
## choice (a prepared skill is free and reactive), asked when it would apply.


func before_damage_taken(inst: StatusInstance, hit: Hit, r: ActionResolver) -> void:
	var owner := inst.owner
	if hit.attacker == null or not owner.is_foe(hit.attacker):
		return
	var text := "%s is about to strike %s for %d." % [
			hit.attacker.def.display_name, owner.def.display_name, hit.amount]
	if await _ask(inst, r, text, "Take no damage."):
		hit.cancelled = true
		await _use(inst, r)


func before_status_received(inst: StatusInstance, def: StatusDef, source: UnitState,
		r: ActionResolver) -> bool:
	if not def.has_tag(&"debuff"):
		return false
	var text := "%s is about to inflict %s on %s." % [
			source.def.display_name, def.display_name, inst.owner.def.display_name]
	if await _ask(inst, r, text, "%s has no effect." % def.display_name):
		await _use(inst, r)
		return true
	return false


func _ask(inst: StatusInstance, r: ActionResolver, text: String, result: String) -> bool:
	var request := DecisionRequest.new()
	request.team = inst.owner.team
	request.title = inst.def.display_name
	request.icon = inst.def.icon
	request.text = "%s Use %s?" % [text, inst.def.display_name]
	request.add_option("Use it", result + " The Cloak is used up.", inst.def.icon)
	request.decline_label = "Save it"
	request.ai_choice = 0
	return await r.decide(request) == 0


func _use(inst: StatusInstance, r: ActionResolver) -> void:
	r.announce(inst.owner, "Negated", Color(0.6, 0.75, 1.0))
	await r.remove_status(inst)
