class_name MovedTowardBonus
extends PowerBonus
## Blade Fury: if played right after a move action, +1 Power for every
## [member squares] squares the caster has closed on the target this turn.

@export var squares: int = 2


func power(caster: UnitState, target: UnitState) -> int:
	if not caster.last_action_was_move:
		return 0
	var closed := BoardState.distance(caster.turn_start_cell, target.cell) \
			- BoardState.distance(caster.cell, target.cell)
	return maxi(closed, 0) / squares


func describe_values() -> Dictionary:
	return { "per_squares": squares }
