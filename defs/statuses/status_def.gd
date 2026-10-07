class_name StatusDef
extends Resource
## A buff, debuff, passive or Pact: anything that sits on a unit and changes
## its stats or reacts to what happens. One .tres per kind of status; a
## StatusInstance is one copy of it on one unit.

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export_multiline var description: String
## How long it lasts. 0 = permanent. Counted at the start of each of its
## owner's turns, or at the start of each round (see [member clock]).
@export var duration: int = 0
## ROUND for "until end of turn" effects: they last until the next round
## starts, so a debuff put on a foe in your phase still works in its phase.
@export var clock: Enums.StatusClock = Enums.StatusClock.OWNER_TURN
@export var stacking: Enums.Stacking = Enums.Stacking.REFRESH
@export var max_stacks: int = 1
## Added to the owner's stats, e.g. { &"move": -1 }. Multiplied by stacks.
@export var stat_mods: Dictionary[StringName, int] = {}
## If false, several copies of this status on one unit count only once for
## stat_mods (two Predation Pacts still give the Bloodthane +1 move, not +2).
@export var stat_mods_stack: bool = true
## Free-form tags rules can look for:
##   taunt        the AI strongly prefers attacking the status's link (Provoke)
##   debuff       a harmful effect from a foe (Chimeric Cloak can negate it)
##   blind        the owner's next strike counts as dodged, then it ends
##   end_on_move  ends after the owner's next walk (Cripple)
##   no_cooldown_next  the owner's next standard skill isn't exhausted (Adrenal Surge)
@export var tags: Array[StringName] = []
## Draw the icon over the unit on the board (passives usually don't).
@export var show_on_unit: bool = true
## What it does when things happen. Optional: a status with only stat_mods
## needs no behavior.
@export var behavior: StatusBehavior


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)
