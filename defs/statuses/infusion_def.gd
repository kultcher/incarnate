class_name InfusionDef
extends Resource
## One of Fates Intertwined's Infusions: what the Soulweaver and each
## Tethered ally get when it's activated.

@export var display_name: String
## The Soulstream suit that brings it (Fates Intertwined flips a card).
@export var suit: Enums.Suit = Enums.Suit.BLADE
@export var icon: Texture2D
@export_multiline var description: String
## Put on each of them (Potent: a free basic attack; Elusive: a free shift).
@export var status: StatusDef
## Shield each of them against this much damage (Stalwart).
@export var shield: int = 0
@export var shield_status: StatusDef
## Each of them may recharge a skill (Sage).
@export var recharge: bool = false


func activate(soulweaver: UnitState, r: ActionResolver) -> void:
	for unit in Tethers.with_allies(soulweaver, r.board):
		await activate_for(unit, soulweaver, r)


## The Infusion for one unit (a newly Tethered ally gets this turn's).
func activate_for(unit: UnitState, soulweaver: UnitState, r: ActionResolver) -> void:
	if not unit.is_alive():
		return
	if status != null:
		await r.apply_status(unit, status, soulweaver)
	if shield > 0 and shield_status != null:
		await r.apply_status(unit, shield_status, soulweaver, null, shield)
	if recharge:
		await _recharge_one(soulweaver, unit, r)


## The unit's owner picks which recharging skill to recharge by 1.
func _recharge_one(soulweaver: UnitState, unit: UnitState, r: ActionResolver) -> void:
	var waiting: Array[SkillDef] = []
	for skill in unit.skills():
		if unit.cooldown_left(skill) > 0:
			waiting.append(skill)
	if waiting.is_empty():
		return
	var pick := 0
	if waiting.size() > 1:
		var request := DecisionRequest.new()
		request.team = soulweaver.team
		request.title = display_name
		request.icon = icon
		request.text = "Which of %s's skills recharges by 1?" % unit.def.display_name
		for i in waiting.size():
			var left := unit.cooldown_left(waiting[i])
			request.add_option(waiting[i].display_name,
					"Recharging: %d turn%s left." % [left, "" if left == 1 else "s"], waiting[i].icon)
			if left > unit.cooldown_left(waiting[request.ai_choice]):
				request.ai_choice = i
		pick = await r.decide(request)
		if pick < 0 or pick >= waiting.size():
			pick = request.ai_choice
	r.recharge_skill(unit, waiting[pick])
	r.announce(unit, "%s recharged" % waiting[pick].display_name, Color(0.6, 1.0, 0.85))
