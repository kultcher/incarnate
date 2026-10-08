class_name BattleController
extends Node
## The turn loop. Side-based: the player's units all act (in any order,
## interleaved), then every enemy acts, then a new round starts.
##
##   round N:  player phase  ->  enemy phase  ->  round N+1 ...
##
## Each phase refreshes that side's action points and ticks its cooldowns
## at the start. Each round first ends the previous turn's "until end of
## turn" effects (ActionResolver.start_round). The battle ends as soon as one side has no units left.

signal battle_ended(outcome: Enums.Outcome)

## Safety net for AI-vs-AI runs that can't reach each other.
@export var max_rounds: int = 60

var board: BoardState
var resolver: ActionResolver
## Who plays each side. Usually the PlayerController and an EnemyAI.
var player_driver: TurnDriver
var enemy_driver: TurnDriver
## Plays the player's side when autoplay is on (F9 in the battle scene).
var autoplay_driver: TurnDriver
var autoplay: bool = false

var round_number: int = 0
var phase: Enums.Team = Enums.Team.PLAYER
var outcome: Enums.Outcome = Enums.Outcome.NONE


## Plays the whole battle. Returns the outcome.
func run() -> Enums.Outcome:
	var over := func() -> bool: return outcome != Enums.Outcome.NONE
	for driver: TurnDriver in [player_driver, enemy_driver, autoplay_driver]:
		if driver != null:
			driver.is_over = over
	resolver.action_finished.connect(_check_outcome)
	for unit in board.units():
		for passive in unit.def.passives:
			await resolver.apply_status(unit, passive, unit)
	_check_outcome()

	while outcome == Enums.Outcome.NONE:
		round_number += 1
		if round_number > max_rounds:
			outcome = Enums.Outcome.DRAW
			break
		await _player_phase()
		if outcome != Enums.Outcome.NONE:
			break
		await _enemy_phase()

	resolver.action_finished.disconnect(_check_outcome)
	await resolver.announce_outcome(outcome)
	battle_ended.emit(outcome)
	return outcome


func is_over() -> bool:
	return outcome != Enums.Outcome.NONE


func _player_phase() -> void:
	phase = Enums.Team.PLAYER
	await resolver.announce_phase(Enums.Team.PLAYER, round_number)
	# Upkeep after the banner, so drains and heals play under it. The new
	# round ends last turn's "until end of turn" effects first.
	await resolver.start_round()
	_check_outcome()
	if is_over():
		return
	_soulstream_income()
	await _start_side(Enums.Team.PLAYER)
	_check_outcome()
	if is_over():
		return
	if autoplay and autoplay_driver != null:
		await autoplay_driver.take_turn(Enums.Team.PLAYER)
		return
	await player_driver.take_turn(Enums.Team.PLAYER)
	# Autoplay switched on mid-turn: let the AI spend what's left.
	if autoplay and autoplay_driver != null and not is_over():
		await autoplay_driver.take_turn(Enums.Team.PLAYER)


func _enemy_phase() -> void:
	phase = Enums.Team.ENEMY
	await resolver.announce_phase(Enums.Team.ENEMY, round_number)
	# Upkeep after the banner, so drains and heals play under it.
	await _start_side(Enums.Team.ENEMY)
	_check_outcome()
	if is_over():
		return
	await enemy_driver.take_turn(Enums.Team.ENEMY)


## Each Incarnate draws a card into its hand, and the shared row gets one.
func _soulstream_income() -> void:
	resolver.refill_row(Enums.Team.PLAYER)
	for unit in board.units():
		if unit.is_player() and unit.is_alive():
			resolver.deal_card(unit)


func _start_side(team: Enums.Team) -> void:
	for unit in board.units():
		if unit.team == team and unit.is_alive():
			await resolver.start_turn(unit)


func _check_outcome() -> void:
	if outcome != Enums.Outcome.NONE:
		return
	var players := 0
	var enemies := 0
	for unit in board.units():
		if not unit.is_alive():
			continue
		if unit.is_player():
			players += 1
		else:
			enemies += 1
	if players == 0:
		outcome = Enums.Outcome.DEFEAT
	elif enemies == 0:
		outcome = Enums.Outcome.VICTORY
