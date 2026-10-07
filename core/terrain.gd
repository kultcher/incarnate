class_name Terrain
extends RefCounted
## What a single cell is made of. Read once from the level's TileMapLayers.

var blocks_move: bool = false
var move_cost: int = 1


func _init(p_blocks_move: bool = false, p_move_cost: int = 1) -> void:
	blocks_move = p_blocks_move
	move_cost = maxi(p_move_cost, 1)
