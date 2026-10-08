class_name FatesIntertwinedBehavior
extends StatusBehavior
## Soulweaver passive (2014). Once per turn, when the Soulweaver unveils a
## card (any card one of its skills uses, blind or readied), it may activate
## an Infusion for itself and each Tethered ally. Choosing the Tether is the
## free Tether skill. Declining keeps the Infusion for a later unveil.

@export var infusions: Array[InfusionDef] = []
## Which Infusion the AI (and autoplay) picks.
@export var ai_choice: int = 0


func on_turn_start(inst: StatusInstance, _r: ActionResolver) -> void:
	inst.data["used"] = false


func on_cards_unveiled(inst: StatusInstance, _cards: Array[Card], r: ActionResolver) -> void:
	if inst.data.get("used", false) or inst.data.get("pending", false):
		return
	inst.data["pending"] = true
	r.queue_followup(_offer.bind(inst, r))


func _offer(inst: StatusInstance, r: ActionResolver) -> void:
	inst.data["pending"] = false
	var soulweaver := inst.owner
	if soulweaver == null or not soulweaver.is_alive() or inst.data.get("used", false):
		return
	var allies := Tethers.allies_of(soulweaver, r.board)
	var who := "you"
	if allies.size() == 1:
		who = "you and %s" % allies[0].def.display_name
	elif allies.size() > 1:
		who = "you and every ally"
	var request := DecisionRequest.new()
	request.team = soulweaver.team
	request.title = "Fates Intertwined"
	request.icon = inst.def.icon
	request.text = "A card is unveiled. Activate an Infusion for %s? (Once per turn.)" % who
	for infusion in infusions:
		request.add_option(infusion.display_name, infusion.description, infusion.icon)
	request.decline_label = "Not now"
	request.ai_choice = ai_choice
	var answer := await r.decide(request)
	if answer < 0 or answer >= infusions.size():
		return
	inst.data["used"] = true
	r.announce(soulweaver, infusions[answer].display_name, Color(0.6, 1.0, 0.85))
	await infusions[answer].activate(soulweaver, r)
