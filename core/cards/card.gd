class_name Card
extends RefCounted
## One Soulstream card: one suit, two suits (a double counts its suit
## twice), or Wild (any one suit, picked when it's used). Held in an
## Incarnate's hand or face up in the shared row; activated for its base
## effects, primed for a skill's boon or Heroic, or flipped by an effect.
## See references/soulstream-spec.md.

## Empty for a Wild.
var suits: Array[Enums.Suit] = []


func _init(p_suits: Array[Enums.Suit] = []) -> void:
	suits = p_suits.duplicate()


static func of(p_suits: Array) -> Card:
	var typed: Array[Enums.Suit] = []
	typed.assign(p_suits)
	return Card.new(typed)


static func wild() -> Card:
	return Card.new()


func is_wild() -> bool:
	return suits.is_empty()


## How many of [param suit] this card counts as (a Wild counts as 1).
func count(suit: Enums.Suit) -> int:
	if is_wild():
		return 1
	return suits.count(suit)


static func suit_name(p_suit: Enums.Suit) -> String:
	return ["Blade", "Orb", "Portal", "Ward"][int(p_suit)]


## "Blade", "Blade + Ward", "Blade x2", "Wild"
func _to_string() -> String:
	if is_wild():
		return "Wild"
	if suits.size() == 2 and suits[0] == suits[1]:
		return "%s x2" % suit_name(suits[0])
	var names: Array[String] = []
	for s in suits:
		names.append(suit_name(s))
	return " + ".join(names)
