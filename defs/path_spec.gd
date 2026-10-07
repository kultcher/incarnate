class_name PathSpec
extends Resource
## A shift the player clicks out one square at a time (Bloody Rush, Phantom
## Dash). Each square must be next to the previous one; it may pass through
## any unit but must end on an empty square. The player can stop early by
## clicking the last square again.

## Squares of shift.
@export var budget: int = 3
## Added to the budget for each different foe the path passes through
## (Phantom Dash: +2).
@export var extend_per_foe: int = 0
## The path must be at least this long.
@export var min_steps: int = 1
@export var highlight: Enums.Highlight = Enums.Highlight.SPECIAL
@export var prompt: String = "Click out the path"
