class_name StrikeSpec
extends RefCounted
## What a strike is made of before it's drawn: its Soulstream cards (tiers),
## any flat bonus, extra Power from the skill itself (Rending Claws), and
## where it comes from.

var tiers: Array[Enums.Tier] = []
## Flat damage on top of the cards (used by tests and flat effects).
var bonus: int = 0
## Power from the skill itself, added to the attacker's Power stat.
var power: int = 0
var melee: bool = true
var skill: SkillDef
## Cell the strike comes from when that isn't the attacker's own cell
## (a Shadow copying an attack). (-1, -1) = the attacker's cell.
var origin := Vector2i(-1, -1)
## A Shadow's copy of an attack: it can't be copied again.
var copy: bool = false


static func cards(p_tiers: Array[Enums.Tier], p_skill: SkillDef = null,
		p_melee: bool = true) -> StrikeSpec:
	var spec := StrikeSpec.new()
	spec.tiers = p_tiers.duplicate()
	spec.skill = p_skill
	spec.melee = p_melee
	return spec


## A strike for a fixed amount, with no cards.
static func flat(amount: int, p_skill: SkillDef = null, p_melee: bool = true) -> StrikeSpec:
	var spec := StrikeSpec.new()
	spec.bonus = amount
	spec.skill = p_skill
	spec.melee = p_melee
	return spec


func has_origin() -> bool:
	return origin != Vector2i(-1, -1)
