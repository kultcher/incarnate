class_name Soulstream
extends RefCounted
## One side's Soulstream: its 60-card suit deck and, for the Incarnates, the
## shared face-up row. See references/soulstream-spec.md.
##
## Numbers are flat. Skills still write them in the 2014 tier notation,
## read as fixed values: Bronze 2, Silver 3, Gold 4.
##
## Income (start of the player phase): each Incarnate draws a card into its
## hand (a hand that would hold 3 activates its oldest card first), and the
## row gets a card once per round, up to ROW_SIZE.

const HAND_SIZE := 2
const ROW_SIZE := 3

var rng := RandomNumberGenerator.new()
var deck := CardDeck.standard()
## The shared face-up row, oldest first. Change it only through the
## resolver, so the HUD hears about it.
var row: Array[Card] = []


## A shuffled deck. Same seed, same battle. Without it the deck is in a
## fixed order (rules tests).
func use_decks(seed_value: int) -> void:
	rng.seed = seed_value
	deck = CardDeck.standard(rng)


## The top card, kept out of the discards until it's used.
func take() -> Card:
	return deck.draw()


## The top card, turned face up and discarded (Fates Intertwined).
func flip() -> Card:
	var card := deck.draw()
	deck.discard(card)
	return card


func discard(card: Card) -> void:
	deck.discard(card)


## Row income: one card, if the row has room.
func refill_row() -> Card:
	if row.size() >= ROW_SIZE:
		return null
	var card := take()
	row.append(card)
	return card


## True if [param card] is in [param unit]'s hand or the row.
func can_use(unit: UnitState, card: Card) -> bool:
	return card != null and (unit.hand.has(card) or row.has(card))


## Takes [param card] out of the hand or the row and discards it.
func spend(unit: UnitState, card: Card) -> void:
	if unit.hand.has(card):
		unit.hand.erase(card)
	else:
		row.erase(card)
	deck.discard(card)


## The flat value of one tier.
static func value_of(tier: Enums.Tier) -> int:
	return int(tier) + 2


static func total_of(tiers: Array[Enums.Tier]) -> int:
	var total := 0
	for tier in tiers:
		total += value_of(tier)
	return total


## The value of each part, in order.
static func parts_of(tiers: Array[Enums.Tier]) -> Array[int]:
	var parts: Array[int] = []
	for tier in tiers:
		parts.append(value_of(tier))
	return parts


static func tier_name(tier: Enums.Tier) -> String:
	return ["Bronze", "Silver", "Gold"][int(tier)]


## The number a skill's text shows: its tiers' total plus [param bonus].
static func describe(tiers: Array[Enums.Tier], bonus: int = 0) -> String:
	return str(total_of(tiers) + bonus)
