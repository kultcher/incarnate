class_name ShadowJumpEffect
extends EffectDef
## Teleports the caster to the Shadow picked in step 0. Shadowstep consumes
## the Shadow; Mirage Shift's swap moves it to the square the caster left.

@export var consume: bool = true


func apply(ctx: ActionContext) -> void:
	var shadow := ctx.picks[0]
	var from := ctx.caster.cell
	if consume:
		ctx.resolver.remove_shadow(ctx.caster, shadow)
	else:
		ctx.resolver.move_shadow(ctx.caster, shadow, from)
	await ctx.resolver.teleport_unit(ctx.caster, shadow)
