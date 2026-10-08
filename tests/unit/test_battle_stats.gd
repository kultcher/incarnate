extends GutTest
## The end-of-battle report's totals.

const BT := preload("res://content/units/bloodthane.tres")
const MINION := preload("res://content/units/welcoming_dead.tres")


func test_strikes_actions_and_moves_are_counted() -> void:
	var rig := TestRig.make(self, ["P . . E"] as Array[String])
	await rig.equip(rig.player(), BT)
	await rig.new_turn(rig.player())
	assert_true(await rig.resolver.request_move(rig.player(), Vector2i(2, 0)))
	assert_true(await rig.use(rig.player(), &"rending_claws", [Vector2i(3, 0)]))
	var row := rig.resolver.stats.rows()[0]
	assert_eq(row.damage, 6)
	assert_eq(row.actions, 2)
	assert_eq(row.moved, 2)
	assert_eq(row.cards, 0, "No cards used")


func test_healing_and_health_loss_count_for_their_source() -> void:
	var rig := TestRig.make(self, ["P A E"] as Array[String])
	rig.ally().hp = 5
	rig.resolver.heal_cards(rig.player(), rig.ally(), [Enums.Tier.SILVER] as Array[Enums.Tier])
	rig.resolver.lose_health(rig.enemy(), 4, null, rig.player())
	rig.resolver.lose_health(rig.player(), 1, null, rig.player())  # Self-inflicted: not damage.
	var row := rig.resolver.stats.rows()[0]
	assert_eq(row.healing, 3)
	assert_eq(row.damage, 4)


func test_welcoming_dead_share_one_damage_row() -> void:
	var rig := TestRig.make(self, ["P . . ."] as Array[String])
	var a := await rig.resolver.summon(MINION, Enums.Team.ENEMY, Vector2i(1, 0))
	var b := await rig.resolver.summon(MINION, Enums.Team.ENEMY, Vector2i(2, 0))
	await rig.resolver.strike(a, rig.player(), StrikeSpec.flat(2))
	await rig.resolver.strike(b, rig.player(), StrikeSpec.flat(2))
	var rows := rig.resolver.stats.rows()
	assert_eq(rows.size(), 1)
	assert_eq(rows[0].name, "Welcoming Dead (all)")
	assert_eq(rows[0].damage, 4)
	assert_true(rig.resolver.stats.report().contains("Welcoming Dead (all)"))


func test_adds_spawned_and_slain_are_counted() -> void:
	var rig := TestRig.make(self, ["P . . ."] as Array[String])
	var a := await rig.resolver.summon(MINION, Enums.Team.ENEMY, Vector2i(1, 0))
	await rig.resolver.summon(MINION, Enums.Team.ENEMY, Vector2i(2, 0))
	rig.resolver.lose_health(a, 99, null, rig.player())
	var minions := rig.resolver.stats.rows().filter(func(r: BattleStats.Row) -> bool: return r.group)
	assert_eq(minions[0].spawned, 2)
	assert_eq(minions[0].slain, 1)
	assert_eq(rig.resolver.stats.group_lines(), ["Welcoming Dead: 2 spawned, 1 slain"] as Array[String])
