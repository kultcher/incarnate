class_name ShadowLayer
extends Node
## Draws each unit's Shadows (the Traceless's) as translucent copies of its
## sprite. Holds no rules: the Presenter hands it the cells to show.

var board_view: BoardView
## Ghost sprites by owner unit id, then by cell.
var _ghosts: Dictionary[int, Dictionary] = {}
## Shadows that can use an inherited skill now, by owner unit id.
var _ready: Dictionary[int, Array] = {}
## Gold rings under ready Shadows, by cell.
var _markers: Dictionary[Vector2i, ShadowMarker] = {}
var _counts: Dictionary[Vector2i, int] = {}
## The Shadow the player has selected (to use its skills), if any.
var selected_cell := Vector2i(-1, -1)
var _pulse := 0.0


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


## Marks [param owner]'s Shadows on [param cells] as ready: each gets a
## pulsing gold ring with a badge for its usable skill count
## ([param counts], one per cell), so the player knows clicking it offers a
## skill with a target.
func set_ready(owner: UnitState, cells: Array[Vector2i], counts: Array[int] = []) -> void:
	_ready[owner.id] = cells.duplicate()
	for i in cells.size():
		_counts[cells[i]] = counts[i] if i < counts.size() else 1
	var wanted: Array[Vector2i] = []
	for list: Array in _ready.values():
		for cell: Vector2i in list:
			wanted.append(cell)
	for cell: Vector2i in _markers.keys():
		if not wanted.has(cell):
			_markers[cell].queue_free()
			_markers.erase(cell)
	for cell in wanted:
		if not _markers.has(cell):
			var marker := ShadowMarker.new()
			marker.position = board_view.cell_to_local(cell)
			board_view.add_child(marker)
			# Under the units, so the Shadow stands on its ring.
			board_view.move_child(marker, board_view.units_root.get_index())
			_markers[cell] = marker
		_markers[cell].count = _counts.get(cell, 1)


## The ring under the Shadow on [param cell], if it's ready.
func marker_at(cell: Vector2i) -> ShadowMarker:
	return _markers.get(cell)


func _process(delta: float) -> void:
	_pulse = fmod(_pulse + delta * 3.0, TAU)
	var glow := 0.5 + 0.5 * sin(_pulse)
	for marker: ShadowMarker in _markers.values():
		marker.pulse = glow
		marker.queue_redraw()
	for owner_id: int in _ghosts:
		var ready: Array = _ready.get(owner_id, [])
		var current: Dictionary = _ghosts[owner_id]
		for cell: Vector2i in current:
			var ghost: Sprite2D = current[cell]
			if not is_instance_valid(ghost):
				continue
			if cell == selected_cell:
				ghost.self_modulate = Color(1.6, 1.4, 0.8)
			elif ready.has(cell):
				ghost.self_modulate = Color(1.0, 1.0, 1.0).lerp(Color(2.4, 2.0, 1.2), glow)
			else:
				ghost.self_modulate = Color.WHITE


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
