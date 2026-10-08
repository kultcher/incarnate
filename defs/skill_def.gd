class_name SkillDef
extends Resource
## A skill: who it can target (one TargetStep per click, or a path) and what
## it does (EffectDefs, run in order). Most skills are only data; new code is
## needed only for a genuinely new kind of effect.

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
## Placeholders like {damage} are filled from the effects, so the text can't
## drift from the numbers.
@export_multiline var description: String
@export var slot: Enums.Slot = Enums.Slot.BASIC
## SKILL, MOVE (Maneuver: can be played as a move action) or FREE.
@export var cost: Enums.Cost = Enums.Cost.SKILL
## Recharge: turns before it can be used again. 0 = every turn.
@export var cooldown: int = 0
@export var tags: Array[StringName] = []
@export var targets: Array[TargetStep] = []
## Set for skills that shift along a path the player clicks out square by
## square (Bloody Rush, Phantom Dash). Used instead of [member targets].
@export var path: PathSpec
## The squares the skill hits, shown while hovering a pick (Cinder Wave).
@export var area: SkillArea
@export var effects: Array[EffectDef] = []

@export_group("Rules")
## Only usable while the caster has this status (Mirage Shift's swaps).
@export var requires_status: StringName = &""
## 0 = unlimited. Ultimates are once per battle.
@export var uses_per_battle: int = 0
## Whenever a foe strikes the caster, this skill recharges by 1 (Rage Strike).
@export var recharge_when_struck: bool = false
## Extra rule for when the skill can be used (Stoke: enough Heat).
@export var condition: SkillCondition

@export_group("Shadow copies")
## How far from a Shadow a copy of this attack can reach. 0 = Shadows can't
## copy it. The copy strikes one foe for [member copy_tiers].
@export var copy_range: int = 0
@export var copy_tiers: Array[Enums.Tier] = []
## Put on each foe a copy strikes (Gloom Edge: Blind).
@export var copy_status: StatusDef

@export_group("Presentation")
## Flipbook played on each struck target: a grid of equal frames, read left
## to right, top to bottom. Optional.
@export var hit_fx: Texture2D
@export var hit_fx_grid := Vector2i(4, 4)
@export var hit_sound: AudioStream


func describe() -> String:
	var text := description
	for effect in effects:
		var values := effect.describe_values()
		for key: String in values:
			text = text.replace("{%s}" % key, str(values[key]))
	if copy_range > 0:
		text = text.replace("{copy}", Soulstream.describe(copy_tiers))
	return text


## Every Soulstream card the skill's effects draw, in effect order.
func card_tiers() -> Array[Enums.Tier]:
	var all: Array[Enums.Tier] = []
	for effect in effects:
		all.append_array(effect.card_tiers())
	return all


## Every card the skill will draw when used with [param picks] (one set per
## strike for skills that strike several foes).
func card_tiers_for(board: BoardState, caster: UnitState, picks: Array[Vector2i]) -> Array[Enums.Tier]:
	var all: Array[Enums.Tier] = []
	for effect in effects:
		all.append_array(effect.card_tiers_for(board, caster, picks))
	return all


## Standard skills (not Basic, Ultimate or Recovery). Adrenal Surge affects these.
func is_standard() -> bool:
	return slot not in [Enums.Slot.BASIC, Enums.Slot.ULTIMATE, Enums.Slot.RECOVERY]


func is_path() -> bool:
	return path != null


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


## "Skill action · Recharge 2", shown above the description.
func cost_text() -> String:
	var parts: Array[String] = []
	match cost:
		Enums.Cost.SKILL:
			parts.append("Skill action")
		Enums.Cost.MOVE:
			parts.append("Maneuver (move action)")
		Enums.Cost.FREE:
			parts.append("Free")
	if cooldown > 0:
		parts.append("Recharge %d" % cooldown)
	if uses_per_battle > 0:
		parts.append("%d per battle" % uses_per_battle)
	if slot == Enums.Slot.RECOVERY:
		parts.append("Recovery (2 per battle for the whole team)")
	return " · ".join(parts)
