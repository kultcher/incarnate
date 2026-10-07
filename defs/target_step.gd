class_name TargetStep
extends Resource
## One click the player makes when using a skill. A skill lists its steps in
## order; Ravage has two ("adjacent enemy", then "adjacent enemy" again).

@export var shape: Enums.TargetShape = Enums.TargetShape.ADJACENT
@export var origin: Enums.TargetOrigin = Enums.TargetOrigin.CASTER
@export var filter: Enums.TargetFilter = Enums.TargetFilter.ENEMY
## Used by WITHIN. ADJACENT is always exactly 1.
@export var range_min: int = 1
@export var range_max: int = 1
## If true, a cell picked in an earlier step can't be picked again.
@export var unique: bool = false
@export var highlight: Enums.Highlight = Enums.Highlight.ATTACK
## Replaces shape and filter with custom code (Displacer Strike).
@export var rule: TargetRule
## Shown while the player is choosing, e.g. "Pick the first foe to strike".
@export var prompt: String = ""
