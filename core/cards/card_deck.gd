class_name CardDeck
extends RefCounted
## A side's 60-card Soulstream deck: 9 of each suit, 4 Wilds, and 2 of each
## two-suit combination including doubles (BB, BW, BO, BP, WW, WO, WP, OO,
## OP, PP). When the draw pile runs out, the discards are shuffled back in.

const BASE_COPIES := 9
const WILDS := 4
const PAIR_COPIES := 2

var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []
var _rng: RandomNumberGenerator


## The full deck. Unshuffled (in a fixed, mixed order) unless
## [param rng] is given, so rules tests know what comes next.
static func standard(rng: RandomNumberGenerator = null) -> CardDeck:
	var deck := CardDeck.new()
	deck._rng = rng
	var suits: Array = Enums.Suit.values()
	for i in BASE_COPIES:
		for suit: Enums.Suit in suits:
			deck.draw_pile.append(Card.of([suit]))
	for i in WILDS:
		deck.draw_pile.append(Card.wild())
	for i in PAIR_COPIES:
		for a in suits.size():
			for b in range(a, suits.size()):
				deck.draw_pile.append(Card.of([suits[a], suits[b]]))
	# Drawn from the back: put the base cards on top, Blade first.
	deck.draw_pile.reverse()
	if rng != null:
		deck.shuffle()
	return deck


func size() -> int:
	return draw_pile.size() + discard_pile.size()


## The top card. Reshuffles the discards in first if the pile is empty.
func draw() -> Card:
	if draw_pile.is_empty():
		draw_pile = discard_pile
		discard_pile = []
		shuffle()
	if draw_pile.is_empty():
		push_error("The Soulstream deck is empty.")
		return Card.wild()
	return draw_pile.pop_back()


func discard(card: Card) -> void:
	discard_pile.append(card)


## Fisher-Yates with the Soulstream's own RNG, so a seed replays a battle.
func shuffle() -> void:
	if _rng == null:
		return
	for i in range(draw_pile.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = swap
