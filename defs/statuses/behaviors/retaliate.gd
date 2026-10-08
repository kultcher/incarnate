class_name RetaliateBehavior
extends StatusBehavior
## Ember Shield: whenever a foe strikes the owner (and the strike lands),
## the owner strikes that foe back for [member tiers], once the foe's action
## has played out. A Shadow's copy counts as its owner striking.

@export var tiers: Array[Enums.Tier] = [Enums.Tier.SILVER]


func after_damage_taken(inst: StatusInstance, hit: Hit, r: ActionResolver) -> void:
	var foe := hit.attacker
	if foe == null or not inst.owner.is_foe(foe):
		return
	r.queue_followup(func() -> void:
		var owner := inst.owner
		if owner != null and owner.is_alive() and foe.is_alive():
			await r.strike(owner, foe, StrikeSpec.cards(tiers, null, false)))


func describe_values() -> Dictionary:
	return { "retaliate": Soulstream.describe(tiers) }
