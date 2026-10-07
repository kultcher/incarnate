class_name PlaceShadowEffect
extends EffectDef
## Puts one of the caster's Shadows on the square picked in step 0.

@export var max_shadows: int = 3


func apply(ctx: ActionContext) -> void:
	ctx.resolver.place_shadow(ctx.caster, ctx.picks[0], max_shadows)
