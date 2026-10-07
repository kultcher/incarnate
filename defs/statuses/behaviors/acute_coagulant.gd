class_name AcuteCoagulantBehavior
extends StatusBehavior
## Acute Coagulant's lasting part: heal at the end of each turn (the start of
## the next round), and whenever the owner is struck for
## [member struck_threshold] or more.

@export var tiers: Array[Enums.Tier] = [Enums.Tier.BRONZE]
@export var struck_threshold: int = 2


func on_round_start(inst: StatusInstance, r: ActionResolver) -> void:
	r.heal_cards(inst.owner, inst.owner, tiers)


func after_damage_taken(inst: StatusInstance, hit: Hit, r: ActionResolver) -> void:
	if hit.dealt >= struck_threshold and inst.owner.is_alive():
		r.heal_cards(inst.owner, inst.owner, tiers)


func describe_values() -> Dictionary:
	return { "tick": Soulstream.describe(tiers), "threshold": struck_threshold }
