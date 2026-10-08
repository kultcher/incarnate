class_name Hit
extends RefCounted
## One strike in progress. The resolver draws its cards and applies Power,
## Armor and dodges; then statuses on the target may change [member amount]
## or cancel it (before_damage_taken); statuses on the attacker see the
## result afterwards (after_damage_dealt).
##
## Power raises a card a tier and Armor lowers one. A tier step is exactly
## one point of value, and past Gold or below Bronze each point is +/-1
## damage, so both come out as +/-1 per point. A strike that lands always
## deals at least 1.

var attacker: UnitState
var target: UnitState
var skill: SkillDef
var melee: bool = true
var spec: StrikeSpec
var cards: Array[Card] = []
var bonus: int = 0
var power: int = 0
var armor: int = 0
## The strike's lowest card was cancelled by a dodge (or Blind).
var dodged: bool = false
## A one-card strike was dodged: it deals 1 and keeps its riders.
var grazed: bool = false
## Dodges the target spent on this strike (given back if it's cancelled).
var dodges_spent: int = 0
## Damage it will deal. Statuses may edit this after compute().
var amount: int = 0
var cancelled: bool = false
## Damage that actually landed (capped at the target's HP).
var dealt: int = 0
## True if this strike killed the target.
var killed: bool = false


func _init(p_attacker: UnitState, p_target: UnitState, p_spec: StrikeSpec) -> void:
	attacker = p_attacker
	target = p_target
	spec = p_spec
	skill = p_spec.skill
	melee = p_spec.melee
	bonus = p_spec.bonus


func is_copy() -> bool:
	return spec.copy


## Cancels the lowest card, or grazes a strike with only one card (or none).
func dodge() -> void:
	dodged = true
	if cards.size() >= 2:
		var lowest := 0
		for i in cards.size():
			if cards[i].value < cards[lowest].value:
				lowest = i
		cards.remove_at(lowest)
	else:
		grazed = true


func card_total() -> int:
	var total := 0
	for card in cards:
		total += card.value
	return total


## Works out [member amount] from the cards, bonus, Power and Armor.
func compute() -> void:
	if grazed:
		amount = 1
		return
	amount = maxi(1, card_total() + bonus + power - armor)


## "Gold 4 + Silver 3, +1 Power": for logs and tooltips.
func breakdown() -> String:
	var parts: Array[String] = []
	for card in cards:
		parts.append("%s (held)" % card if card.held else str(card))
	var text := " + ".join(parts)
	if bonus != 0:
		text += " %+d" % bonus
	if power != 0:
		text += ", %+d Power" % power
	if armor != 0:
		text += ", %d Armor" % armor
	if grazed:
		text += " (graze)"
	return text
