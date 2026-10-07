extends GutTest
## Statuses: stacking, stats, durations (owner turns and rounds), links and
## the hooks the resolver runs. Kit-specific statuses are tested with their
## kits (test_bloodthane_kit, test_traceless_kit).


func _status(id: StringName, duration: int, stacking: Enums.Stacking, max_stacks: int = 1) -> StatusDef:
	var st := TestRig.status(id, duration)
	st.stacking = stacking
	st.max_stacks = max_stacks
	return st


func test_refresh_keeps_one_copy_and_resets_duration() -> void:
	var rig := TestRig.make(self, ["P"] as Array[String])
	var st := _status(&"buff", 2, Enums.Stacking.REFRESH)
	var a := await rig.resolver.apply_status(rig.player(), st)
	a.turns_left = 1
	var b := await rig.resolver.apply_status(rig.player(), st)
	assert_eq(a, b)
	assert_eq(rig.player().statuses.size(), 1)
	assert_eq(a.turns_left, 2)


func test_add_stacks_up_to_the_cap() -> void:
	var rig := TestRig.make(self, ["P"] as Array[String])
	var st := _status(&"marks", 1, Enums.Stacking.ADD, 2)
	for i in 3:
		await rig.resolver.apply_status(rig.player(), st)
	assert_eq(rig.player().find_status(&"marks").stacks, 2)


func test_apply_with_stacks_sets_the_count() -> void:
	var rig := TestRig.make(self, ["P"] as Array[String])
	var st := _status(&"rage", 1, Enums.Stacking.REFRESH, 99)
	st.stat_mods = { &"power": 1 }
	await rig.resolver.apply_status(rig.player(), st, null, null, 5)
	assert_eq(rig.player().get_stat(&"power"), 5)


func test_independent_copies_and_non_stacking_stat_mods() -> void:
	var rig := TestRig.make(self, ["P"] as Array[String])
	var boon := _status(&"boon", 0, Enums.Stacking.INDEPENDENT)
	boon.stat_mods = { &"move": 1 }
	boon.stat_mods_stack = false
	await rig.resolver.apply_status(rig.player(), boon)
	await rig.resolver.apply_status(rig.player(), boon)
	assert_eq(rig.player().statuses.size(), 2)
	assert_eq(rig.player().get_stat(&"move"), 5, "+1 move once, not +2")


func test_stat_mods_never_go_negative() -> void:
	var rig := TestRig.make(self, ["P"] as Array[String])
	var slow := _status(&"slow", 0, Enums.Stacking.REFRESH)
	slow.stat_mods = { &"move": -10, &"armor": -3 }
	await rig.resolver.apply_status(rig.player(), slow)
	assert_eq(rig.player().get_stat(&"move"), 0)
	assert_eq(rig.player().get_stat(&"armor"), 0)


func test_owner_turn_durations_count_the_owners_turns() -> void:
	var rig := TestRig.make(self, ["P"] as Array[String])
	await rig.resolver.apply_status(rig.player(), _status(&"short", 1, Enums.Stacking.REFRESH))
	await rig.resolver.apply_status(rig.player(), _status(&"forever", 0, Enums.Stacking.REFRESH))
	await rig.new_round()
	assert_true(rig.player().has_status(&"short"), "A new round doesn't count")
	await rig.new_turn(rig.player())
	assert_false(rig.player().has_status(&"short"), "Gone at the start of the next turn")
	assert_true(rig.player().has_status(&"forever"))


func test_round_durations_count_rounds() -> void:
	var rig := TestRig.make(self, ["P"] as Array[String])
	await rig.resolver.apply_status(rig.player(), TestRig.status(&"two_rounds", 2, Enums.StatusClock.ROUND))
	await rig.new_turn(rig.player())
	await rig.new_round()
	assert_true(rig.player().has_status(&"two_rounds"))
	await rig.new_round()
	assert_false(rig.player().has_status(&"two_rounds"))


func test_linked_statuses_end_when_the_link_dies() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var st := _status(&"linked", 0, Enums.Stacking.INDEPENDENT)
	await rig.resolver.apply_status(rig.player(), st, rig.player(), rig.enemy())
	rig.resolver.lose_health(rig.enemy(), 99)
	assert_false(rig.player().has_status(&"linked"))


func test_healing_caps_at_max_hp() -> void:
	var rig := TestRig.make(self, ["P"] as Array[String])
	rig.player().hp = 10
	assert_eq(rig.resolver.heal(rig.player(), 4), 2)
	assert_eq(rig.player().hp, 12)


func test_heal_cards_adds_the_healers_power() -> void:
	var rig := TestRig.make(self, ["P A"] as Array[String])
	rig.player().def.power = 1
	rig.ally().hp = 1
	assert_eq(rig.resolver.heal_cards(rig.player(), rig.ally(), [Enums.Tier.SILVER] as Array[Enums.Tier]), 4)
