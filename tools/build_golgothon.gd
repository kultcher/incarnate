extends SceneTree
## Writes the Golgothon encounter: statuses, the boss and minion units, the
## 10x10 arena with its Encounter node, and the battle scene that loads it.
##   godot --headless --path . --script res://tools/build_golgothon.gd
## The files are the source of truth once written; re-running overwrites them.
## Numbers are translated from the 2013 booklet and the 2014 cards; see
## references/golgothon-reference.md.

const TILE := Vector2i(64, 64)
const BOARD := Vector2i(10, 10)
const GRASS_LEFT := 21
const GRASS_MID := 22
const GRASS_RIGHT := 23
const GRASS_TOP := 13
const GRASS_CENTER := 14
const GRASS_BOTTOM := 15

const SDIR := "res://content/statuses/golgothon/"
const ARENA_PATH := "res://levels/golgothon/golgothon_arena.tscn"
const BATTLE_PATH := "res://levels/golgothon/golgothon_battle.tscn"

## Health, on the 40-health Incarnate scale of the booklets (and of the 2014
## cards' numbers). The booklet says 450; 300 is a first pass from autoplay
## runs (the AI wins about 4 in 10, in about 7 rounds).
const BOSS_HP := 300
## The booklet's 8 made minions take two strikes; 5 keeps them one-hit kills.
const MINION_HP := 5


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(SDIR)
	var defs := _content()
	_arena(defs)
	_battle_scene()
	print("build_golgothon: done")
	quit(0)


func _icon(icon_name: String) -> Texture2D:
	return load("res://art/icons/%s.png" % icon_name)


func _save(res: Resource, path: String) -> Resource:
	var err := ResourceSaver.save(res, path)
	assert(err == OK, "Couldn't save %s" % path)
	res.take_over_path(path)
	return res


func _status(id: StringName, display: String, icon: String, text: String) -> StatusDef:
	var s := StatusDef.new()
	s.id = id
	s.display_name = display
	s.icon = _icon(icon)
	s.description = text
	s.duration = 0
	return s


func _content() -> Dictionary:
	var daze := _status(&"daze", "Dazed", "grave_smash",
			"Its next recharge doesn't happen (cooldowns don't tick at the start of its next turn).")
	daze.tags = [&"daze", &"debuff"]
	daze.stacking = Enums.Stacking.ADD
	daze.max_stacks = 9
	_save(daze, "res://content/statuses/common/daze.tres")

	var unquenched := _status(&"unquenched", "Unquenched", "unquenched",
			"+1 Power per stack. His Welcoming Dead move 1 square and strike +1 per stack.")
	unquenched.stacking = Enums.Stacking.ADD
	unquenched.max_stacks = 99
	unquenched.stat_mods = { &"power": 1 }
	_save(unquenched, SDIR + "unquenched.tres")

	var traits_behavior := GolgothonTraitsBehavior.new()
	var traits := _status(&"golgothon_traits", "Graveyard Elemental", "deaths_grasp",
			"Large (2x2). Resolve {resolve}: a debuff only takes hold on its {resolve}nd application. " \
			+ "Sturdy 1: forced movement against him is 1 square shorter. Trample: he walks " \
			+ "through units, pushing them aside.")
	traits.behavior = traits_behavior
	traits.tags = [&"passive"]
	traits.show_on_unit = false
	_save(traits, SDIR + "golgothon_traits.tres")

	var drag := _status(&"drag_you_down", "Drag You Down", "welcoming_dead",
			"While 2 or more Welcoming Dead are next to an Incarnate, it can't walk or shift " \
			+ "(teleports still work).")
	drag.tags = [&"grapple", &"passive"]
	drag.show_on_unit = false
	_save(drag, SDIR + "drag_you_down.tres")

	var restless_behavior := RestlessBehavior.new()
	restless_behavior.mark_icon = _icon("restless_dead")
	var restless := _status(&"restless", "Restless", "restless_dead",
			"When slain, leaves a gravestone. Golgothon's Unquenched raises it again.")
	restless.behavior = restless_behavior
	restless.tags = [&"passive"]
	restless.show_on_unit = false
	_save(restless, SDIR + "restless.tres")

	var boss := UnitDef.new()
	boss.id = &"golgothon"
	boss.display_name = "Golgothon"
	boss.max_hp = BOSS_HP
	boss.move = 4
	boss.footprint = 2
	boss.sturdy = 1
	boss.flex_points = 0
	boss.sheet = load("res://art/units/golgothon.png")
	boss.sheet_columns = 1
	boss.idle_column = 0
	boss.sheet_rows = [&"down"]
	boss.display_height = 150.0
	boss.passives = [traits]
	_save(boss, "res://content/units/golgothon.tres")

	var shambler: UnitDef = load("res://content/units/monster_a.tres")
	var minion := UnitDef.new()
	minion.id = &"welcoming_dead"
	minion.display_name = "Welcoming Dead"
	minion.report_as_group = true
	minion.max_hp = MINION_HP
	minion.move = 0
	minion.flex_points = 0
	minion.sheet = shambler.sheet
	minion.sheet_columns = shambler.sheet_columns
	minion.idle_column = shambler.idle_column
	minion.sheet_rows = shambler.sheet_rows
	minion.display_height = shambler.display_height
	minion.passives = [drag, restless]
	_save(minion, "res://content/units/welcoming_dead.tres")

	return { "boss": boss, "minion": minion, "daze": daze, "unquenched": unquenched }


func _arena(defs: Dictionary) -> void:
	var terrain: TileSet = load("res://art/tiles/terrain_tileset.tres")
	var highlight: TileSet = load("res://art/tiles/highlight_tileset.tres")
	var arena := Node2D.new()
	arena.name = "GolgothonArena"
	arena.set_script(load("res://view/board_view.gd"))
	var ground := _layer("Ground", terrain, arena)
	var grid := _layer("Grid", highlight, arena)
	var highlights := _layer("Highlights", highlight, arena)
	_layer("Obstacles", terrain, arena)
	_layer("Overlay", highlight, arena)
	var units := Node2D.new()
	units.name = "Units"
	units.y_sort_enabled = true
	arena.add_child(units)
	units.owner = arena
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	arena.add_child(spawns)
	spawns.owner = arena
	highlights.modulate = Color(1, 1, 1, 0.9)
	for y in BOARD.y:
		for x in BOARD.x:
			var ax := GRASS_LEFT if x == 0 else (GRASS_RIGHT if x == BOARD.x - 1 else GRASS_MID)
			var ay := GRASS_TOP if y == 0 else (GRASS_BOTTOM if y == BOARD.y - 1 else GRASS_CENTER)
			ground.set_cell(Vector2i(x, y), 0, Vector2i(ax, ay))
			grid.set_cell(Vector2i(x, y), 0, Vector2i(Enums.Highlight.GRID, 0))

	# Booklet setup: Golgothon top centre, the Incarnates in the bottom rows.
	_spawn(spawns, arena, "Golgothon", "res://content/units/golgothon.tres", Vector2i(4, 1), Enums.Team.ENEMY)
	_spawn(spawns, arena, "Bloodthane", "res://content/units/bloodthane.tres", Vector2i(4, 7), Enums.Team.PLAYER)
	_spawn(spawns, arena, "Traceless", "res://content/units/traceless.tres", Vector2i(5, 7), Enums.Team.PLAYER)
	_spawn(spawns, arena, "Soulweaver", "res://content/units/soulweaver.tres", Vector2i(3, 8), Enums.Team.PLAYER)
	_spawn(spawns, arena, "Kindleborne", "res://content/units/kindleborne.tres", Vector2i(6, 8), Enums.Team.PLAYER)

	var encounter := Node.new()
	encounter.name = "Encounter"
	encounter.set_script(load("res://levels/golgothon/golgothon_encounter.gd"))
	encounter.set("minion_def", defs["minion"])
	encounter.set("unquenched_status", defs["unquenched"])
	encounter.set("daze_status", defs["daze"])
	encounter.set("mark_icon", _icon("restless_dead"))
	encounter.set("grasp_icon", _icon("deaths_grasp"))
	encounter.set("caress_icon", _icon("deaths_caress"))
	encounter.set("unquenched_icon", _icon("unquenched"))
	encounter.set("smash_icon", _icon("grave_smash"))
	encounter.set("spew_icon", _icon("carrion_spew"))
	encounter.set("summon_icon", _icon("welcoming_dead"))
	arena.add_child(encounter)
	encounter.owner = arena

	var packed := PackedScene.new()
	assert(packed.pack(arena) == OK)
	_save(packed, ARENA_PATH)
	arena.free()


func _battle_scene() -> void:
	var text := """[gd_scene format=3]

[ext_resource type="PackedScene" path="res://battle/battle.tscn" id="1_battle"]
[ext_resource type="PackedScene" path="%s" id="2_level"]

[node name="Battle" instance=ExtResource("1_battle")]
level_scene = ExtResource("2_level")
""" % ARENA_PATH
	var f := FileAccess.open(BATTLE_PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _layer(layer_name: String, ts: TileSet, parent: Node) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = ts
	parent.add_child(layer)
	layer.owner = parent
	return layer


func _spawn(parent: Node, owner_node: Node, spawn_name: String, def_path: String,
		cell: Vector2i, team: Enums.Team) -> void:
	var s := Marker2D.new()
	s.set_script(load("res://battle/unit_spawn.gd"))
	s.name = spawn_name
	s.set("def", load(def_path))
	s.set("team", team)
	s.position = Vector2(cell * TILE) + Vector2(TILE) / 2.0
	parent.add_child(s)
	s.owner = owner_node
