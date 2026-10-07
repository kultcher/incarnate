class_name PerfectDecoyBehavior
extends StatusBehavior
## Perfect Decoy, on each ally of the Traceless who used it. The first time
## this turn a foe's strike would bring one of them below 1 health, the
## strike is prevented and that ally heals [member tiers]. Then every copy
## from the same Traceless ends. (The 4-square teleport isn't in yet.)

@export var tiers: Array[Enums.Tier] = [Enums.Tier.GOLD, Enums.Tier.SILVER]


func before_damage_taken(inst: StatusInstance, hit: Hit, r: ActionResolver) -> void:
	var owner := inst.owner
	if hit.attacker == null or not owner.is_foe(hit.attacker) or hit.amount < owner.hp:
		return
	hit.cancelled = true
	r.announce(owner, "Perfect Decoy", Color(0.75, 0.6, 1.0))
	r.heal_cards(inst.source, owner, tiers)
	var def := inst.def
	var source := inst.source
	for unit in r.board.units():
		for other: StatusInstance in unit.statuses.duplicate():
			if other.def == def and other.source == source:
				await r.remove_status(other)


func describe_values() -> Dictionary:
	return { "heal": Soulstream.describe(tiers) }
