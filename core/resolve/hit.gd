class_name Hit
extends RefCounted
## One strike in progress. The resolver sets its parts (one flat value per
## tier) and applies Power, Armor and dodges; then statuses on the target may change [member amount]
## or cancel it (before_damage_taken); statuses on the attacker see the
## result afterwards (after_damage_dealt).
##
## Power and Armor are +/-1 damage per point. A strike that lands always
## deals at least 1.

var attacker: UnitState
var target: UnitState
var skill: SkillDef
var melee: bool = true
var spec: StrikeSpec
## The strike's parts: one flat value per tier (Silver = 3).
var parts: Array[int] = []
var bonus: int = 0
var power: int = 0
var armor: int = 0
## The strike's smallest part was cancelled by a dodge (or Blind).
var dodged: bool = false
## A one-part strike was dodged: it deals 1 and keeps its riders.
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


## Cancels the smallest part, or grazes a strike with only one part (or none).
func dodge() -> void:
	dodged = true
	if parts.size() >= 2:
		var lowest := 0
		for i in parts.size():
			if parts[i] < parts[lowest]:
				lowest = i
		parts.remove_at(lowest)
	else:
		grazed = true


func part_total() -> int:
	var total := 0
	for part in parts:
		total += part
	return total


## Works out [member amount] from the parts, bonus, Power and Armor.
func compute() -> void:
	if grazed:
		amount = 1
		return
	amount = maxi(1, part_total() + bonus + power - armor)


## "4 + 3, +1 Power": for logs and tooltips.
func breakdown() -> String:
	var names: Array[String] = []
	for part in parts:
		names.append(str(part))
	var text := " + ".join(names)
	if names.is_empty():
		text = str(bonus)
	elif bonus != 0:
		text += " %+d" % bonus
	if power != 0:
		text += ", %+d Power" % power
	if armor != 0:
		text += ", %d Armor" % armor
	if grazed:
		text += " (graze)"
	return text
