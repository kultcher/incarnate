class_name FatesIntertwinedBehavior
extends StatusBehavior
## Soulweaver passive (provisional rework, references/soulstream-spec.md).
## At the start of the Soulweaver's turn it flips the top Soulstream card:
## each suit on it activates that suit's Infusion for her and her Tethered
## ally, with no prompt (a Wild asks which). An ally she Tethers later that
## turn gets the same Infusions.

@export var infusions: Array[InfusionDef] = []
## Which Infusion the AI (and autoplay) picks for a Wild.
@export var ai_choice: int = 0


func on_turn_start(inst: StatusInstance, r: ActionResolver) -> void:
	var soulweaver := inst.owner
	var today: Array[InfusionDef] = []
	inst.data["today"] = today
	var card := r.flip_card(soulweaver)
	if card.is_wild():
		var pick := await _pick(inst, r)
		if pick != null:
			today.append(pick)
	else:
		for suit in card.suits:
			var infusion := infusion_for(suit)
			if infusion != null and not today.has(infusion):
				today.append(infusion)
	var given: Array[int] = []
	inst.data["given"] = given
	for unit in Tethers.with_allies(soulweaver, r.board):
		given.append(unit.id)
	for infusion in today:
		r.announce(soulweaver, infusion.display_name, Color(0.6, 1.0, 0.85))
		await infusion.activate(soulweaver, r)


## A newly Tethered ally gets this turn's Infusions (TetherEffect).
func on_tethered(inst: StatusInstance, ally: UnitState, r: ActionResolver) -> void:
	var given: Array = inst.data.get("given", [])
	if given.has(ally.id):
		return
	given.append(ally.id)
	var today: Array = inst.data.get("today", [])
	for infusion: InfusionDef in today:
		await infusion.activate_for(ally, inst.owner, r)


func infusion_for(suit: Enums.Suit) -> InfusionDef:
	for infusion in infusions:
		if infusion.suit == suit:
			return infusion
	return null


func _pick(inst: StatusInstance, r: ActionResolver) -> InfusionDef:
	var request := DecisionRequest.new()
	request.team = inst.owner.team
	request.title = "Fates Intertwined"
	request.icon = inst.def.icon
	request.text = "A Wild card. Which Infusion?"
	for infusion in infusions:
		request.add_option(infusion.display_name, infusion.description, infusion.icon)
	request.ai_choice = ai_choice
	var answer := await r.decide(request)
	if answer < 0 or answer >= infusions.size():
		answer = ai_choice
	return infusions[answer] if not infusions.is_empty() else null
