extends Node

enum {PLAYER_TURN, ENEMY_TURN}
enum {NO_SELECTION, PLAYER_SELECTION, PLAYER_MOVE, PLAYER_ACTION, ENEMY_MOVE, ENEMY_ACTION}
enum {MOVE, SHIFT, FLY, TELEPORT}

var turn
var state = NO_SELECTION
var movestate



func start_player_turn():
	turn = PLAYER_TURN
	state = NO_SELECTION
	get_tree().call_group("all_player_units", "start_new_turn")

	
	
func end_player_turn():
	print("Player ended turn.")
#	get_tree().call_group("checked_tiles", "deselect")
	$TurnTimer.start()
	yield($TurnTimer, "timeout")
	start_enemy_turn()


func start_enemy_turn():
	turn = ENEMY_TURN
	state = NO_SELECTION
	$World/Encounter.start_turn()

func end_enemy_turn():
	start_player_turn()
