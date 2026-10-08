extends GutTest
## The Soulstream: tier decks, hands, the shared row, readying cards for a
## skill, and each side drawing from its own decks.

const BR := Enums.Tier.BRONZE
const SI := Enums.Tier.SILVER
const GO := Enums.Tier.GOLD


func _tiers(list: Array) -> Array[Enums.Tier]:
	var typed: Array[Enums.Tier] = []
	typed.assign(list)
	return typed


func _cards(list: Array) -> Array[Card]:
	var typed: Array[Card] = []
	typed.assign(list)
	return typed


## Strikes one adjacent pick for [param tiers].
func _strike_skill(tiers: Array) -> SkillDef:
	var s := SkillDef.new()
	s.id = &"test_strike"
	s.targets.append(TargetStep.new())
	var d := DamageEffect.new()
	d.tiers = _tiers(tiers)
	s.effects.append(d)
	return s


## Does nothing that draws cards.
func _no_draw_skill() -> SkillDef:
	var s := SkillDef.new()
	s.id = &"test_nothing"
	return s


func _rig(rows: Array[String], skills: Array[SkillDef]) -> TestRig:
	var rig := TestRig.make(self, rows)
	rig.player().def.skills = skills
	return rig


func test_a_tier_deck_has_five_six_four_of_each_suit() -> void:
	var rng := RandomNumberGenerator.new()
	var deck := CardDeck.standard(SI, rng)
	assert_eq(deck.draw_pile.size(), 60)
	var counts := {}
	for card in deck.draw_pile:
		var key := "%d:%d" % [card.suit, card.value]
		counts[key] = counts.get(key, 0) + 1
	for suit: Enums.Suit in Enums.Suit.values():
		assert_eq(counts.get("%d:2" % suit, 0), 5, "%s low" % Card.suit_name(suit))
		assert_eq(counts.get("%d:3" % suit, 0), 6, "%s median" % Card.suit_name(suit))
		assert_eq(counts.get("%d:4" % suit, 0), 4, "%s high" % Card.suit_name(suit))


func test_the_same_seed_shuffles_the_same_way() -> void:
	var a := Soulstream.new()
	var b := Soulstream.new()
	a.use_decks(42)
	b.use_decks(42)
	for i in 20:
		assert_eq(str(a.draw(GO)), str(b.draw(GO)))


func test_an_empty_deck_reshuffles_its_discards() -> void:
	var s := Soulstream.new()
	s.use_decks(3)
	for i in 60:
		s.draw(BR)
	assert_eq(s.deck(BR).draw_pile.size(), 0)
	assert_eq(s.deck(BR).discard_pile.size(), 60)
	s.draw(BR)
	assert_eq(s.deck(BR).draw_pile.size(), 59, "Discards went back in")


func test_hands_hold_two_and_the_row_three() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	for i in 3:
		rig.resolver.deal_card(rig.player())
	assert_eq(rig.player().hand.size(), Soulstream.HAND_SIZE)
	assert_eq(rig.player().hand[0].tier, SI, "Hands draw from the Silver deck")
	for i in 5:
		rig.resolver.refill_row(Enums.Team.PLAYER)
	assert_eq(rig.resolver.soulstream(Enums.Team.PLAYER).row.size(), Soulstream.ROW_SIZE)
	assert_has(rig.log.types, GameEvent.CARDS_CHANGED)


func test_held_cards_leave_the_deck_until_spent() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	rig.resolver.use_decks(5)
	rig.resolver.deal_card(rig.player())
	var stream := rig.resolver.soulstream(Enums.Team.PLAYER)
	assert_eq(stream.deck(SI).draw_pile.size(), 59)
	assert_eq(stream.deck(SI).discard_pile.size(), 0, "A held card isn't discarded")


func test_a_readied_hand_card_replaces_a_blind_draw() -> void:
	var skill := _strike_skill([SI, SI])
	var rig := _rig(["P E"] as Array[String], [skill])
	var ace := Card.new(SI, 4, Enums.Suit.BLADE)
	rig.player().hand.append(ace)
	assert_true(await rig.resolver.request_skill(rig.player(), skill,
			TestRig.cells([Vector2i(1, 0)]), _cards([ace])))
	assert_eq(rig.enemy().hp, 12 - (4 + 3), "Held 4 plus a blind median 3")
	assert_false(rig.player().hand.has(ace), "The card was spent")


func test_readied_cards_replace_the_lowest_tier_draws() -> void:
	var s := Soulstream.new()
	var unit := UnitState.new(UnitDef.new(), Enums.Team.PLAYER)
	var five := Card.new(SI, 5)
	unit.hand.append(five)
	s.ready_cards(unit, _cards([five]))
	var cards := s.draw_for(_tiers([GO, BR, SI]))
	assert_eq(cards[0].value, 4, "Gold drawn blind")
	assert_same(cards[1], five, "The held card stands in for the Bronze")
	assert_eq(cards[2].value, 3, "Silver drawn blind")
	assert_true(cards[1].held)
	assert_false(cards[0].held)


func test_a_shared_row_card_can_be_readied() -> void:
	var skill := _strike_skill([BR])
	var rig := _rig(["P E"] as Array[String], [skill])
	var stream := rig.resolver.soulstream(Enums.Team.PLAYER)
	var gold := Card.new(GO, 5, Enums.Suit.WARD)
	stream.row.append(gold)
	await rig.resolver.request_skill(rig.player(), skill, TestRig.cells([Vector2i(1, 0)]), _cards([gold]))
	assert_eq(rig.enemy().hp, 7, "Any card can stand in for any tier")
	assert_eq(stream.row.size(), 0)


func test_unused_readied_cards_go_back() -> void:
	var nothing := _no_draw_skill()
	var rig := _rig(["P E"] as Array[String], [nothing])
	var stream := rig.resolver.soulstream(Enums.Team.PLAYER)
	var mine := Card.new(SI, 4)
	var shared := Card.new(BR, 3)
	rig.player().hand.append(mine)
	stream.row.append(shared)
	assert_true(await rig.resolver.request_skill(rig.player(), nothing, [] as Array[Vector2i],
			_cards([mine, shared])))
	assert_eq(rig.player().hand, _cards([mine]))
	assert_eq(stream.row, _cards([shared]))
	assert_eq(stream.readied_count(), 0)


func test_extra_readied_cards_go_back_after_the_strike() -> void:
	var skill := _strike_skill([SI])
	var rig := _rig(["P E"] as Array[String], [skill])
	var a := Card.new(SI, 4)
	var b := Card.new(SI, 2)
	rig.player().hand.append_array([a, b])
	await rig.resolver.request_skill(rig.player(), skill, TestRig.cells([Vector2i(1, 0)]), _cards([a, b]))
	assert_eq(rig.enemy().hp, 8, "Only the first readied card was needed")
	assert_eq(rig.player().hand, _cards([b]))


func test_cards_you_dont_hold_are_refused() -> void:
	var skill := _strike_skill([SI])
	var rig := _rig(["P A E"] as Array[String], [skill])
	var theirs := Card.new(GO, 5)
	rig.ally().hand.append(theirs)
	assert_false(await rig.resolver.request_skill(rig.player(), skill,
			TestRig.cells([Vector2i(2, 0)]), _cards([theirs])), "An ally's hand isn't yours")
	assert_eq(rig.ally().hand.size(), 1)
	assert_eq(rig.player().actions.skill, 1, "Nothing was paid")
	var mine := Card.new(SI, 4)
	rig.player().hand.append(mine)
	assert_false(await rig.resolver.request_skill(rig.player(), skill,
			TestRig.cells([Vector2i(2, 0)]), _cards([mine, mine])), "A card can't be used twice")


func test_enemies_draw_from_their_own_deck() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	rig.resolver.use_decks(9)
	var theirs := rig.resolver.soulstream(Enums.Team.ENEMY)
	var ours := rig.resolver.soulstream(Enums.Team.PLAYER)
	await rig.resolver.strike(rig.enemy(), rig.player(), StrikeSpec.cards(_tiers([SI])))
	assert_eq(theirs.deck(SI).discard_pile.size(), 1)
	assert_eq(ours.deck(SI).discard_pile.size(), 0)


func test_a_fallen_incarnates_hand_is_discarded() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	rig.resolver.use_decks(11)
	rig.resolver.deal_card(rig.player())
	rig.resolver.lose_health(rig.player(), 99)
	assert_eq(rig.player().hand.size(), 0)
	assert_eq(rig.resolver.soulstream(Enums.Team.PLAYER).deck(SI).discard_pile.size(), 1)


func test_battle_income_each_player_phase() -> void:
	var rig := TestRig.make(self, ["P A E"] as Array[String])
	var bc := BattleController.new()
	add_child_autofree(bc)
	bc.board = rig.board
	bc.resolver = rig.resolver
	bc._soulstream_income()
	bc._soulstream_income()
	bc._soulstream_income()
	assert_eq(rig.player().hand.size(), 2)
	assert_eq(rig.ally().hand.size(), 2)
	assert_eq(rig.enemy().hand.size(), 0, "Enemies hold no cards")
	assert_eq(rig.resolver.soulstream(Enums.Team.PLAYER).row.size(), 3)


func test_the_ai_readies_cards_that_beat_the_median() -> void:
	var skill := _strike_skill([GO, BR])
	var rig := _rig(["P E"] as Array[String], [skill])
	var stream := rig.resolver.soulstream(Enums.Team.PLAYER)
	var four := Card.new(SI, 4)
	var two := Card.new(SI, 2)
	var shared_four := Card.new(SI, 4)
	rig.player().hand.append_array([two, four])
	stream.row.append(shared_four)
	var chosen := AiPlanner.choose_cards(rig.resolver, rig.player(), skill)
	assert_eq(chosen, _cards([four]),
			"Your own 4 stands in for the Bronze; no 4 beats Gold's median")
	stream.row.append(Card.new(GO, 5))
	chosen = AiPlanner.choose_cards(rig.resolver, rig.player(), skill)
	assert_eq(chosen.size(), 1, "5 + 4 gains no more than the 5 alone, so keep the 4")
	assert_eq(chosen[0].value, 5)


func test_the_ai_readies_cards_for_every_strike_of_a_path_skill() -> void:
	var rush := preload("res://content/skills/bloodthane/bloody_rush.tres")
	var rig := _rig(["P E E . ."] as Array[String], [rush])
	rig.player().hand.append_array([Card.new(SI, 4), Card.new(SI, 4)])
	var picks := TestRig.cells([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])
	assert_eq(AiPlanner.choose_cards(rig.resolver, rig.player(), rush, picks).size(), 2,
			"Two foes on the path: a 4 for each strike")
	assert_eq(AiPlanner.choose_cards(rig.resolver, rig.player(), rush).size(), 1,
			"Without the picks, one strike's worth")
