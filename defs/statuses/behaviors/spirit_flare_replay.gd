class_name SpiritFlareReplayBehavior
extends StatusBehavior
## Spirit Flare's second line (Soulweaver): once per turn, when the owner
## slays a foe or heals an ally to full health, its next basic attack this
## turn is a free action ([member ready_status], tagged free_basic).

@export var ready_status: StatusDef


func on_turn_start(inst: StatusInstance, _r: ActionResolver) -> void:
	inst.data["used"] = false


func after_damage_dealt(inst: StatusInstance, hit: Hit, r: ActionResolver) -> void:
	if hit.killed and inst.owner.is_foe(hit.target):
		_grant(inst, r)


func after_heal_given(inst: StatusInstance, target: UnitState, _amount: int,
		r: ActionResolver) -> void:
	if target != inst.owner and not inst.owner.is_foe(target) \
			and target.hp >= target.get_stat(&"max_hp"):
		_grant(inst, r)


func _grant(inst: StatusInstance, r: ActionResolver) -> void:
	if inst.data.get("used", false) or ready_status == null:
		return
	inst.data["used"] = true
	r.queue_followup(func() -> void:
		var owner := inst.owner
		if owner != null and owner.is_alive():
			await r.apply_status(owner, ready_status, owner)
			r.announce(owner, "Spirit Flare ready", Color(0.6, 1.0, 0.85)))
