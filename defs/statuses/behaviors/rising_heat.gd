class_name RisingHeatBehavior
extends StatusBehavior
## Kindleborne passive (provisional rework, references/soulstream-spec.md).
## Each skill the Kindleborne uses that costs an action adds 1 Heat, up to
## [member max_heat]: Ignited skills, Burnout replays and free skills add
## none. Heat is spent with the free Stoke skill:
##   Ignite     [member ignite_cost] Heat (1 more for each Ignite this turn):
##              the next skill this turn costs no action.
##   Dissipate  [member dissipate_cost] Heat: heal, +1 Evasion.
## Burnout: after an Ignited skill resolves, it may be replayed once for free.

@export var max_heat: int = 5
@export var ignite_cost: int = 2
@export var dissipate_cost: int = 2
## Heat each paid skill adds.
@export var per_skill: int = 1
## Put on the owner by Ignite: the next skill that costs an action is free.
@export var ignite_status: StatusDef
## Put on the owner after an Ignited skill while Burnout lasts.
@export var echo_status: StatusDef
@export var burnout_id: StringName = &"burnout"


func on_turn_start(inst: StatusInstance, _r: ActionResolver) -> void:
	inst.data["ignites"] = 0


## Adds [param amount] Heat to [param unit], up to [member max_heat].
func gain(unit: UnitState, amount: int, r: ActionResolver) -> void:
	var before := unit.heat
	unit.heat = clampi(unit.heat + amount, 0, max_heat)
	if unit.heat != before:
		r.cards_changed(unit.team)


## What the next Ignite costs this turn.
func current_ignite_cost(inst: StatusInstance) -> int:
	return ignite_cost + int(inst.data.get("ignites", 0))


func can_ignite(inst: StatusInstance) -> bool:
	return inst.owner.heat >= current_ignite_cost(inst)


func can_dissipate(inst: StatusInstance) -> bool:
	return inst.owner.heat >= dissipate_cost


## Spends [param amount] Heat. Returns false (spending none) if short.
func spend(unit: UnitState, amount: int, r: ActionResolver) -> bool:
	if unit.heat < amount:
		return false
	unit.heat -= amount
	r.cards_changed(unit.team)
	r.announce(unit, "Heat spent: %d" % amount, Color(1.0, 0.7, 0.35))
	return true


## Ignite: the next skill costs no action. Recharges skills tagged
## recharge_on_ignite (Flickerstep).
func ignite(inst: StatusInstance, r: ActionResolver) -> bool:
	var unit := inst.owner
	if not spend(unit, current_ignite_cost(inst), r):
		return false
	inst.data["ignites"] = int(inst.data.get("ignites", 0)) + 1
	await r.apply_status(unit, ignite_status, unit)
	r.announce(unit, "Ignite", Color(1.0, 0.6, 0.2))
	for skill in unit.skills():
		if skill.has_tag(&"recharge_on_ignite"):
			r.recharge_skill(unit, skill)
	return true


## Paid skills make Heat; after an Ignited skill, Burnout offers a free
## replay of it.
func after_skill(inst: StatusInstance, ctx: ActionContext, r: ActionResolver) -> void:
	if ctx.paid:
		gain(inst.owner, per_skill, r)
	if not ctx.ignited or echo_status == null:
		return
	var burnout := inst.owner.find_status(burnout_id)
	if burnout == null:
		return
	var echo := await r.apply_status(inst.owner, echo_status, inst.owner)
	if echo != null:
		echo.data["skill"] = ctx.skill.id
		r.announce(inst.owner, "Burnout: %s again" % ctx.skill.display_name, Color(1.0, 0.5, 0.2))
	if burnout.stacks > 1:
		r.set_stacks(burnout, burnout.stacks - 1)
	else:
		await r.remove_status(burnout)


func describe_values() -> Dictionary:
	return { "max": max_heat, "ignite": ignite_cost, "dissipate": dissipate_cost }
