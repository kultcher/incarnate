class_name AiScore
extends RefCounted
## Adds up how good one use of a skill would be, for AiPlanner. Each effect
## reports what it would do (EffectDef.ai_score); this keeps track of HP
## already spent within the same skill so overkill isn't counted twice.

## Score bonus for a kill, on top of the damage dealt.
const KILL_BONUS := 6.0
## Small pull toward finishing off wounded targets.
const WOUNDED_BONUS := 0.15
## Pull toward the unit the attacker is Provoked by.
const TAUNT_BONUS := 20.0
## Healing is worth a bit less than the same damage.
const HEAL_FACTOR := 0.8

var attacker: UnitState
var total: float = 0.0
var _hp: Dictionary[int, int] = {}


func _init(p_attacker: UnitState) -> void:
	attacker = p_attacker


## HP [param unit] would have left at this point in the skill.
func hp_of(unit: UnitState) -> int:
	return _hp.get(unit.id, unit.hp)


## Expected damage of a strike: card medians, plus Power, minus Armor.
func expected_strike(target: UnitState, tiers: Array[Enums.Tier], bonus: int = 0,
		power: int = 0) -> int:
	return maxi(1, Soulstream.median_sum(tiers) + bonus + power
			+ attacker.get_stat(&"power") - target.get_stat(&"armor"))


func damage(target: UnitState, amount: int) -> void:
	if target == null or not attacker.is_foe(target):
		return
	var left := hp_of(target)
	if left <= 0:
		return
	total += mini(amount, left)
	if taunted_by(attacker, target):
		total += TAUNT_BONUS
	total += WOUNDED_BONUS * (target.get_stat(&"max_hp") - left)
	left -= amount
	_hp[target.id] = left
	if left <= 0:
		total += KILL_BONUS


## Healing only counts if the unit is missing at least that much HP.
func heal(target: UnitState, amount: int) -> void:
	if target == null or attacker.is_foe(target):
		return
	var missing := target.get_stat(&"max_hp") - hp_of(target)
	if amount > 0 and missing >= amount:
		total += amount * HEAL_FACTOR


## True if [param unit] is Provoked by [param target].
static func taunted_by(unit: UnitState, target: UnitState) -> bool:
	for inst in unit.statuses:
		if inst.def.has_tag(&"taunt") and inst.link == target:
			return true
	return false
