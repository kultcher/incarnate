class_name HeatBonus
extends PowerBonus
## Wracking Flame: Power equal to the highest value among the caster's Heat.


func power(caster: UnitState, _target: UnitState, _r: ActionResolver = null) -> int:
	var best := 0
	for card in caster.heat:
		best = maxi(best, card.value)
	return best
