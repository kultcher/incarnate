class_name IllusiveShadowsBehavior
extends StatusBehavior
## Traceless passive (2014, reworked 2026-10-08).
##   Illusive Shadows   Shifting out of a square leaves a Shadow there (at
##                      most [member max_shadows]; a new one replaces the
##                      oldest). Shadows don't block and can't be targeted.
##   Shadowstrike       When the Traceless uses a skill with shadow_use
##                      (Displacer Strike, Gloom Edge, Phantom Dash), each of
##                      its Shadows inherits it until end of turn, except a
##                      Shadow made by that same use. The player clicks a
##                      Shadow to use an inherited skill from its square
##                      (free; the Shadow then fades, unless Shadowstorm).
##                      See ActionResolver.request_shadow_skill.
##   Probability Armor  +1 Evasion (a dodge per round) per Shadow.
## (Shadowstep, the teleport, is its own free skill.)

@export var max_shadows: int = 3


func on_moved(inst: StatusInstance, kind: Enums.MoveKind, from: Vector2i,
		_path: Array[Vector2i], r: ActionResolver) -> void:
	if kind == Enums.MoveKind.SHIFT:
		r.place_shadow(inst.owner, from, max_shadows)


func stat_bonus(inst: StatusInstance, stat: StringName) -> int:
	if stat == &"evasion":
		return inst.owner.shadows.size()
	return 0


func after_skill(inst: StatusInstance, ctx: ActionContext, r: ActionResolver) -> void:
	if ctx.skill.shadow_use and not inst.owner.shadows.is_empty():
		r.inherit_skill(inst.owner, ctx.skill)


func on_round_start(inst: StatusInstance, r: ActionResolver) -> void:
	r.clear_inherited(inst.owner)


func describe_values() -> Dictionary:
	return { "max": max_shadows }
