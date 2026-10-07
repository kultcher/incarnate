class_name BoundInBloodBehavior
extends StatusBehavior
## Bloodthane passive (2014): whenever he strikes a foe, he may bind a Pact
## to it. Each Pact can be bound once per turn.
##
## The 2014 trigger is "a Blade card is unveiled on the strike". Until the
## Soulstream has suits, it is stood in by "a foe you've already struck
## this turn" (the 2013 two-strike rule).
##
## If a Pact is remembered on this passive (StatusInstance.choice) and still
## unused this turn, it is bound without asking. Otherwise the player is
## asked once the action's hits have played out. A killing blow binds nothing.

@export var pacts: Array[PactDef] = []
## Strikes on the same foe this turn needed to trigger (placeholder rule).
@export var strikes_needed: int = 2
## Which Pact the AI (and autoplay) binds.
@export var ai_choice: int = 1


func on_turn_start(inst: StatusInstance, _r: ActionResolver) -> void:
	inst.data["bound"] = []


func after_damage_dealt(inst: StatusInstance, hit: Hit, r: ActionResolver) -> void:
	var foe := hit.target
	if hit.dealt <= 0 or hit.killed or not inst.owner.is_foe(foe):
		return
	if inst.owner.strikes_on(foe) < strikes_needed or available(inst).is_empty():
		return
	r.queue_followup(_bind.bind(inst, foe, r))


## Indices of the Pacts not yet bound this turn.
func available(inst: StatusInstance) -> Array[int]:
	var bound: Array = inst.data.get("bound", [])
	var result: Array[int] = []
	for i in pacts.size():
		if not bound.has(i):
			result.append(i)
	return result


func _bind(inst: StatusInstance, foe: UnitState, r: ActionResolver) -> void:
	var bloodthane := inst.owner
	if bloodthane == null or not bloodthane.is_alive() or not foe.is_alive():
		return
	var open := available(inst)
	if open.is_empty():
		return
	var choice := inst.choice
	if not open.has(choice):
		var request := DecisionRequest.new()
		request.team = bloodthane.team
		request.title = "Bound in Blood"
		request.icon = inst.def.icon
		request.text = "%s's blood answers. Bind a Pact to %s?" % [
				bloodthane.def.display_name, foe.def.display_name]
		for i in open:
			request.add_option(pacts[i].display_name, pacts[i].description, pacts[i].icon)
		request.decline_label = "Don't bind"
		request.offer_remember = true
		request.ai_choice = open.find(ai_choice) if open.has(ai_choice) else 0
		var answer := await r.decide(request)
		if answer < 0 or answer >= open.size() or not foe.is_alive():
			return
		choice = open[answer]
		if request.remember:
			inst.choice = choice
	var bound: Array = inst.data.get("bound", [])
	bound.append(choice)
	inst.data["bound"] = bound
	await pacts[choice].bind(bloodthane, foe, r)


func describe_values() -> Dictionary:
	return { "strikes": strikes_needed }
