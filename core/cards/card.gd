class_name Card
extends RefCounted
## One Soulstream card: a tier (Bronze, Silver, Gold), a suit and a value.
## Used in strikes, heals and health loss, held in an Incarnate's hand, or
## face up in the shared row.

var tier: Enums.Tier
var suit: Enums.Suit
var value: int
## Came from a hand or the shared row rather than a blind draw.
var held: bool = false


func _init(p_tier: Enums.Tier, p_value: int, p_suit: Enums.Suit = Enums.Suit.BLADE) -> void:
	tier = p_tier
	value = p_value
	suit = p_suit


static func suit_name(p_suit: Enums.Suit) -> String:
	return ["Blade", "Orb", "Portal", "Ward"][int(p_suit)]


## "Silver Blade 3"
func _to_string() -> String:
	return "%s %s %d" % [Soulstream.tier_name(tier), suit_name(suit), value]
