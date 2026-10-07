extends GutTest
## Strike maths: Soulstream cards at their medians, Power, Armor, dodges
## (Evasion), grazes, Accuracy and Blind. Plus round-clock statuses.

const BLIND := preload("res://content/statuses/common/blind.tres")
const CRIPPLE := preload("res://content/statuses/common/cripple.tres")

const BR := Enums.Tier.BRONZE
const SI := Enums.Tier.SILVER
const GO := Enums.Tier.GOLD


func _spec(tiers: Array) -> StrikeSpec:
	var typed: Array[Enums.Tier] = []
	typed.assign(tiers)
	return StrikeSpec.cards(typed)


func _stat_status(stat: StringName, amount: int) -> StatusDef:
	var st := TestRig.status(StringName("buff_%s" % stat))
	st.stat_mods = { stat: amount }
	return st


func test_medians_are_two_three_four() -> void:
	assert_eq(Soulstream.median(BR), 2)
	assert_eq(Soulstream.median(SI), 3)
	assert_eq(Soulstream.median(GO), 4)
	assert_eq(Soulstream.describe([GO, SI] as Array[Enums.Tier]), "7 (Gold + Silver)")


func test_random_draws_stay_in_the_tier_range() -> void:
	var s := Soulstream.new()
	s.mode = Soulstream.Mode.RANDOM
	s.rng.seed = 7
	for tier: Enums.Tier in [BR, SI, GO]:
		for i in 50:
			var v := s.draw(tier).value
			assert_between(v, int(tier) + 1, int(tier) + 3, "%s range" % Soulstream.tier_name(tier))


func test_strike_deals_the_card_total() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var hit := await rig.resolver.strike(rig.player(), rig.enemy(), _spec([SI, SI]))
	assert_eq(hit.dealt, 6)
	assert_eq(rig.enemy().hp, 6)


func test_power_adds_and_armor_subtracts_never_below_one() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	await rig.resolver.apply_status(rig.player(), _stat_status(&"power", 2))
	var hit := await rig.resolver.strike(rig.player(), rig.enemy(), _spec([SI]))
	assert_eq(hit.amount, 5, "Silver 3 raised two tiers (Gold, then +1 past Gold)")

	await rig.resolver.apply_status(rig.enemy(), _stat_status(&"armor", 9))
	hit = await rig.resolver.strike(rig.player(), rig.enemy(), _spec([BR]))
	assert_eq(hit.amount, 1, "Armor can't push a strike below 1")


func test_a_dodge_cancels_the_lowest_card() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	rig.enemy().def.evasion = 1
	var hit := await rig.resolver.strike(rig.player(), rig.enemy(), _spec([GO, SI]))
	assert_true(hit.dodged)
	assert_eq(hit.amount, 4, "Gold + Silver loses the Silver")
	assert_true(rig.log.texts().has("Dodge"))

	hit = await rig.resolver.strike(rig.player(), rig.enemy(), _spec([GO, SI]))
	assert_false(hit.dodged, "One dodge per round per point of Evasion")
	assert_eq(hit.amount, 7)


func test_a_one_card_strike_is_grazed_for_one() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	rig.enemy().def.evasion = 1
	var hit := await rig.resolver.strike(rig.player(), rig.enemy(), _spec([GO]))
	assert_true(hit.grazed)
	assert_eq(hit.dealt, 1)
	assert_true(rig.log.texts().has("Graze"))


func test_dodges_come_back_at_the_start_of_the_units_turn() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	rig.enemy().def.evasion = 1
	await rig.resolver.strike(rig.player(), rig.enemy(), _spec([SI]))
	assert_eq(rig.enemy().dodges_left(), 0)
	await rig.new_turn(rig.enemy())
	assert_eq(rig.enemy().dodges_left(), 1)


func test_accuracy_needs_an_extra_dodge_per_point() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	rig.player().def.accuracy = 1
	rig.enemy().def.evasion = 1
	var hit := await rig.resolver.strike(rig.player(), rig.enemy(), _spec([SI, SI]))
	assert_false(hit.dodged, "Accuracy 1 beats a single dodge")
	assert_eq(rig.enemy().dodges_left(), 1, "and doesn't waste it")

	rig.enemy().def.evasion = 2
	hit = await rig.resolver.strike(rig.player(), rig.enemy(), _spec([SI, SI]))
	assert_true(hit.dodged, "Two dodges cover Accuracy 1")
	assert_eq(rig.enemy().dodges_left(), 0)


func test_allies_never_dodge_each_other() -> void:
	var rig := TestRig.make(self, ["P A"] as Array[String])
	rig.ally().def.evasion = 3
	var hit := await rig.resolver.strike(rig.player(), rig.ally(), _spec([SI, SI]))
	assert_false(hit.dodged)


func test_blind_makes_the_next_strike_count_as_dodged_once() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	await rig.resolver.apply_status(rig.enemy(), BLIND)
	var hit := await rig.resolver.strike(rig.enemy(), rig.player(), _spec([GO, SI]))
	assert_eq(hit.amount, 4, "Blinded: loses its lowest card")
	assert_false(rig.enemy().has_status(&"blind"), "Used up")
	hit = await rig.resolver.strike(rig.enemy(), rig.player(), _spec([GO, SI]))
	assert_eq(hit.amount, 7)


func test_round_clock_statuses_end_at_the_next_round_not_the_owners_turn() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	await rig.resolver.apply_status(rig.enemy(), BLIND, rig.player())
	await rig.new_turn(rig.enemy())
	assert_true(rig.enemy().has_status(&"blind"), "Still there for the foe's own phase")
	await rig.new_round()
	assert_false(rig.enemy().has_status(&"blind"), "Gone at the end of the turn")


func test_cripple_ends_after_the_next_walk() -> void:
	var rig := TestRig.make(self, ["E . . . . . P"] as Array[String])
	var foe := rig.enemy()
	await rig.resolver.apply_status(foe, CRIPPLE, rig.player())
	assert_eq(foe.get_stat(&"move"), 2, "4 - 2")
	assert_true(await rig.resolver.request_move(foe, Vector2i(2, 0)))
	assert_false(foe.has_status(&"cripple"))
	assert_eq(foe.get_stat(&"move"), 4)


func test_health_loss_ignores_armor_and_dodges() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	rig.enemy().def.evasion = 2
	await rig.resolver.apply_status(rig.enemy(), _stat_status(&"armor", 3))
	assert_eq(rig.resolver.lose_health(rig.enemy(), 4), 4)
	assert_eq(rig.enemy().hp, 8)
