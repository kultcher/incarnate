class_name CauterizingBrandBehavior
extends StatusBehavior
## Cauterizing Brand (Kindleborne Recovery). Until end of turn, each time a
## strike damages the owner it loses [member loss_tiers] more health. At end
## of turn (the next round's start) it heals [member heal_tiers]. Cards come
## from whoever applied it.

@export var loss_tiers: Array[Enums.Tier] = [Enums.Tier.SILVER]
@export var heal_tiers: Array[Enums.Tier] = [Enums.Tier.GOLD, Enums.Tier.GOLD, Enums.Tier.GOLD]


func after_damage_taken(inst: StatusInstance, hit: Hit, r: ActionResolver) -> void:
	if hit.dealt > 0 and inst.owner.is_alive():
		r.lose_health(inst.owner, r.card_value(inst.source, loss_tiers, 0, false))


func on_round_start(inst: StatusInstance, r: ActionResolver) -> void:
	var owner := inst.owner
	if owner != null and owner.is_alive():
		r.heal(owner, r.card_value(inst.source, heal_tiers), inst.source)


func describe_values() -> Dictionary:
	return { "loss": Soulstream.describe(loss_tiers), "heal": Soulstream.describe(heal_tiers) }
