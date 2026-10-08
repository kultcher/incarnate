class_name ApplyStatusEffect
extends EffectDef
## Puts a status on the caster or on the unit picked in a targeting step.

@export var status: StatusDef
## Which targeting step's unit gets it. -1 = the caster.
@export var target_step: int = -1
## Link the status to the caster (Provoke: the AI is drawn to its link).
@export var link_caster: bool = false
## Stacks to apply (Burnout: 3).
@export var stacks: int = 1


func apply(ctx: ActionContext) -> void:
	var target := ctx.unit_at_step(target_step)
	if target != null:
		await ctx.resolver.apply_status(target, status, ctx.caster,
				ctx.caster if link_caster else null, stacks)


func describe_values() -> Dictionary:
	if status == null or status.behavior == null:
		return {}
	return status.behavior.describe_values()
