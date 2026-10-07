class_name Card
extends RefCounted
## One Soulstream card used in a strike, heal or health loss.

var tier: Enums.Tier
var value: int


func _init(p_tier: Enums.Tier, p_value: int) -> void:
	tier = p_tier
	value = p_value


func _to_string() -> String:
	return "%s %d" % [Soulstream.tier_name(tier), value]
