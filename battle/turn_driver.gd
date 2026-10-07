class_name TurnDriver
extends Node
## Whoever plays one side's phase: the human (PlayerController) or the AI
## (EnemyAI). The BattleController doesn't care which.

## Set by the BattleController: true once the battle has an outcome, so a
## driver can stop mid-phase.
var is_over: Callable = func() -> bool: return false


## Plays [param team]'s phase. Returns when the phase is over.
func take_turn(_team: Enums.Team) -> void:
	pass
