class_name RisingHeatBehavior
extends StatusBehavior
## Kindleborne passive (2014). Every card the Kindleborne's skills unveil
## (blind or readied) is stored as Heat, up to [member max_heat]; past that,
## the lowest go back to the discards. Cards a Burnout replay unveils aren't
## stored. Heat is spent with the free Stoke skill:
##   Ignite     discard Heat worth [member ignite_cost]+ (1 more for each
##              Ignite this turn): the next skill this turn costs no action.
##   Dissipate  discard Heat worth [member dissipate_cost]+: heal, +1 Evasion.
## Discards take the lowest cards first, keeping the best for Wracking Flame.
## Burnout: after an Ignited skill resolves, it may be replayed once for free.

@export var max_heat: int = 5
@export var ignite_cost: int = 5
@export var dissipate_cost: int = 5
## Put on the owner by Ignite: the next skill that costs an action is free.
@export var ignite_status: StatusDef
## Put on the owner after an Ignited skill while Burnout lasts.
@export var echo_status: StatusDef
@export var burnout_id: StringName = &"burnout"


func on_turn_start(inst: StatusInstance, _r: ActionResolver) -> void:
	inst.data["ignites"] = 0


func on_cards_unveiled(inst: StatusInstance, cards: Array[Card], r: ActionResolver) -> void:
	if r.action_is_copy:
		return
	store(inst.owner, cards, r)


## Adds [param cards] to the unit's Heat, keeping the highest [member max_heat].
func store(unit: UnitState, cards: Array[Card], r: ActionResolver) -> void:
	var stream := r.soulstream(unit.team)
	for card in cards:
		if unit.heat.has(card):
			continue
		if stream.deck(card.tier) != null:
			stream.deck(card.tier).discard_pile.erase(card)
		unit.heat.append(card)
	unit.heat.sort_custom(func(a: Card, b: Card) -> bool: return a.value > b.value)
	while unit.heat.size() > max_heat:
		_discard(unit.heat.pop_back(), stream)
	r.cards_changed(unit.team)


## What the next Ignite costs this turn.
func current_ignite_cost(inst: StatusInstance) -> int:
	return ignite_cost + int(inst.data.get("ignites", 0))


static func heat_total(unit: UnitState) -> int:
	var total := 0
	for card in unit.heat:
		total += card.value
	return total


## The lowest Heat cards worth at least [param amount] together, or none if
## the store can't cover it.
static func cheapest(unit: UnitState, amount: int) -> Array[Card]:
	var chosen: Array[Card] = []
	var sorted := unit.heat.duplicate()
	sorted.sort_custom(func(a: Card, b: Card) -> bool: return a.value < b.value)
	var total := 0
	for card: Card in sorted:
		if total >= amount:
			break
		chosen.append(card)
		total += card.value
	if total < amount:
		chosen.clear()
	return chosen


## Discards [param cards] from the unit's Heat. Returns their total value.
func spend(unit: UnitState, cards: Array[Card], r: ActionResolver) -> int:
	var stream := r.soulstream(unit.team)
	var total := 0
	var values: Array[String] = []
	for card in cards:
		if unit.heat.has(card):
			unit.heat.erase(card)
			total += card.value
			values.append(str(card.value))
			_discard(card, stream)
	r.cards_changed(unit.team)
	if not values.is_empty():
		r.announce(unit, "Heat spent: %s" % ", ".join(values), Color(1.0, 0.7, 0.35))
	return total


## Ignite: the next skill costs no action. Recharges skills tagged
## recharge_on_ignite (Flickerstep).
func ignite(inst: StatusInstance, r: ActionResolver) -> bool:
	var unit := inst.owner
	var cards := cheapest(unit, current_ignite_cost(inst))
	if cards.is_empty():
		return false
	spend(unit, cards, r)
	inst.data["ignites"] = int(inst.data.get("ignites", 0)) + 1
	await r.apply_status(unit, ignite_status, unit)
	r.announce(unit, "Ignite", Color(1.0, 0.6, 0.2))
	for skill in unit.skills():
		if skill.has_tag(&"recharge_on_ignite"):
			r.recharge_skill(unit, skill)
	return true


## After an Ignited skill, Burnout offers a free replay of it.
func after_skill(inst: StatusInstance, ctx: ActionContext, r: ActionResolver) -> void:
	if not ctx.ignited or echo_status == null:
		return
	var burnout := inst.owner.find_status(burnout_id)
	if burnout == null:
		return
	var echo := await r.apply_status(inst.owner, echo_status, inst.owner)
	if echo != null:
		echo.data["skill"] = ctx.skill.id
		r.announce(inst.owner, "Burnout: %s again" % ctx.skill.display_name, Color(1.0, 0.5, 0.2))
	if burnout.stacks > 1:
		r.set_stacks(burnout, burnout.stacks - 1)
	else:
		await r.remove_status(burnout)


func _discard(card: Card, stream: Soulstream) -> void:
	if stream.deck(card.tier) != null:
		stream.deck(card.tier).discard(card)


func describe_values() -> Dictionary:
	return { "max": max_heat, "ignite": ignite_cost, "dissipate": dissipate_cost }
