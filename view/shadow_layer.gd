class_name ShadowLayer
extends Node
## Draws each unit's Shadows (the Traceless's) as translucent copies of its
## sprite. Holds no rules: the Presenter hands it the cells to show.

var board_view: BoardView
## Ghost sprites by owner unit id, then by cell.
var _ghosts: Dictionary[int, Dictionary] = {}


## Shows [param owner]'s Shadows on exactly [param cells].
func set_shadows(owner: UnitState, owner_view: UnitView, cells: Array[Vector2i]) -> void:
	var current: Dictionary = _ghosts.get(owner.id, {})
	for cell: Vector2i in current.keys():
		if not cells.has(cell):
			var gone: Sprite2D = current[cell]
			current.erase(cell)
			_fade_out(gone)
	for cell in cells:
		if current.has(cell) or owner_view == null:
			continue
		var ghost: Sprite2D = owner_view.make_ghost()
		ghost.position = board_view.cell_to_local(cell)
		board_view.units_root.add_child(ghost)
		ghost.modulate.a = 0.0
		var tween: Tween = ghost.create_tween()
		tween.tween_property(ghost, "modulate:a", UnitView.GHOST_COLOR.a, 0.2)
		current[cell] = ghost
	_ghosts[owner.id] = current


## The ghost on [param cell], if [param owner] has one there.
func ghost_at(owner: UnitState, cell: Vector2i) -> Sprite2D:
	var current: Dictionary = _ghosts.get(owner.id, {})
	return current.get(cell)


func _fade_out(ghost: Sprite2D) -> void:
	if not is_instance_valid(ghost):
		return
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)
