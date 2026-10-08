class_name RowSuitBonus
extends PowerBonus
## Soul Echo: +[member per] Power for each [member suit] in the caster's
## shared Soulstream row (a two-suit card counts each suit, a double counts
## twice, a Wild counts for every suit).

@export var suit: Enums.Suit = Enums.Suit.BLADE
@export var per: int = 2


func power(caster: UnitState, _target: UnitState, r: ActionResolver = null) -> int:
	if r == null:
		return 0  # The AI doesn't count it yet.
	var count := 0
	for card in r.soulstream(caster.team).row:
		count += card.count(suit)
	return count * per


func describe_values() -> Dictionary:
	return { "per_suit": per, "suit": Card.suit_name(suit) }
