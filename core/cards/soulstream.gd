class_name Soulstream
extends RefCounted
## One side's Soulstream: a deck for each tier and, for the Incarnates, the
## shared face-up row. Each side has its own (enemies draw from theirs).
##   Bronze 1-3 (median 2), Silver 2-4 (3), Gold 3-5 (4)
##
## A strike for "(Si)(Si)" draws two cards blind from the Silver deck, unless
## the caster readied cards from its hand or the shared row: those are used
## first, in place of the lowest-tier draws (where a known card gains the
## most). Any card can stand in for any tier.
##
## Income (start of the player phase): each Incarnate draws a Silver card
## into its hand (up to HAND_SIZE), and the row gets a card of a random tier
## once per round (up to ROW_SIZE). Unspent cards carry over.
##
## MEDIAN mode skips the decks and makes every card its tier's median, so
## rules tests get fixed numbers. Battles use DECK mode.

enum Mode { MEDIAN, DECK }

const HAND_SIZE := 2
const ROW_SIZE := 3
## The deck an Incarnate's hand draws from.
const HAND_TIER := Enums.Tier.SILVER

var mode: Mode = Mode.MEDIAN
var rng := RandomNumberGenerator.new()
## The shared face-up row, oldest first. Change it only through the
## resolver, so the HUD hears about it.
var row: Array[Card] = []

var _decks: Array[CardDeck] = []
## MEDIAN mode: suits rotate so held cards still look different.
var _next_suit: int = 0
## Cards readied for the action being resolved, in the order they're used,
## and the hand (or the row) each one goes back to if it isn't.
var _readied: Array[Card] = []
var _readied_from: Array[Array] = []


## Shuffled 60-card decks for each tier. Same seed, same battle.
func use_decks(seed_value: int) -> void:
	mode = Mode.DECK
	rng.seed = seed_value
	_decks.clear()
	for tier: Enums.Tier in Enums.Tier.values():
		_decks.append(CardDeck.standard(tier, rng))


func deck(tier: Enums.Tier) -> CardDeck:
	return _decks[int(tier)] if mode == Mode.DECK else null


## One card, blind. It goes straight to the discards: it's spent.
func draw(tier: Enums.Tier) -> Card:
	if mode == Mode.MEDIAN:
		var card := Card.new(tier, median(tier), _next_suit as Enums.Suit)
		_next_suit = (_next_suit + 1) % Enums.Suit.size()
		return card
	var drawn := deck(tier).draw()
	deck(tier).discard(drawn)
	return drawn


## The cards for one strike, heal or health loss. Readied cards replace the
## lowest-tier draws; the rest are drawn blind. Keeps the order of [param tiers].
func draw_for(tiers: Array[Enums.Tier]) -> Array[Card]:
	var cards: Array[Card] = []
	cards.resize(tiers.size())
	var order: Array[int] = []
	for i in tiers.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		return tiers[a] < tiers[b] or (tiers[a] == tiers[b] and a < b))
	for i in order:
		if _readied.is_empty():
			cards[i] = draw(tiers[i])
			continue
		var card: Card = _readied.pop_front()
		_readied_from.pop_front()
		_spend(card)
		cards[i] = card
	return cards


## Hand income: one card for [param unit], if its hand has room.
func deal_to(unit: UnitState) -> Card:
	if unit.hand.size() >= HAND_SIZE:
		return null
	var card := _take(HAND_TIER)
	unit.hand.append(card)
	return card


## Row income: one card of a random tier, if the row has room.
func refill_row() -> Card:
	if row.size() >= ROW_SIZE:
		return null
	var tier: Enums.Tier = rng.randi_range(0, Enums.Tier.size() - 1) as Enums.Tier
	var card := _take(tier)
	row.append(card)
	return card


## True if every card is in [param unit]'s hand or the row, once each.
func can_ready(unit: UnitState, cards: Array[Card]) -> bool:
	var seen: Array[Card] = []
	for card in cards:
		if card == null or seen.has(card):
			return false
		if not unit.hand.has(card) and not row.has(card):
			return false
		seen.append(card)
	return true


## Takes [param cards] out of the hand and row for the coming action.
## Call can_ready first.
func ready_cards(unit: UnitState, cards: Array[Card]) -> void:
	release()
	for card in cards:
		var from: Array[Card] = unit.hand if unit.hand.has(card) else row
		from.erase(card)
		_readied.append(card)
		_readied_from.append(from)


## Readied cards the action didn't use go back where they came from.
## Returns how many went back.
func release() -> int:
	var count := _readied.size()
	for i in count:
		var from: Array = _readied_from[i]
		from.append(_readied[i])
	_readied.clear()
	_readied_from.clear()
	return count


func readied_count() -> int:
	return _readied.size()


## A card to hold: face up, kept out of the decks until it's spent.
func _take(tier: Enums.Tier) -> Card:
	var card: Card
	if mode == Mode.MEDIAN:
		card = Card.new(tier, median(tier), _next_suit as Enums.Suit)
		_next_suit = (_next_suit + 1) % Enums.Suit.size()
	else:
		card = deck(tier).draw()
	card.held = true
	return card


func _spend(card: Card) -> void:
	if mode == Mode.DECK:
		deck(card.tier).discard(card)
	card.held = true  # Shown as held in the strike's breakdown.


static func low(tier: Enums.Tier) -> int:
	return int(tier) + 1


static func median(tier: Enums.Tier) -> int:
	return int(tier) + 2


static func median_sum(tiers: Array[Enums.Tier]) -> int:
	var total := 0
	for tier in tiers:
		total += median(tier)
	return total


static func tier_name(tier: Enums.Tier) -> String:
	return ["Bronze", "Silver", "Gold"][int(tier)]


## "6 (Silver + Silver)": the median value, then the cards it stands for.
static func describe(tiers: Array[Enums.Tier], bonus: int = 0) -> String:
	if tiers.is_empty():
		return str(bonus)
	var names: Array[String] = []
	for tier in tiers:
		names.append(tier_name(tier))
	var text := "%d (%s" % [median_sum(tiers) + bonus, " + ".join(names)]
	if bonus != 0:
		text += " %+d" % bonus
	return text + ")"
