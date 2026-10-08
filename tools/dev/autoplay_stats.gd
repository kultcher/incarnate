extends Node
## Dev tool: plays 20 AI-vs-AI battles with shuffled Soulstream decks and
## prints outcomes and skill use (a quick balance check). The test arena by
## default; pass "golgothon" for the boss fight, and a count if you like.
##   godot --headless --path . res://tools/dev/autoplay_stats.tscn -- golgothon 10

var _uses: Dictionary = {}


func _ready() -> void:
	var results := {}
	var rounds := 0
	var args := OS.get_cmdline_user_args()
	var scene := "res://battle/battle.tscn"
	if args.has("golgothon"):
		scene = "res://levels/golgothon/golgothon_battle.tscn"
	var n := 20
	for a in args:
		if a.is_valid_int():
			n = a.to_int()
	for i in n:
		var battle: Battle = load(scene).instantiate()
		battle.autoplay = true
		battle.card_seed = i + 1
		Engine.time_scale = 50.0
		add_child(battle)
		await get_tree().process_frame
		EventBus.skill_used.connect(_on_skill)
		var outcome: Enums.Outcome = await battle.battle_controller.battle_ended
		EventBus.skill_used.disconnect(_on_skill)
		var key: String = Enums.Outcome.keys()[outcome]
		results[key] = results.get(key, 0) + 1
		rounds += battle.battle_controller.round_number
		var alive := []
		for u in battle.board.units():
			alive.append("%s %d/%d" % [u.def.display_name, u.hp, u.def.max_hp])
		print("battle %d: %s in %d rounds; left: %s" % [i, key, battle.battle_controller.round_number, ", ".join(alive)])
		battle.queue_free()
		await get_tree().process_frame
	print(results, " avg rounds ", float(rounds) / n)
	print(_uses)
	get_tree().quit(0)


func _on_skill(unit: UnitState, skill: SkillDef) -> void:
	var k := "%s:%s" % [unit.def.display_name, skill.id]
	_uses[k] = _uses.get(k, 0) + 1
