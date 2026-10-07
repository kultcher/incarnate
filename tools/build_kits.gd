extends SceneTree
## Writes the Bloodthane and Traceless kits (2014 version, milestone 5) as
## .tres files: statuses, Pacts, skills, and the units' skill lists.
##   godot --headless --path . --script res://tools/build_kits.gd
## The .tres files are the source of truth once written; edit them in the
## editor. Re-running this overwrites them.
##
## Card values use the tier medians for now (Bronze 2, Silver 3, Gold 4).
## Heroic versions and Talents are not in this pass.

const BR := Enums.Tier.BRONZE
const SI := Enums.Tier.SILVER
const GO := Enums.Tier.GOLD

var _blood_fx: Texture2D
var _shadow_fx: Texture2D
var _hit_sound: AudioStream


func _initialize() -> void:
	_blood_fx = load("res://art/fx/blood_strike.png")
	_shadow_fx = load("res://art/fx/shadow_strike.png")
	_hit_sound = load("res://audio/strike_hit.wav")
	DirAccess.make_dir_recursive_absolute("res://content/statuses/common")
	DirAccess.make_dir_recursive_absolute("res://content/pacts")

	var common := _common_statuses()
	_bloodthane(common)
	_traceless(common)
	_enemies()
	print("build_kits: done")
	quit(0)


#region Helpers

func _icon(name: String) -> Texture2D:
	return load("res://art/icons/%s.png" % name)


func _tiers(list: Array) -> Array[Enums.Tier]:
	var out: Array[Enums.Tier] = []
	for t: int in list:
		out.append(t as Enums.Tier)
	return out


func _save(res: Resource, path: String) -> Resource:
	var err := ResourceSaver.save(res, path)
	assert(err == OK, "Couldn't save %s" % path)
	# Later saves must reference this file, not embed a copy of it.
	res.take_over_path(path)
	return res


func _status(id: StringName, display: String, icon: String, text: String,
		duration: int = 1, clock: Enums.StatusClock = Enums.StatusClock.ROUND) -> StatusDef:
	var s := StatusDef.new()
	s.id = id
	s.display_name = display
	s.icon = _icon(icon)
	s.description = text
	s.duration = duration
	s.clock = clock
	return s


func _step(shape: Enums.TargetShape, filter: Enums.TargetFilter, prompt: String,
		range_max: int = 1, highlight: Enums.Highlight = Enums.Highlight.ATTACK) -> TargetStep:
	var t := TargetStep.new()
	t.shape = shape
	t.filter = filter
	t.range_min = 1
	t.range_max = range_max
	t.highlight = highlight
	t.prompt = prompt
	return t


func _adjacent_foe() -> TargetStep:
	return _step(Enums.TargetShape.ADJACENT, Enums.TargetFilter.ENEMY, "Pick an adjacent foe")


func _own_shadow(prompt: String) -> TargetStep:
	return _step(Enums.TargetShape.WITHIN, Enums.TargetFilter.OWN_SHADOW, prompt, 99,
			Enums.Highlight.SPECIAL)


func _skill(id: StringName, display: String, icon: String, text: String,
		slot: Enums.Slot, cost: Enums.Cost, cooldown: int, tags: Array[StringName],
		targets: Array[TargetStep], effects: Array[EffectDef]) -> SkillDef:
	var s := SkillDef.new()
	s.id = id
	s.display_name = display
	s.icon = _icon(icon)
	s.description = text
	s.slot = slot
	s.cost = cost
	s.cooldown = cooldown
	s.tags = tags
	s.targets = targets
	s.effects = effects
	s.hit_sound = _hit_sound
	return s


func _damage(tiers: Array[Enums.Tier], power: PowerBonus = null) -> DamageEffect:
	var d := DamageEffect.new()
	d.tiers = tiers
	d.power_bonus = power
	return d


func _apply(status: StatusDef, target_step: int = -1) -> ApplyStatusEffect:
	var a := ApplyStatusEffect.new()
	a.status = status
	a.target_step = target_step
	return a

#endregion

#region Common statuses

func _common_statuses() -> Dictionary:
	var dir := "res://content/statuses/common/"
	var provoke := _status(&"provoke", "Provoked", "provoke",
			"Drawn to attack the unit that Provoked it, until end of turn.")
	provoke.tags = [&"taunt", &"debuff"]
	_save(provoke, dir + "provoke.tres")

	var cripple := _status(&"cripple", "Crippled", "cripple",
			"-2 move until it next moves (or until end of turn).")
	cripple.tags = [&"debuff", &"end_on_move"]
	cripple.stat_mods = { &"move": -2 }
	_save(cripple, dir + "cripple.tres")

	var blind := _status(&"blind", "Blinded", "blind",
			"Its next strike counts as dodged: it loses its lowest card, or grazes for 1.")
	blind.tags = [&"debuff", &"blind"]
	_save(blind, dir + "blind.tres")
	return { "provoke": provoke, "cripple": cripple, "blind": blind }

#endregion

#region Bloodthane

func _bloodthane(common: Dictionary) -> void:
	var sdir := "res://content/statuses/bloodthane/"
	var kdir := "res://content/skills/bloodthane/"

	# --- Statuses ---
	var dominance_armor := _status(&"dominance_armor", "Dominance", "armor_up",
			"+1 Armor until end of turn.")
	dominance_armor.stat_mods = { &"armor": 1 }
	_save(dominance_armor, sdir + "dominance_armor.tres")

	var rush_armor := _status(&"bloody_rush_armor", "Bloody Rush", "armor_up",
			"+1 Armor until end of turn.")
	rush_armor.stat_mods = { &"armor": 1 }
	_save(rush_armor, sdir + "bloody_rush_armor.tres")

	var coagulant_behavior := AcuteCoagulantBehavior.new()
	coagulant_behavior.tiers = _tiers([BR])
	var coagulant := _status(&"acute_coagulant", "Acute Coagulant", "acute_coagulant",
			"Heals {tick} at the end of each turn, and whenever struck for {threshold} or more.", 2)
	coagulant.behavior = coagulant_behavior
	_save(coagulant, sdir + "acute_coagulant.tres")

	var adrenal := _status(&"adrenal", "Adrenal Surge", "adrenal_surge",
			"The next standard skill used this turn isn't exhausted.")
	adrenal.tags = [&"no_cooldown_next"]
	_save(adrenal, sdir + "adrenal.tres")

	var bloodrage_status := _status(&"bloodrage", "Bloodrage", "bloodrage",
			"Strikes get +1 Power per stack until end of turn.")
	bloodrage_status.stat_mods = { &"strike_power": 1 }
	bloodrage_status.max_stacks = 99
	_save(bloodrage_status, sdir + "bloodrage.tres")

	# --- Pacts (2014: one-shot, each once per turn) ---
	var dominance := PactDef.new()
	dominance.display_name = "Dominance Pact"
	dominance.icon = _icon("dominance_pact")
	dominance.description = "Provoke the foe until end of turn. You gain +1 Armor until end of turn."
	dominance.foe_status = common["provoke"]
	dominance.self_status = dominance_armor
	_save(dominance, "res://content/pacts/dominance.tres")

	var vampiric := PactDef.new()
	vampiric.display_name = "Vampiric Pact"
	vampiric.icon = _icon("vampiric_pact")
	vampiric.description = "The foe loses 1 health and you heal 1."
	vampiric.foe_health_loss = 1
	vampiric.self_heal = 1
	_save(vampiric, "res://content/pacts/vampiric.tres")

	var predation := PactDef.new()
	predation.display_name = "Predation Pact"
	predation.icon = _icon("predation_pact")
	predation.description = "Cripple the foe (-2 move until it next moves). Then you may shift 1 square."
	predation.foe_status = common["cripple"]
	predation.self_shift = 1
	_save(predation, "res://content/pacts/predation.tres")

	var bib_behavior := BoundInBloodBehavior.new()
	bib_behavior.pacts = [dominance, vampiric, predation]
	bib_behavior.ai_choice = 1
	var bib := _status(&"bound_in_blood", "Bound in Blood", "bound_in_blood",
			"Passive. When you strike a foe you've already struck this turn, you may bind a Pact to it. " \
			+ "Each Pact can be bound once per turn. (Stands in for the 2014 trigger, a Blade card " \
			+ "unveiled on the strike, until the Soulstream has suits.)", 0, Enums.StatusClock.OWNER_TURN)
	bib.behavior = bib_behavior
	bib.tags = [&"passive"]
	bib.show_on_unit = false
	_save(bib, sdir + "bound_in_blood.tres")

	# --- Skills ---
	var blade_fury := _skill(&"blade_fury", "Blade Fury", "blade_fury",
			"Strike an adjacent foe for {damage}. Right after a move action, +1 Power for every " \
			+ "{per_squares} squares you've moved toward that foe this turn.",
			Enums.Slot.BASIC, Enums.Cost.SKILL, 0, [&"attack", &"melee"],
			[_adjacent_foe()], [_damage(_tiers([BR, BR]), MovedTowardBonus.new())])
	blade_fury.hit_fx = _blood_fx
	_save(blade_fury, kdir + "blade_fury.tres")

	var rending := _skill(&"rending_claws", "Rending Claws", "rending_claws",
			"Strike an adjacent foe for {damage}, with +1 Power for every {per_damage} damage " \
			+ "you've already dealt this turn.",
			Enums.Slot.ATTACK, Enums.Cost.SKILL, 2, [&"attack", &"melee"],
			[_adjacent_foe()], [_damage(_tiers([SI, SI]), DamageDealtBonus.new())])
	rending.hit_fx = _blood_fx
	_save(rending, kdir + "rending_claws.tres")

	var rage := _skill(&"rage_strike", "Rage Strike", "rage_strike",
			"Strike an adjacent foe for {damage}. Whenever a foe strikes you, Rage Strike " \
			+ "recharges by 1.",
			Enums.Slot.ATTACK, Enums.Cost.SKILL, 3, [&"attack", &"melee"],
			[_adjacent_foe()], [_damage(_tiers([GO, SI]))])
	rage.recharge_when_struck = true
	rage.hit_fx = _blood_fx
	_save(rage, kdir + "rage_strike.tres")

	var rush_effect := PathStrikeEffect.new()
	rush_effect.tiers = _tiers([SI])
	rush_effect.include_adjacent = true
	rush_effect.reward_threshold = 3
	rush_effect.reward_status = rush_armor
	var rush := _skill(&"bloody_rush", "Bloody Rush", "bloody_rush",
			"Shift up to 3 squares, through foes if you like. Strike each foe you shift through " \
			+ "or next to for {damage}. If you strike at least {threshold}, +1 Armor until end of turn.",
			Enums.Slot.AREA, Enums.Cost.SKILL, 3, [&"attack", &"area"], [], [rush_effect])
	rush.path = PathSpec.new()
	rush.path.budget = 3
	rush.path.prompt = "Click out up to 3 squares"
	rush.hit_fx = _blood_fx
	_save(rush, kdir + "bloody_rush.tres")

	var heal := HealEffect.new()
	heal.tiers = _tiers([SI])
	var coagulant_skill := _skill(&"acute_coagulant", "Acute Coagulant", "acute_coagulant",
			"Heal yourself for {heal}. For 2 turns, heal {tick} at the end of each turn and " \
			+ "whenever you're struck for {threshold} or more.",
			Enums.Slot.DEFENSE, Enums.Cost.SKILL, 1, [&"heal"], [], [heal, _apply(coagulant)])
	_save(coagulant_skill, kdir + "acute_coagulant.tres")

	var verve := _skill(&"verve_magnet", "Verve Magnet", "verve_magnet",
			"Maneuver. You and a unit within 5 squares are each forced {squares} squares toward " \
			+ "or away from each other. Each forced ally heals {amount}; each forced foe loses " \
			+ "{amount} health.",
			Enums.Slot.MOBILITY, Enums.Cost.MOVE, 3, [&"maneuver"],
			[_step(Enums.TargetShape.WITHIN, Enums.TargetFilter.UNIT, "Pick a unit within 5", 5,
					Enums.Highlight.SPECIAL)],
			[VerveMagnetEffect.new()])
	_save(verve, kdir + "verve_magnet.tres")

	var gain := GainActionEffect.new()
	gain.target_step = 0
	var adrenal_skill := _skill(&"adrenal_surge", "Adrenal Surge", "adrenal_surge",
			"An ally within 4 squares refreshes a skill and gains a skill action. The next " \
			+ "standard skill they use this turn isn't exhausted.",
			Enums.Slot.UTILITY, Enums.Cost.SKILL, 4, [&"utility"],
			[_step(Enums.TargetShape.WITHIN, Enums.TargetFilter.ALLY, "Pick an ally within 4", 4,
					Enums.Highlight.AID)],
			[RefreshSkillEffect.new(), gain, _apply(adrenal, 0)])
	_save(adrenal_skill, kdir + "adrenal_surge.tres")

	var transfusion := _skill(&"violent_transfusion", "Violent Transfusion", "violent_transfusion",
			"A foe within 5 squares loses {loss} health. An ally within 5 (you included) heals " \
			+ "that much, +{kill_bonus} if the foe died.",
			Enums.Slot.RECOVERY, Enums.Cost.SKILL, 0, [&"recovery"],
			[_step(Enums.TargetShape.WITHIN, Enums.TargetFilter.ENEMY, "Pick a foe within 5", 5),
			_step(Enums.TargetShape.WITHIN, Enums.TargetFilter.ALLY_OR_SELF,
					"Pick who heals (within 5, you included)", 5, Enums.Highlight.AID)],
			[TransfusionEffect.new()])
	transfusion.targets[1].range_min = 0
	_save(transfusion, kdir + "violent_transfusion.tres")

	var rage_effect := BloodrageEffect.new()
	rage_effect.status = bloodrage_status
	var bloodrage := _skill(&"bloodrage", "Bloodrage", "bloodrage",
			"Ultimate. Gain a skill action. Until end of turn, your strikes get +X Power, where X " \
			+ "is the damage you've dealt so far this turn.",
			Enums.Slot.ULTIMATE, Enums.Cost.FREE, 0, [&"ultimate"], [], [rage_effect])
	bloodrage.uses_per_battle = 1
	_save(bloodrage, kdir + "bloodrage.tres")

	var unit: UnitDef = load("res://content/units/bloodthane.tres")
	unit.skills = [blade_fury, rending, rage, rush, coagulant_skill, verve, adrenal_skill,
			transfusion, bloodrage]
	unit.passives = [bib]
	_save(unit, unit.resource_path)

#endregion

#region Traceless

func _traceless(common: Dictionary) -> void:
	var sdir := "res://content/statuses/traceless/"
	var kdir := "res://content/skills/traceless/"

	# --- Statuses ---
	var shadows_behavior := IllusiveShadowsBehavior.new()
	var shadows := _status(&"illusive_shadows", "Illusive Shadows", "illusive_shadows",
			"Passive. Shifting out of a square leaves a Shadow there (at most {max}; a new one " \
			+ "replaces the oldest). Shadows don't block anything and can't be struck.\n" \
			+ "Shadowstrike: after you use an attack, one Shadow may copy it, then fades.\n" \
			+ "Probability Armor: +1 Evasion (a dodge per round) for each Shadow.",
			0, Enums.StatusClock.OWNER_TURN)
	shadows.behavior = shadows_behavior
	shadows.tags = [&"passive"]
	shadows.show_on_unit = false
	_save(shadows, sdir + "illusive_shadows.tres")

	var cloak := _status(&"chimeric_cloak", "Chimeric Cloak", "chimeric_cloak",
			"Prepared. You may negate the next strike or harmful status from a foe this turn.")
	cloak.behavior = ChimericCloakBehavior.new()
	_save(cloak, sdir + "chimeric_cloak.tres")

	var mirage := _status(&"mirage", "Mirage", "mirage_shift",
			"Until end of turn, you may swap places with a Shadow as a free action.")
	_save(mirage, sdir + "mirage.tres")

	var distorted := _status(&"distorted", "Distorted", "tactical_distortion",
			"Once this turn, the Traceless may change the target of one of its skills.")
	distorted.behavior = TacticalDistortionBehavior.new()
	distorted.tags = [&"debuff"]
	_save(distorted, sdir + "distorted.tres")

	var decoy_behavior := PerfectDecoyBehavior.new()
	var decoy := _status(&"perfect_decoy", "Perfect Decoy", "perfect_decoy",
			"The first time this turn a foe's strike would bring a protected ally below 1 health, " \
			+ "it's prevented and the ally heals {heal}.")
	decoy.behavior = decoy_behavior
	_save(decoy, sdir + "perfect_decoy.tres")

	var storm := _status(&"shadowstorm", "Shadowstorm", "shadowstorm",
			"Any number of Shadows can copy each attack until end of turn.")
	_save(storm, sdir + "shadowstorm.tres")

	# --- Skills ---
	var displacer_effect := ShiftStrikeEffect.new()
	displacer_effect.tiers = _tiers([SI])
	var foe_step := TargetStep.new()
	foe_step.rule = ShiftStrikeRule.new()
	foe_step.prompt = "Pick a foe to strike (in reach before or after the shift)"
	var dest_step := TargetStep.new()
	dest_step.rule = foe_step.rule
	dest_step.highlight = Enums.Highlight.MOVE
	dest_step.prompt = "Pick where to shift"
	var displacer := _skill(&"displacer_strike", "Displacer Strike", "displacer_strike",
			"Shift up to {shift} squares, through foes if you like. Before or after the shift, " \
			+ "strike an adjacent foe for {damage}. A Shadow copying it reaches 2 squares further. " \
			+ "(Pick your own square to strike without moving.)",
			Enums.Slot.BASIC, Enums.Cost.SKILL, 0, [&"attack", &"melee"],
			[foe_step, dest_step], [displacer_effect])
	displacer.copy_range = 5
	displacer.copy_tiers = _tiers([SI])
	displacer.hit_fx = _shadow_fx
	_save(displacer, kdir + "displacer_strike.tres")

	var shadowstep := _skill(&"shadowstep", "Shadowstep", "shadowstep",
			"Free. Teleport to one of your Shadows. The Shadow is used up.",
			Enums.Slot.BASIC, Enums.Cost.FREE, 0, [&"teleport"],
			[_own_shadow("Pick one of your Shadows")], [ShadowJumpEffect.new()])
	_save(shadowstep, kdir + "shadowstep.tres")

	var gloom := _skill(&"gloom_edge", "Gloom Edge", "gloom_edge",
			"Strike an adjacent foe for {damage}. A foe struck by a Shadow copying this is Blinded " \
			+ "(its next strike counts as dodged).",
			Enums.Slot.ATTACK, Enums.Cost.SKILL, 2, [&"attack", &"melee"],
			[_adjacent_foe()], [_damage(_tiers([SI, SI]))])
	gloom.copy_range = 1
	gloom.copy_tiers = _tiers([SI, SI])
	gloom.copy_status = common["blind"]
	gloom.hit_fx = _shadow_fx
	_save(gloom, kdir + "gloom_edge.tres")

	var dash_effect := PathStrikeEffect.new()
	dash_effect.tiers = _tiers([SI])
	var dash := _skill(&"phantom_dash", "Phantom Dash", "phantom_dash",
			"Shift 2 squares, plus 2 more for each foe you shift through. Then strike each foe you " \
			+ "shifted through for {damage}.",
			Enums.Slot.AREA, Enums.Cost.SKILL, 3, [&"attack", &"area"], [], [dash_effect])
	dash.path = PathSpec.new()
	dash.path.budget = 2
	dash.path.extend_per_foe = 2
	dash.path.prompt = "Click out the dash (each foe you pass through adds 2 squares)"
	dash.copy_range = 3
	dash.copy_tiers = _tiers([SI])
	dash.hit_fx = _shadow_fx
	_save(dash, kdir + "phantom_dash.tres")

	var cloak_skill := _skill(&"chimeric_cloak", "Chimeric Cloak", "chimeric_cloak",
			"Prepare. Until end of turn, you may negate the next strike or harmful status a foe " \
			+ "aims at you. (Health loss isn't covered yet.)",
			Enums.Slot.DEFENSE, Enums.Cost.SKILL, 3, [&"prepare"], [], [_apply(cloak)])
	_save(cloak_skill, kdir + "chimeric_cloak.tres")

	var place := PlaceShadowEffect.new()
	var mirage_skill := _skill(&"mirage_shift", "Mirage Shift", "mirage_shift",
			"Maneuver. Put a Shadow on an empty square within 6. Until end of turn, you may swap " \
			+ "places with a Shadow as a free action (Shadow Swap).",
			Enums.Slot.MOBILITY, Enums.Cost.MOVE, 3, [&"maneuver"],
			[_step(Enums.TargetShape.WITHIN, Enums.TargetFilter.EMPTY, "Pick an empty square within 6",
					6, Enums.Highlight.SPECIAL)],
			[place, _apply(mirage)])
	_save(mirage_skill, kdir + "mirage_shift.tres")

	var swap_effect := ShadowJumpEffect.new()
	swap_effect.consume = false
	var swap := _skill(&"shadow_swap", "Shadow Swap", "shadow_swap",
			"Free, after Mirage Shift this turn. Swap places with one of your Shadows. The Shadow " \
			+ "stays.",
			Enums.Slot.MOBILITY, Enums.Cost.FREE, 0, [&"teleport"],
			[_own_shadow("Pick a Shadow to swap with")], [swap_effect])
	swap.requires_status = &"mirage"
	_save(swap, kdir + "shadow_swap.tres")

	var distortion := _skill(&"tactical_distortion", "Tactical Distortion", "tactical_distortion",
			"Free. Choose a foe within 4. Once this turn, when it uses a skill, you may change its " \
			+ "target to another valid target.",
			Enums.Slot.UTILITY, Enums.Cost.FREE, 3, [&"utility"],
			[_step(Enums.TargetShape.WITHIN, Enums.TargetFilter.ENEMY, "Pick a foe within 4", 4,
					Enums.Highlight.SPECIAL)],
			[_apply(distorted, 0)])
	(distortion.effects[0] as ApplyStatusEffect).link_caster = true
	_save(distortion, kdir + "tactical_distortion.tres")

	var decoy_effect := StatusToAlliesEffect.new()
	decoy_effect.status = decoy
	var decoy_skill := _skill(&"perfect_decoy", "Perfect Decoy", "perfect_decoy",
			"Free. Until end of turn, the first time a foe's strike would bring an ally (you " \
			+ "included) below 1 health, it's prevented and they heal {heal}. (The 4-square " \
			+ "teleport isn't in yet.)",
			Enums.Slot.RECOVERY, Enums.Cost.FREE, 0, [&"recovery"], [], [decoy_effect])
	_save(decoy_skill, kdir + "perfect_decoy.tres")

	var storm_effect := ShadowstormEffect.new()
	storm_effect.status = storm
	var storm_targets: Array[TargetStep] = []
	for i in 3:
		var t := _step(Enums.TargetShape.WITHIN, Enums.TargetFilter.EMPTY,
				"Pick a square for Shadow %d of 3" % (i + 1), 99, Enums.Highlight.SPECIAL)
		t.unique = true
		storm_targets.append(t)
	var storm_skill := _skill(&"shadowstorm", "Shadowstorm", "shadowstorm",
			"Ultimate. Free. Put your Shadows on any 3 empty squares (new ones fill any gaps). " \
			+ "Until end of turn, any number of Shadows can copy each attack.",
			Enums.Slot.ULTIMATE, Enums.Cost.FREE, 0, [&"ultimate"], storm_targets, [storm_effect])
	storm_skill.uses_per_battle = 1
	_save(storm_skill, kdir + "shadowstorm.tres")

	var unit: UnitDef = load("res://content/units/traceless.tres")
	unit.skills = [displacer, shadowstep, gloom, dash, cloak_skill, mirage_skill, swap,
			distortion, decoy_skill, storm_skill]
	unit.passives = [shadows]
	_save(unit, unit.resource_path)

#endregion

#region Enemies and placeholders

func _enemies() -> void:
	var claw: SkillDef = load("res://content/skills/shambler/claw.tres")
	claw.description = "Rake an adjacent foe for {damage}."
	claw.tags = [&"attack", &"melee"]
	claw.effects = [_damage(_tiers([SI]))]
	_save(claw, claw.resource_path)

	var strike: SkillDef = load("res://content/skills/common/strike.tres")
	strike.description = "Strike an adjacent foe for {damage}. (Placeholder until the kit is ported.)"
	strike.tags = [&"attack", &"melee"]
	strike.effects = [_damage(_tiers([SI]))]
	_save(strike, strike.resource_path)

#endregion
