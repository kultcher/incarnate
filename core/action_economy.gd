class_name ActionEconomy
extends RefCounted
## Action points for one turn: by default one move, one skill and one flex
## point. Flex covers either. A unit's def can change the maxima (monsters
## have no flex point, so they can't attack twice).

var max_move: int = 1
var max_skill: int = 1
var max_flex: int = 1

var move: int
var skill: int
var flex: int


func _init(p_move: int = 1, p_skill: int = 1, p_flex: int = 1) -> void:
	max_move = p_move
	max_skill = p_skill
	max_flex = p_flex
	refresh()


func refresh() -> void:
	move = max_move
	skill = max_skill
	flex = max_flex


func can_pay(cost: Enums.Cost) -> bool:
	match cost:
		Enums.Cost.FREE:
			return true
		Enums.Cost.MOVE:
			return move > 0 or flex > 0
		Enums.Cost.SKILL:
			return skill > 0 or flex > 0
	return false


## Spends the dedicated point first and falls back to flex.
func pay(cost: Enums.Cost) -> void:
	assert(can_pay(cost), "Tried to pay for an action that can't be afforded.")
	match cost:
		Enums.Cost.MOVE:
			if move > 0:
				move -= 1
			else:
				flex -= 1
		Enums.Cost.SKILL:
			if skill > 0:
				skill -= 1
			else:
				flex -= 1


## True if [param second] could still be paid after paying [param first].
func can_pay_both(first: Enums.Cost, second: Enums.Cost) -> bool:
	var copy := ActionEconomy.new(max_move, max_skill, max_flex)
	copy.move = move
	copy.skill = skill
	copy.flex = flex
	if not copy.can_pay(first):
		return false
	copy.pay(first)
	return copy.can_pay(second)


func is_spent() -> bool:
	return move + skill + flex == 0


func spend_all() -> void:
	move = 0
	skill = 0
	flex = 0
