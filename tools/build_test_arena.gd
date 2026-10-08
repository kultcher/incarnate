extends SceneTree
## Generates the terrain and highlight tilesets and the test arena scene.
## Run from the project folder:
##   godot --headless --path . --script res://tools/build_test_arena.gd
## After the first run, edit the arena in the editor like any scene; only
## re-run this if you want to regenerate it from scratch.

const TILE := Vector2i(64, 64)
const BOARD := Vector2i(12, 10)

# Atlas coordinates on art/tiles/terrain_sheet.png.
const GRASS_LEFT := 21
const GRASS_MID := 22
const GRASS_RIGHT := 23
const GRASS_TOP := 13
const GRASS_CENTER := 14
const GRASS_BOTTOM := 15
const BUSH := Vector2i(20, 6)

const TERRAIN_TILESET_PATH := "res://art/tiles/terrain_tileset.tres"
const HIGHLIGHT_TILESET_PATH := "res://art/tiles/highlight_tileset.tres"
const ARENA_PATH := "res://levels/test_arena.tscn"

const OBSTACLES: Array[Vector2i] = [
	# A wall the player has to walk around.
	Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5), Vector2i(5, 6),
	# Scattered cover.
	Vector2i(2, 2), Vector2i(8, 7), Vector2i(9, 2), Vector2i(3, 5),
]


func _initialize() -> void:
	var terrain := _build_terrain_tileset()
	var highlight := _build_highlight_tileset()
	_check(ResourceSaver.save(terrain, TERRAIN_TILESET_PATH), TERRAIN_TILESET_PATH)
	_check(ResourceSaver.save(highlight, HIGHLIGHT_TILESET_PATH), HIGHLIGHT_TILESET_PATH)
	terrain = load(TERRAIN_TILESET_PATH)
	highlight = load(HIGHLIGHT_TILESET_PATH)
	_build_arena(terrain, highlight)
	quit()


func _check(err: Error, path: String) -> void:
	if err != OK:
		push_error("Failed to save %s: %s" % [path, error_string(err)])
	else:
		print("Saved ", path)


func _build_terrain_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = TILE
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "blocks_move")
	ts.set_custom_data_layer_type(0, TYPE_BOOL)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(1, "move_cost")
	ts.set_custom_data_layer_type(1, TYPE_INT)

	var src := TileSetAtlasSource.new()
	src.texture = load("res://art/tiles/terrain_sheet.png")
	src.texture_region_size = TILE
	ts.add_source(src, 0)
	for x: int in [GRASS_LEFT, GRASS_MID, GRASS_RIGHT]:
		for y: int in [GRASS_TOP, GRASS_CENTER, GRASS_BOTTOM]:
			_add_tile(src, Vector2i(x, y), false, 1)
	_add_tile(src, BUSH, true, 1)
	return ts


func _add_tile(src: TileSetAtlasSource, coords: Vector2i, blocks: bool, cost: int) -> void:
	src.create_tile(coords)
	var data := src.get_tile_data(coords, 0)
	data.set_custom_data("blocks_move", blocks)
	data.set_custom_data("move_cost", cost)


func _build_highlight_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = TILE
	var src := TileSetAtlasSource.new()
	src.texture = load("res://art/tiles/highlights.png")
	src.texture_region_size = TILE
	ts.add_source(src, 0)
	for i in Enums.Highlight.size():
		src.create_tile(Vector2i(i, 0))
	return ts


func _build_arena(terrain: TileSet, highlight: TileSet) -> void:
	var arena := Node2D.new()
	arena.name = "Arena"
	arena.set_script(load("res://view/board_view.gd"))

	var ground := _layer("Ground", terrain, arena)
	var grid := _layer("Grid", highlight, arena)
	var highlights := _layer("Highlights", highlight, arena)
	var obstacles := _layer("Obstacles", terrain, arena)
	var overlay := _layer("Overlay", highlight, arena)
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
	for cell in OBSTACLES:
		obstacles.set_cell(cell, 0, BUSH)

	_spawn(spawns, arena, "Bloodthane", "res://content/units/bloodthane.tres", Vector2i(2, 7), Enums.Team.PLAYER)
	_spawn(spawns, arena, "Traceless", "res://content/units/traceless.tres", Vector2i(3, 8), Enums.Team.PLAYER)
	_spawn(spawns, arena, "Soulweaver", "res://content/units/soulweaver.tres", Vector2i(1, 8), Enums.Team.PLAYER)
	_spawn(spawns, arena, "Kindleborne", "res://content/units/kindleborne.tres", Vector2i(1, 7), Enums.Team.PLAYER)
	_spawn(spawns, arena, "Shambler1", "res://content/units/monster_a.tres", Vector2i(6, 6), Enums.Team.ENEMY)
	_spawn(spawns, arena, "Shambler2", "res://content/units/monster_a.tres", Vector2i(6, 8), Enums.Team.ENEMY)
	_spawn(spawns, arena, "Shambler3", "res://content/units/monster_a.tres", Vector2i(9, 4), Enums.Team.ENEMY)

	var packed := PackedScene.new()
	_check(packed.pack(arena), "pack arena")
	_check(ResourceSaver.save(packed, ARENA_PATH), ARENA_PATH)
	arena.free()


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
