class_name CardDeck
extends RefCounted
## The draw and discard piles of one tier. Each suit has 5 cards of the
## tier's low value, 6 of its median and 4 of its high value (Silver: 2, 3
## and 4), so 60 cards per tier. When the draw pile runs out, the discards
## are shuffled back in.

## Copies per suit of the low, median and high value.
const COPIES: Array[int] = [5, 6, 4]

var tier: Enums.Tier
var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []
var _rng: RandomNumberGenerator


static func standard(p_tier: Enums.Tier, rng: RandomNumberGenerator) -> CardDeck:
	var deck := CardDeck.new()
	deck.tier = p_tier
	deck._rng = rng
	for suit: Enums.Suit in Enums.Suit.values():
		for step in COPIES.size():
			for i in COPIES[step]:
				deck.draw_pile.append(Card.new(p_tier, Soulstream.low(p_tier) + step, suit))
	deck.shuffle()
	return deck


## The top card. Reshuffles the discards in first if the pile is empty.
func draw() -> Card:
	if draw_pile.is_empty():
		draw_pile = discard_pile
		discard_pile = []
		shuffle()
	if draw_pile.is_empty():
		# Every card is held somewhere. Can't happen with hands of 2.
		push_error("The %s deck is empty." % Soulstream.tier_name(tier))
		return Card.new(tier, Soulstream.median(tier))
	var card: Card = draw_pile.pop_back()
	card.held = false
	return card


func discard(card: Card) -> void:
	discard_pile.append(card)


## Fisher-Yates with the Soulstream's own RNG, so a seed replays a battle.
func shuffle() -> void:
	for i in range(draw_pile.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = swap
