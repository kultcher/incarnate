extends Node
## Renders the battle scene to a PNG. Needs a real (or virtual) display, not
## --headless.
##   godot --path . res://tools/screenshot.tscn -- out.png [shot]
## Shots:
##   select     Bloodthane selected, path previewed (default)
##   targeting  clicking out Bloody Rush between the Shamblers (2 of 3 squares)
##   hit        mid-Bloody Rush, as the first strike lands
##   after      after Bloody Rush has resolved
##   enemy      during the enemy phase, after End Turn
##   end        the victory/defeat screen (AI plays both sides, sped up)
##   pact       the Bound in Blood prompt after Bloodthane's 2nd strike
##   pacted     after binding Dominance: Provoke over the Shambler, panel strip
##   cloak      the Chimeric Cloak prompt during the enemy phase
##   shadow     a Shadow selected, showing the Gloom Edge it inherited
##   traceless  the Traceless selected, its 10-skill bar and a tooltip
##   cards      Bloodthane selected with a hand card and a shared card readied
##   logged     after Blade Fury with a readied card: the strike log
##   soulweaver the Soulweaver Tethered to the Bloodthane, its bar and a tooltip
##   infusion   the Fates Intertwined prompt after Spirit Flare
##   wave       the Kindleborne aiming Cinder Wave (area preview), Heat shown
##   stoke      the Kindleborne's Stoke prompt (Ignite or Dissipate)
##   golgothon  the boss fight, round 1: his intents listed and drawn
##   caress     the boss fight, a Death's Caress turn: the loss per square
##   swarm      the boss fight after his first enemy phase (Welcoming Dead)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://screenshot.png"
	var shot := args[1] if args.size() > 1 else "select"
	var scene := "res://battle/battle.tscn"
	if shot in ["golgothon", "caress", "swarm"]:
		scene = "res://levels/golgothon/golgothon_battle.tscn"
	var battle: Battle = load(scene).instantiate()
	battle.autoplay = shot == "end"
	battle.card_seed = 4  # The same cards every time.
	if shot == "end":
		Engine.time_scale = 10.0
	add_child(battle)
	await _frames(3)

	var c := battle.controller
	var bt: UnitState
	var foes: Array[UnitState] = []
	for unit in battle.board.units():
		if unit.def.id == &"bloodthane":
			bt = unit
		elif not unit.is_player():
			foes.append(unit)
	if shot == "end":
		await battle.battle_controller.battle_ended
		Engine.time_scale = 1.0
		await get_tree().create_timer(0.6).timeout
	elif scene != "res://battle/battle.tscn":
		await get_tree().create_timer(1.2).timeout
	else:
		await c.click_cell(bt.cell)

	match shot:
		"golgothon":
			await c.click_cell(bt.cell)
		"caress":
			battle.encounter.round_number = 3
			battle.encounter.refresh_intents()
			await c.click_cell(bt.cell)
		"swarm":
			Engine.time_scale = 6.0
			c.request_end_turn()
			while not c.is_active():
				await get_tree().process_frame
			Engine.time_scale = 1.0
			await get_tree().create_timer(1.0).timeout
		"select":
			# Pretend the mouse is over a cell to show the path preview.
			c._update_hover(Vector2i(4, 5), true)
		"targeting":
			await c.click_cell(Vector2i(4, 7))
			c.begin_targeting_index(_index(bt, &"bloody_rush"))
			await c.click_cell(Vector2i(5, 7))
			await c.click_cell(Vector2i(6, 7))
			c._update_hover(Vector2i(7, 7), true)
		"pact", "pacted":
			var foe := battle.board.unit_at(Vector2i(6, 6))
			foe.hp = 20
			await c.click_cell(Vector2i(6, 7))
			c.begin_targeting_index(0)
			await c.click_cell(foe.cell)
			c.begin_targeting_index(0)
			c.click_cell(foe.cell)
			while not battle.hud.prompt.is_open():
				await get_tree().process_frame
			await get_tree().create_timer(0.3).timeout
			if shot == "pacted":
				battle.hud.prompt.pick(0)
				await get_tree().create_timer(1.0).timeout
				c._update_hover(foe.cell, true)
		"cloak":
			var tl := _find(battle, &"traceless")
			await c.click_cell(tl.cell)
			await c.click_cell(Vector2i(5, 8))
			c.begin_targeting_index(_index(tl, &"chimeric_cloak"))
			await get_tree().create_timer(0.5).timeout
			c.request_end_turn()
			while not battle.hud.prompt.is_open():
				await get_tree().process_frame
			await get_tree().create_timer(0.3).timeout
		"shadow", "traceless":
			var tl := _find(battle, &"traceless")
			await c.click_cell(tl.cell)
			if shot == "traceless":
				battle.hud._tooltip.text = battle.hud._skill_text(tl.skills()[3])
			else:
				battle.board.unit_at(Vector2i(6, 8)).hp = 20
				await c.click_cell(Vector2i(5, 8))
				c.begin_targeting_index(_index(tl, &"displacer_strike"))
				await c.click_cell(Vector2i(6, 8))
				await c.click_cell(Vector2i(7, 8))
				# The Shadow it left inherits Gloom Edge; select the Shadow.
				c.begin_targeting_index(_index(tl, &"gloom_edge"))
				await c.click_cell(Vector2i(6, 8))
				await get_tree().create_timer(0.4).timeout
				await c.click_cell(Vector2i(5, 8))
				await get_tree().create_timer(0.6).timeout
		"cards", "logged":
			if shot == "logged":
				await c.click_cell(Vector2i(5, 8))
			c.toggle_card(bt.hand[0])
			c.toggle_card(battle.resolver.soulstream(Enums.Team.PLAYER).row[0])
			if shot == "logged":
				c.begin_targeting_index(_index(bt, &"blade_fury"))
				await c.click_cell(Vector2i(6, 8))
				await get_tree().create_timer(0.6).timeout
		"soulweaver", "infusion":
			var sw := _find(battle, &"soulweaver")
			await c.click_cell(sw.cell)
			c.begin_targeting_index(_index(sw, &"tether"))
			await c.click_cell(bt.cell)
			if shot == "soulweaver":
				battle.hud._tooltip.text = battle.hud._skill_text(sw.skills()[_index(sw, &"dread_diffusion")])
			else:
				await c.click_cell(Vector2i(2, 8))
				c.begin_targeting_index(_index(sw, &"spirit_flare"))
				c.click_cell(Vector2i(6, 8))
				while not battle.hud.prompt.is_open():
					await get_tree().process_frame
				await get_tree().create_timer(0.4).timeout
		"wave", "stoke":
			var kb := _find(battle, &"kindleborne")
			for v: int in [5, 3, 2]:
				kb.heat.append(Card.new(Enums.Tier.SILVER if v < 5 else Enums.Tier.GOLD, v))
			await c.click_cell(kb.cell)
			await c.click_cell(Vector2i(3, 7))
			if shot == "wave":
				c.begin_targeting_index(_index(kb, &"cinder_wave"))
				c._update_hover(Vector2i(4, 7), true)
			else:
				c.begin_targeting_index(_index(kb, &"stoke"))
				while not battle.hud.prompt.is_open():
					await get_tree().process_frame
				await get_tree().create_timer(0.3).timeout
		"enemy":
			# Walk Bloodthane forward, then hand over to the enemies.
			await c.click_cell(Vector2i(4, 7))
			c.request_end_turn()
			await get_tree().create_timer(1.3).timeout
		"hit", "after":
			await c.click_cell(Vector2i(4, 7))
			c.begin_targeting_index(_index(bt, &"bloody_rush"))
			await c.click_cell(Vector2i(5, 7))
			await c.click_cell(Vector2i(6, 7))
			if shot == "hit":
				c.click_cell(Vector2i(7, 7))
				await get_tree().create_timer(0.45).timeout
			else:
				await c.click_cell(Vector2i(7, 7))
				await get_tree().create_timer(0.6).timeout
	await _frames(10 if shot != "hit" else 1)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("Saved ", out)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _find(battle: Battle, id: StringName) -> UnitState:
	for unit in battle.board.units():
		if unit.def.id == id:
			return unit
	return null


func _index(unit: UnitState, id: StringName) -> int:
	for i in unit.skills().size():
		if unit.skills()[i].id == id:
			return i
	return -1
