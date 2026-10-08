class_name GolgothonTraitsBehavior
extends StatusBehavior
## Golgothon's passive.
##   Resolve N   a debuff from a foe applies only on its Nth application;
##               the earlier ones are absorbed (the count then resets).
##   Tally       damage each foe's strikes dealt him this turn, for Grave
##               Smash's target (minions don't count; health loss doesn't).
## (Large and Sturdy are on the UnitDef.)

@export var resolve: int = 2


func on_round_start(inst: StatusInstance, _r: ActionResolver) -> void:
	inst.data["damage"] = {}


func after_damage_taken(inst: StatusInstance, hit: Hit, _r: ActionResolver) -> void:
	if hit.attacker == null or not inst.owner.is_foe(hit.attacker) or hit.dealt <= 0:
		return
	var tally: Dictionary = inst.data.get("damage", {})
	tally[hit.attacker.id] = int(tally.get(hit.attacker.id, 0)) + hit.dealt
	inst.data["damage"] = tally


func before_status_received(inst: StatusInstance, def: StatusDef, _source: UnitState,
		r: ActionResolver) -> bool:
	if not def.has_tag(&"debuff") or resolve <= 1:
		return false
	var counts: Dictionary = inst.data.get("resolve", {})
	var n := int(counts.get(def.id, 0)) + 1
	if n < resolve:
		counts[def.id] = n
		inst.data["resolve"] = counts
		r.announce(inst.owner, "Resolve (%d/%d)" % [n, resolve], Color(0.75, 0.75, 0.85))
		return true
	counts.erase(def.id)
	inst.data["resolve"] = counts
	return false


## Damage each foe has dealt him this turn, by unit id.
static func damage_by(inst: StatusInstance) -> Dictionary:
	return inst.data.get("damage", {})


func describe_values() -> Dictionary:
	return { "resolve": resolve }
