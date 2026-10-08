class_name AshAugurEffect
extends EffectDef
## Ash Augur (provisional rework): gain [member heat] Heat.

@export var heat: int = 2
@export var passive_id: StringName = &"rising_heat"


func apply(ctx: ActionContext) -> void:
	var inst := ctx.caster.find_status(passive_id)
	if inst != null:
		(inst.def.behavior as RisingHeatBehavior).gain(ctx.caster, heat, ctx.resolver)
		ctx.resolver.announce(ctx.caster, "+%d Heat" % heat, Color(1.0, 0.7, 0.35))


func describe_values() -> Dictionary:
	return { "heat": heat }
