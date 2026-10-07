class_name UnitView
extends Node2D
## Draws one unit. Knows no rules; the Presenter tells it what to animate
## and what HP to show (the HP at that moment of playback, which can be
## higher than the unit's current HP while a combo plays out).

const FRAME_SECONDS := 0.12
const RING_RADIUS := 26.0
const BAR_SIZE := Vector2(40, 5)
const LUNGE_DISTANCE := 22.0
const LUNGE_SECONDS := 0.09
const FLASH_SECONDS := 0.16
const DEATH_SECONDS := 0.35
const TELEPORT_SECONDS := 0.12
const GHOST_COLOR := Color(0.45, 0.3, 0.75, 0.55)

var unit: UnitState
var _sprite: Sprite2D
var _facing: StringName = &"down"
var _selected: bool = false
var _walking: bool = false
var _frame_clock: float = 0.0
var _walk_frame: int = 0
var _shown_hp: int = 0
## Status icons shown over the unit, in the order they arrived:
## { "id": StatusInstance instance id, "icon": Texture2D, "stacks": int }.
var _icons: Array[Dictionary] = []

const ICON_SIZE := 16.0


func setup(p_unit: UnitState) -> void:
	unit = p_unit
	name = "%s_%d" % [unit.def.id, unit.id]
	var def := unit.def

	_sprite = Sprite2D.new()
	_sprite.texture = def.sheet
	_sprite.hframes = def.sheet_columns
	_sprite.vframes = def.sheet_rows.size()
	# The source art is large; filter it smoothly when shrinking it to a cell.
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var frame_height := float(def.sheet.get_height()) / def.sheet_rows.size()
	var s := def.display_height / frame_height
	_sprite.scale = Vector2(s, s)
	# Stand the sprite on the lower part of the cell.
	_sprite.position = Vector2(0, 26.0 - def.display_height / 2.0)
	add_child(_sprite)
	_shown_hp = unit.hp
	_face(&"down")
	queue_redraw()


func set_selected(value: bool) -> void:
	_selected = value
	queue_redraw()


func set_spent(spent: bool) -> void:
	modulate = Color(0.6, 0.6, 0.6) if spent else Color.WHITE


## Walks through [param points] one cell at a time.
func walk_along(points: Array[Vector2], step_seconds: float) -> void:
	_walking = true
	for p in points:
		_face(_direction_name(p - position))
		var tween := create_tween()
		tween.tween_property(self, "position", p, step_seconds)
		await tween.finished
	_walking = false
	_set_frame(unit.def.idle_column)


## Steps toward [param target_pos] and back. Returns at the moment of impact,
## so the hit can land while the attacker recoils.
func lunge_toward(target_pos: Vector2) -> void:
	var home := position
	_face(_direction_name(target_pos - home))
	var dir := (target_pos - home).normalized()
	var tween := create_tween()
	tween.tween_property(self, "position", home + dir * LUNGE_DISTANCE, LUNGE_SECONDS) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	var back := create_tween()
	back.tween_property(self, "position", home, LUNGE_SECONDS * 1.5)


## Blink out, reappear at [param target_pos].
func teleport_to(target_pos: Vector2) -> void:
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, TELEPORT_SECONDS)
	await out.finished
	position = target_pos
	var back := create_tween()
	back.tween_property(self, "modulate:a", 1.0, TELEPORT_SECONDS)
	await back.finished


## A translucent copy of the unit's current sprite, for its Shadows.
func make_ghost() -> Sprite2D:
	var ghost := Sprite2D.new()
	ghost.texture = _sprite.texture
	ghost.hframes = _sprite.hframes
	ghost.vframes = _sprite.vframes
	ghost.frame = _sprite.frame
	ghost.scale = _sprite.scale
	ghost.offset = _sprite.position / _sprite.scale.x
	ghost.texture_filter = _sprite.texture_filter
	ghost.modulate = GHOST_COLOR
	return ghost


func face_toward(target_pos: Vector2) -> void:
	_face(_direction_name(target_pos - position))


## Flash, number pop and HP bar drop for one hit.
func take_hit(amount: int, hp_after: int) -> void:
	_shown_hp = hp_after
	queue_redraw()
	_float_text(str(amount), Color(1.0, 0.85, 0.3), 26)
	_sprite.modulate = Color(4, 4, 4)
	var shake := create_tween()
	shake.tween_property(_sprite, "modulate", Color.WHITE, FLASH_SECONDS)
	shake.parallel().tween_property(_sprite, "position:x", 3.0, FLASH_SECONDS / 4).as_relative()
	shake.tween_property(_sprite, "position:x", -3.0, FLASH_SECONDS / 4).as_relative()
	await shake.finished


func die() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DEATH_SECONDS)
	tween.parallel().tween_property(_sprite, "position:y", 10.0, DEATH_SECONDS).as_relative()
	await tween.finished
	queue_free()


## Green number and HP bar rise.
func heal_to(amount: int, hp_now: int) -> void:
	_shown_hp = hp_now
	queue_redraw()
	_float_text("+%d" % amount, Color(0.45, 1.0, 0.5), 26)
	var glow := create_tween()
	_sprite.modulate = Color(0.7, 1.6, 0.8)
	glow.tween_property(_sprite, "modulate", Color.WHITE, 0.35)
	await glow.finished


func float_text(text: String, color: Color) -> void:
	_float_text(text, color, 18)


func add_status_icon(inst: StatusInstance, stacks: int) -> void:
	if not inst.def.show_on_unit or inst.def.icon == null:
		return
	_icons.append({ "id": inst.get_instance_id(), "icon": inst.def.icon, "stacks": stacks })
	queue_redraw()


func set_status_stacks(inst: StatusInstance, stacks: int) -> void:
	for entry in _icons:
		if entry["id"] == inst.get_instance_id():
			entry["stacks"] = stacks
	queue_redraw()


func remove_status_icon(inst: StatusInstance) -> void:
	for i in range(_icons.size() - 1, -1, -1):
		if _icons[i]["id"] == inst.get_instance_id():
			_icons.remove_at(i)
	queue_redraw()


func _float_text(text: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0, 0))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(140, 34)
	label.position = Vector2(-70, -unit.def.display_height - 10)
	label.z_index = 30
	add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", -28.0, 0.7).as_relative() \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.tween_callback(label.queue_free)


func _process(delta: float) -> void:
	if not _walking:
		return
	_frame_clock += delta
	if _frame_clock >= FRAME_SECONDS:
		_frame_clock = 0.0
		_walk_frame = (_walk_frame + 1) % unit.def.sheet_columns
		_set_frame(_walk_frame)


func _draw() -> void:
	var color := Color(0.0, 0.0, 0.0, 0.25)
	if _selected:
		color = Color(1.0, 0.85, 0.3, 0.9)
	var team_tint := Color(0.3, 0.8, 1.0) if unit != null and unit.is_player() else Color(1.0, 0.4, 0.35)
	draw_set_transform(Vector2(0, 22), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, RING_RADIUS, Color(team_tint, 0.25))
	draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 32, color, 3.0 if _selected else 1.5)
	_draw_hp_bar(team_tint)


func _draw_hp_bar(tint: Color) -> void:
	if unit == null:
		return
	draw_set_transform(Vector2.ZERO)
	# Above the head: y-sorting draws lower units later, so a bar under the
	# feet would be hidden by whoever stands in the cell below.
	var top_left := Vector2(-BAR_SIZE.x / 2.0, 26.0 - unit.def.display_height - 6.0)
	var ratio := clampf(float(_shown_hp) / unit.get_stat(&"max_hp"), 0.0, 1.0)
	draw_rect(Rect2(top_left - Vector2.ONE, BAR_SIZE + Vector2(2, 2)), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(top_left, Vector2(BAR_SIZE.x * ratio, BAR_SIZE.y)), tint.lerp(Color.WHITE, 0.2))
	_draw_status_icons(top_left.y - ICON_SIZE - 3.0)


func _draw_status_icons(y: float) -> void:
	if _icons.is_empty():
		return
	var gap := 2.0
	var width := _icons.size() * ICON_SIZE + (_icons.size() - 1) * gap
	var x := -width / 2.0
	var font := ThemeDB.fallback_font
	for entry in _icons:
		var rect := Rect2(x, y, ICON_SIZE, ICON_SIZE)
		draw_rect(rect.grow(1.0), Color(0, 0, 0, 0.75))
		draw_texture_rect(entry["icon"], rect, false)
		var stacks: int = entry["stacks"]
		if stacks > 1:
			draw_string_outline(font, Vector2(x + ICON_SIZE - 6, y + ICON_SIZE + 2), str(stacks),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color.BLACK)
			draw_string(font, Vector2(x + ICON_SIZE - 6, y + ICON_SIZE + 2), str(stacks),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		x += ICON_SIZE + gap


func _face(direction: StringName) -> void:
	if direction == &"":
		return
	_facing = direction
	_set_frame(unit.def.idle_column)


func _set_frame(column: int) -> void:
	var row := unit.def.sheet_rows.find(_facing)
	_sprite.frame = maxi(row, 0) * unit.def.sheet_columns + column


static func _direction_name(v: Vector2) -> StringName:
	if v == Vector2.ZERO:
		return &""
	if absf(v.x) > absf(v.y):
		return &"right" if v.x > 0 else &"left"
	return &"down" if v.y > 0 else &"up"
