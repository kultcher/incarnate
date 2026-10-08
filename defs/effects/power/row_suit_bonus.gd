class_name RowSuitBonus
extends PowerBonus
## Soul Echo: +[member per] Power for each card of [member suit] in the
## caster's shared Soulstream row.

@export var suit: Enums.Suit = Enums.Suit.BLADE
@export var per: int = 2


func power(caster: UnitState, _target: UnitState, r: ActionResolver = null) -> int:
	if r == null:
		return 0  # The AI doesn't count it yet.
	var count := 0
	for card in r.soulstream(caster.team).row:
		if card.suit == suit:
			count += 1
	return count * per


func describe_values() -> Dictionary:
	return { "per_suit": per, "suit": Card.suit_name(suit) }
