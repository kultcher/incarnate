class_name StokeEffect
extends EffectDef
## Stoke (Kindleborne): spend Heat on Ignite or Dissipate (Rising Heat).

@export var passive_id: StringName = &"rising_heat"
## Dissipate: heal for these cards and gain [member feint_status].
@export var heal_tiers: Array[Enums.Tier] = [Enums.Tier.SILVER]
@export var feint_status: StatusDef

const IGNITE := 0
const DISSIPATE := 1


func apply(ctx: ActionContext) -> void:
	var unit := ctx.caster
	var inst := unit.find_status(passive_id)
	if inst == null:
		return
	var heat := inst.def.behavior as RisingHeatBehavior
	var r := ctx.resolver
	var options: Array[int] = []
	var request := DecisionRequest.new()
	request.team = unit.team
	request.title = ctx.skill.display_name
	request.icon = ctx.skill.icon
	request.text = "Heat: %d. Spend it how?" % unit.heat
	if heat.can_ignite(inst):
		options.append(IGNITE)
		request.add_option("Ignite (%d Heat)" % heat.current_ignite_cost(inst),
				"Your next skill this turn costs no action.")
	if heat.can_dissipate(inst):
		options.append(DISSIPATE)
		request.add_option("Dissipate (%d Heat)" % heat.dissipate_cost,
				"Heal %s and +1 Evasion this turn." % Soulstream.describe(heal_tiers))
	if options.is_empty():
		return
	request.decline_label = "Cancel"
	var want := ai_choice(unit)
	request.ai_choice = maxi(options.find(want), 0)
	var answer := await r.decide(request)
	if answer < 0 or answer >= options.size():
		return
	if options[answer] == IGNITE:
		await heat.ignite(inst, r)
	elif heat.spend(unit, heat.dissipate_cost, r):
		r.announce(unit, "Dissipate", Color(1.0, 0.75, 0.4))
		r.heal_cards(unit, unit, heal_tiers)
		if feint_status != null:
			await r.apply_status(unit, feint_status, unit)


## Ignite when out of actions with an attack ready; else Dissipate.
static func ai_choice(unit: UnitState) -> int:
	if unit.actions.skill + unit.actions.flex == 0 and not unit.has_status_tag(&"ignite"):
		for skill in unit.skills():
			if skill.has_tag(&"attack") and skill.cost != Enums.Cost.FREE \
					and unit.cooldown_left(skill) == 0:
				return IGNITE
	return DISSIPATE


func ai_score(score: AiScore, _board: BoardState, caster: UnitState,
		_picks: Array[Vector2i]) -> void:
	var inst := caster.find_status(passive_id)
	if inst == null:
		return
	var heat := inst.def.behavior as RisingHeatBehavior
	if ai_choice(caster) == IGNITE:
		if heat.can_ignite(inst):
			score.total += 20.0
	elif caster.get_stat(&"max_hp") - caster.hp >= 4 and heat.can_dissipate(inst):
		score.total += 4.0


func has_ai_value() -> bool:
	return true
