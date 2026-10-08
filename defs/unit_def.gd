class_name UnitDef
extends Resource
## What a unit is. One .tres per Incarnate or enemy type.

@export var id: StringName
@export var display_name: String
@export var max_hp: int = 12
@export var move: int = 4

@export_group("Combat stats")
## Each point raises one card in the unit's strikes and heals a tier (+1).
@export var power: int = 0
## Each point lowers one card in strikes against the unit a tier (-1).
@export var armor: int = 0
## Dodges per round: each cancels a foe's strike's lowest card.
@export var evasion: int = 0
## Each point means a target needs one more dodge to dodge this unit.
@export var accuracy: int = 0
@export_group("")
## Skills on the unit's bar, in order (hotkeys 1, 2, 3...).
@export var skills: Array[SkillDef] = []
@export_group("Size and traits")
## Squares per side: 1 for most units, 2 for a Large (2x2) boss. Its cell is
## the top-left square.
@export_range(1, 3) var footprint: int = 1
## Forced movement against it is this many squares shorter (minimum 1).
@export var sturdy: int = 0
## The battle report sums all units of this kind into one damage-only row
## (the Welcoming Dead).
@export var report_as_group: bool = false
@export_group("")
## Flex points per turn. Incarnates get 1; most monsters get 0, so they can
## move and attack but never attack twice.
@export_range(0, 2) var flex_points: int = 1
## Permanent statuses the unit starts every battle with (Bound in Blood).
@export var passives: Array[StatusDef] = []

@export_group("Sprite")
## Sheet laid out as columns of walk frames and one row per facing.
@export var sheet: Texture2D
@export var sheet_columns: int = 3
## Column used when standing still (middle for 3-frame RPG-style sheets).
@export var idle_column: int = 1
## Row order of facings on the sheet.
@export var sheet_rows: Array[StringName] = [&"down", &"left", &"right", &"up"]
## Height in pixels the sprite should be drawn at on a 64 px cell.
@export var display_height: float = 72.0
