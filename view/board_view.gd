class_name BoardView
extends Node2D
## Draws the board: terrain layers, range highlights, the hover path.
## Converts between cells and positions. Holds no game state.

@onready var ground: TileMapLayer = $Ground
@onready var obstacles: TileMapLayer = $Obstacles
@onready var highlights: TileMapLayer = $Highlights
@onready var overlay: TileMapLayer = $Overlay
@onready var units_root: Node2D = $Units
@onready var spawns_root: Node2D = $Spawns

const HIGHLIGHT_SOURCE := 0

var pick_marks: PickMarks
var shadows: ShadowLayer


func _ready() -> void:
	pick_marks = PickMarks.new()
	pick_marks.name = "PickMarks"
	pick_marks.board_view = self
	pick_marks.z_index = 10
	add_child(pick_marks)
	shadows = ShadowLayer.new()
	shadows.name = "Shadows"
	shadows.board_view = self
	add_child(shadows)


func cell_to_local(cell: Vector2i) -> Vector2:
	return ground.map_to_local(cell)


func local_to_cell(local_pos: Vector2) -> Vector2i:
	return ground.local_to_map(local_pos)


func mouse_cell() -> Vector2i:
	return local_to_cell(get_local_mouse_position())


## Board size in pixels, from the ground layer.
func pixel_rect() -> Rect2:
	var used := ground.get_used_rect()
	var tile := Vector2(ground.tile_set.tile_size)
	return Rect2(Vector2(used.position) * tile, Vector2(used.size) * tile)


func show_cells(cells: Array[Vector2i], kind: Enums.Highlight) -> void:
	highlights.clear()
	for cell in cells:
		highlights.set_cell(cell, HIGHLIGHT_SOURCE, Vector2i(kind, 0))


func clear_highlights() -> void:
	highlights.clear()
	overlay.clear()
	pick_marks.clear()


func show_path(path: Array[Vector2i], hover_cell: Vector2i) -> void:
	overlay.clear()
	for cell in path:
		overlay.set_cell(cell, HIGHLIGHT_SOURCE, Vector2i(Enums.Highlight.PATH, 0))
	overlay.set_cell(hover_cell, HIGHLIGHT_SOURCE, Vector2i(Enums.Highlight.HOVER, 0))


func show_hover(cell: Vector2i) -> void:
	overlay.clear()
	if ground.get_cell_source_id(cell) != -1:
		overlay.set_cell(cell, HIGHLIGHT_SOURCE, Vector2i(Enums.Highlight.HOVER, 0))
