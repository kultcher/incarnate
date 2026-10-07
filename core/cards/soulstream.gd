class_name Soulstream
extends RefCounted
## Where card values come from. For the first kit pass every card is worth
## its tier's middle value (MEDIAN); RANDOM draws within the tier's range.
## Held cards, the shared row, suits and Heroics come later and plug in here.
##   Bronze 1-3 (median 2), Silver 2-4 (3), Gold 3-5 (4)

enum Mode { MEDIAN, RANDOM }

var mode: Mode = Mode.MEDIAN
var rng := RandomNumberGenerator.new()


func draw(tier: Enums.Tier) -> Card:
	var value := median(tier)
	if mode == Mode.RANDOM:
		value = rng.randi_range(low(tier), low(tier) + 2)
	return Card.new(tier, value)


func draw_all(tiers: Array[Enums.Tier]) -> Array[Card]:
	var cards: Array[Card] = []
	for tier in tiers:
		cards.append(draw(tier))
	return cards


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


## "6 (Silver + Silver)": the value used for now, then the cards it stands for.
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
