extends GutTest
## The turn loop with no Presenter: AI plays both sides.

const BLADE_FURY := preload("res://content/skills/bloodthane/blade_fury.tres")
const CLAW := preload("res://content/skills/shambler/claw.tres")

var resolver: ActionResolver
var battle: BattleController
var ai: EnemyAI


func _make(rows: Array[String]) -> BoardFixture:
	var f := BoardFixture.parse(rows)
	for unit in f.board.units():
		if unit.is_player():
			unit.def.skills = [BLADE_FURY]
		else:
			unit.def.skills = [CLAW]
			unit.def.flex_points = 0
			unit.actions = ActionEconomy.new(1, 1, 0)
	resolver = ActionResolver.new()
	resolver.board = f.board
	ai = EnemyAI.new()
	ai.board = f.board
	ai.resolver = resolver
	battle = BattleController.new()
	battle.board = f.board
	battle.resolver = resolver
	battle.player_driver = ai
	battle.enemy_driver = ai
	battle.autoplay_driver = ai
	battle.autoplay = true
	for node: Node in [resolver, ai, battle]:
		add_child_autofree(node)
	return f


func test_ai_vs_ai_battle_reaches_an_outcome() -> void:
	var f := _make([
		"P . . . . . E",
		". . # # . . .",
		"A . . . . . E",
		". . . . . . E",
	] as Array[String])
	var outcome: Enums.Outcome = await battle.run()
	assert_true(outcome == Enums.Outcome.VICTORY or outcome == Enums.Outcome.DEFEAT,
			"Ended with %s after %d rounds" % [Enums.Outcome.keys()[outcome], battle.round_number])
	var players := 0
	var enemies := 0
	for unit in f.board.units():
		if unit.is_player():
			players += 1
		else:
			enemies += 1
	if outcome == Enums.Outcome.VICTORY:
		assert_eq(enemies, 0)
		assert_gt(players, 0)
	else:
		assert_eq(players, 0)


func test_lone_player_beats_one_weak_enemy_and_stops() -> void:
	var f := _make(["P E"] as Array[String])
	var foe := f.enemies[0]
	foe.hp = 4
	var outcome: Enums.Outcome = await battle.run()
	assert_eq(outcome, Enums.Outcome.VICTORY)
	assert_eq(battle.round_number, 1, "Won during the first player phase")
	assert_eq(f.mover.actions.flex, 1, "Stopped acting once the battle was won")


func test_unreachable_sides_end_in_a_draw() -> void:
	_make(["P # E"] as Array[String])
	battle.max_rounds = 3
	assert_eq(await battle.run(), Enums.Outcome.DRAW)


func test_each_side_refreshes_at_its_own_phase() -> void:
	var f := _make(["P . . . . . . . E"] as Array[String])
	battle.max_rounds = 2
	var claw_user := f.enemies[0]
	var seen: Array[String] = []
	resolver.action_finished.connect(func() -> void:
		seen.append("%d:%s" % [battle.round_number, Enums.Team.keys()[battle.phase]]))
	await battle.run()
	assert_eq(seen[0], "1:PLAYER", "Player side acts first")
	assert_has(seen, "1:ENEMY")
	if claw_user.is_alive():
		assert_has(seen, "2:PLAYER")
	var first_enemy := seen.find("1:ENEMY")
	for i in first_enemy:
		assert_eq(seen[i], "1:PLAYER", "No enemy action before the player phase ends")
