class_name ShieldBehavior
extends StatusBehavior
## A shield: its stacks are points of damage it absorbs from strikes (not
## health loss), then it's gone. More shielding adds to the same shield.


func before_damage_taken(inst: StatusInstance, hit: Hit, r: ActionResolver) -> void:
	if hit.amount <= 0:
		return
	var absorbed := mini(inst.stacks, hit.amount)
	hit.amount -= absorbed
	r.announce(inst.owner, "Shield -%d" % absorbed, Color(0.55, 1.0, 0.8))
	if absorbed >= inst.stacks:
		await r.remove_status(inst)
	else:
		r.set_stacks(inst, inst.stacks - absorbed)
