extends GutTest
## The suit Soulstream (references/soulstream-spec.md): the 60-card deck,
## hands and the shared row, activating cards for their base effects,
## priming them for a skill's boon or Heroic, and flips.

const B := Enums.Suit.BLADE
const O := Enums.Suit.ORB
const P := Enums.Suit.PORTAL
const W := Enums.Suit.WARD


## A skill with a boon suit that remembers the tier it was used at.
class BoonProbe extends EffectDef:
	var levels: Array[int] = []

	func apply(ctx: ActionContext) -> void:
		levels.append(ctx.boon_level)


func _boon_skill(suits: Array, probe: BoonProbe) -> SkillDef:
	var s := SkillDef.new()
	s.id = &"test_boon"
	s.boon_suits.assign(suits)
	s.effects.append(probe)
	return s


## Strikes one adjacent pick for Silver (3).
func _strike_skill() -> SkillDef:
	var s := SkillDef.new()
	s.id = &"test_strike"
	s.tags = [&"attack"]
	s.targets.append(TargetStep.new())
	var d := DamageEffect.new()
	d.tiers = [Enums.Tier.SILVER] as Array[Enums.Tier]
	s.effects.append(d)
	return s


func _cooldown_skill(id: StringName) -> SkillDef:
	var s := SkillDef.new()
	s.id = id
	s.display_name = String(id)
	s.cooldown = 3
	return s


#region The deck

func test_the_deck_has_sixty_cards() -> void:
	var deck := CardDeck.standard()
	assert_eq(deck.size(), 60)
	var singles: Dictionary[int, int] = {}
	var wilds := 0
	var pairs: Dictionary[String, int] = {}
	for card in deck.draw_pile:
		if card.is_wild():
			wilds += 1
		elif card.suits.size() == 1:
			singles[int(card.suits[0])] = singles.get(int(card.suits[0]), 0) + 1
		else:
			var key := str(card)
			pairs[key] = pairs.get(key, 0) + 1
	for suit: Enums.Suit in Enums.Suit.values():
		assert_eq(singles[int(suit)], 9, "9 %s" % Card.suit_name(suit))
	assert_eq(wilds, 4)
	assert_eq(pairs.size(), 10, "Every pair, doubles included")
	for key in pairs:
		assert_eq(pairs[key], 2, key)


func test_a_two_suit_card_counts_each_suit_and_a_double_counts_twice() -> void:
	var bw := Card.of([B, W])
	assert_eq(bw.count(B), 1)
	assert_eq(bw.count(W), 1)
	assert_eq(bw.count(O), 0)
	assert_eq(Card.of([B, B]).count(B), 2)
	assert_eq(Card.wild().count(O), 1, "A Wild counts as any one suit")
	assert_eq(str(Card.of([B, B])), "Blade x2")
	assert_eq(str(bw), "Blade + Ward")


func test_the_same_seed_shuffles_the_same_way() -> void:
	var a := Soulstream.new()
	var b := Soulstream.new()
	a.use_decks(42)
	b.use_decks(42)
	for i in 20:
		assert_eq(str(a.take()), str(b.take()))


func test_an_empty_deck_reshuffles_its_discards() -> void:
	var s := Soulstream.new()
	s.use_decks(3)
	for i in 60:
		s.flip()
	assert_eq(s.deck.draw_pile.size(), 0)
	s.take()
	assert_eq(s.deck.draw_pile.size(), 59, "The discards came back")

#endregion

#region Hands and the row

func test_income_fills_hands_of_two_and_a_row_of_three() -> void:
	var rig := TestRig.make(self, ["P A E"] as Array[String])
	var bc := BattleController.new()
	add_child_autofree(bc)
	bc.board = rig.board
	bc.resolver = rig.resolver
	for i in 3:
		await bc._soulstream_income()
	assert_eq(rig.player().hand.size(), 2)
	assert_eq(rig.ally().hand.size(), 2)
	assert_eq(rig.enemy().hand.size(), 0, "Enemies hold no cards")
	assert_eq(rig.resolver.soulstream(Enums.Team.PLAYER).row.size(), 3)


func test_a_third_card_activates_the_oldest_first() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var p := rig.player()
	p.hand.append(Card.of([W]))
	p.hand.append(Card.of([O]))
	await rig.resolver.deal_card(p)
	assert_eq(p.hand.size(), 2)
	assert_eq(str(p.hand[0]), "Orb", "The Ward was the oldest")
	assert_eq(p.find_status(&"shield").stacks, 2, "Its Shield went up")


func test_a_fallen_incarnates_hand_is_discarded() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	await rig.resolver.deal_card(rig.player())
	rig.resolver.lose_health(rig.player(), 99)
	assert_eq(rig.player().hand.size(), 0)
	assert_eq(rig.resolver.soulstream(Enums.Team.PLAYER).deck.discard_pile.size(), 1)

#endregion

#region Activating

func test_blade_adds_one_to_every_strike_of_the_next_attack() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var p := rig.player()
	p.def.skills = [_strike_skill()] as Array[SkillDef]
	var card := Card.of([B])
	p.hand.append(card)
	assert_true(await rig.resolver.activate_card(p, card))
	assert_true(p.hand.is_empty())
	assert_true(await rig.use(p, &"test_strike", [Vector2i(1, 0)]))
	assert_eq(rig.enemy().hp, 12 - 4, "Silver 3 + 1")
	assert_false(p.has_status(&"honed"), "Used up by the attack")


func test_ward_shields_two_until_end_of_turn() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var p := rig.player()
	var card := Card.of([W])
	p.hand.append(card)
	await rig.resolver.activate_card(p, card)
	await rig.resolver.strike(rig.enemy(), p, StrikeSpec.flat(3))
	assert_eq(p.hp, 12 - 1, "2 absorbed")


func test_portal_adds_one_move_until_end_of_turn() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var p := rig.player()
	var move := p.get_stat(&"move")
	var card := Card.of([P])
	p.hand.append(card)
	await rig.resolver.activate_card(p, card)
	assert_eq(p.get_stat(&"move"), move + 1)
	await rig.resolver.start_round()
	assert_eq(p.get_stat(&"move"), move, "Gone when the next round starts")


func test_orb_recharges_the_skill_that_is_recharging() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var p := rig.player()
	var slow := _cooldown_skill(&"slow")
	p.def.skills = [slow] as Array[SkillDef]
	p.cooldowns[&"slow"] = 3
	var card := Card.of([O])
	p.hand.append(card)
	await rig.resolver.activate_card(p, card)
	assert_eq(p.cooldown_left(slow), 2)


func test_a_two_suit_card_does_both_and_a_double_does_one_twice() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var p := rig.player()
	var move := p.get_stat(&"move")
	var bp := Card.of([B, P])
	var ww := Card.of([W, W])
	p.hand.append_array([bp, ww])
	await rig.resolver.activate_card(p, bp)
	assert_true(p.has_status(&"honed"))
	assert_eq(p.get_stat(&"move"), move + 1)
	await rig.resolver.activate_card(p, ww)
	assert_eq(p.find_status(&"shield").stacks, 4)


func test_a_wild_asks_for_a_suit() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var p := rig.player()
	var card := Card.wild()
	p.hand.append(card)
	await rig.resolver.activate_card(p, card)
	assert_eq(p.find_status(&"shield").stacks, 2, "The AI's pick: Ward")


func test_any_incarnate_can_use_a_shared_row_card() -> void:
	var rig := TestRig.make(self, ["P A E"] as Array[String])
	var stream := rig.resolver.soulstream(Enums.Team.PLAYER)
	var card := Card.of([W])
	stream.row.append(card)
	assert_false(await rig.resolver.activate_card(rig.enemy(), card), "Not the enemy's")
	assert_true(await rig.resolver.activate_card(rig.ally(), card))
	assert_true(stream.row.is_empty())
	assert_true(rig.ally().has_status(&"shield"))


func test_cards_you_dont_hold_are_refused() -> void:
	var rig := TestRig.make(self, ["P A E"] as Array[String])
	var card := Card.of([B])
	rig.ally().hand.append(card)
	assert_false(await rig.resolver.activate_card(rig.player(), card))
	assert_eq(rig.ally().hand.size(), 1)


func test_cards_used_are_counted_in_the_report() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var card := Card.of([W])
	rig.player().hand.append(card)
	await rig.resolver.activate_card(rig.player(), card)
	assert_eq(rig.resolver.stats.rows()[0].cards, 1)
	assert_eq(rig.resolver.stats.rows()[0].shield, 2, "Ward's shield counts as shield given")

#endregion

#region Priming

func test_a_primed_matching_card_pays_the_boon() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var p := rig.player()
	var probe := BoonProbe.new()
	p.def.skills = [_boon_skill([B], probe)] as Array[SkillDef]
	var blade := Card.of([B])
	var ward := Card.of([W])
	p.hand.append_array([blade, ward])
	assert_true(await rig.resolver.request_skill(p, p.def.skills[0], [], [blade, ward] as Array[Card]))
	assert_eq(probe.levels, [1] as Array[int])
	assert_eq(p.hand, [ward] as Array[Card], "The Ward didn't match: it stays")


func test_two_matches_or_a_double_pay_the_heroic() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var p := rig.player()
	var probe := BoonProbe.new()
	p.def.skills = [_boon_skill([O], probe)] as Array[SkillDef]
	var double := Card.of([O, O])
	p.hand.append(double)
	await rig.resolver.request_skill(p, p.def.skills[0], [], [double] as Array[Card])
	p.actions.refresh()
	var a := Card.of([O, W])
	var b := Card.wild()
	p.hand.append_array([a, b])
	await rig.resolver.request_skill(p, p.def.skills[0], [], [a, b] as Array[Card])
	assert_eq(probe.levels, [2, 2] as Array[int])
	assert_true(p.hand.is_empty())


func test_a_skill_without_a_boon_leaves_primed_cards_alone() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var p := rig.player()
	var probe := BoonProbe.new()
	p.def.skills = [_boon_skill([], probe)] as Array[SkillDef]
	var blade := Card.of([B])
	p.hand.append(blade)
	await rig.resolver.request_skill(p, p.def.skills[0], [], [blade] as Array[Card])
	assert_eq(probe.levels, [0] as Array[int])
	assert_eq(p.hand.size(), 1)

#endregion


func test_a_flip_turns_the_top_card_and_discards_it() -> void:
	var rig := TestRig.make(self, ["P E"] as Array[String])
	var stream := rig.resolver.soulstream(Enums.Team.PLAYER)
	var card := rig.resolver.flip_card(rig.player())
	assert_eq(str(card), "Blade", "The unshuffled deck starts with a Blade")
	assert_eq(stream.deck.discard_pile, [card] as Array[Card])
