class_name Encounter
extends TurnDriver
## A scripted enemy side (a boss fight). Put one in a level as a node named
## "Encounter"; the Battle then lets it play the enemy phase instead of the
## EnemyAI. Subclasses write the script: take_turn() runs one enemy phase,
## intents() says what the next one will do, so the board can show it.
##
## The script changes the battle only through the resolver, like everything
## else. Wrap each step in run_step() so follow-ups (reactions) resolve and
## the battle checks for an outcome after it.

var board: BoardState
var resolver: ActionResolver
## The current round, set at the start of each player phase.
var round_number: int = 0


func setup(p_board: BoardState, p_resolver: ActionResolver) -> void:
	board = p_board
	resolver = p_resolver


## Start of round [param n], before the player acts (flavour text, upkeep).
func begin_round(n: int) -> void:
	round_number = n
	refresh_intents()


## What the coming enemy phase will do, as things stand.
func intents() -> Array[Intent]:
	return []


## Health a unit of [param team] would lose standing on [param cell] when the
## enemy phase comes (the AI steps out of it).
func danger(_cell: Vector2i, _team: Enums.Team) -> int:
	return 0


## True once the encounter is won, even with enemies left (the boss is down).
func is_won() -> bool:
	return false


## Tells the board and HUD what the encounter will do now.
func refresh_intents() -> void:
	EventBus.intents_changed.emit(intents())


func clear_intents() -> void:
	EventBus.intents_changed.emit([] as Array[Intent])


## Runs one script step as an action: [param step] (an async Callable),
## then its follow-ups, then playback, then the outcome check.
func run_step(step: Callable) -> void:
	if is_over.call():
		return
	await step.call()
	await resolver.finish_scripted_action()
