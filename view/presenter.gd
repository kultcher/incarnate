class_name Presenter
extends EventSink
## Plays GameEvents in order, one after another, so the screen always
## matches the order the rules ran in. Re-broadcasts each event on the
## EventBus as it plays, so the HUD updates in step with the animation.

signal idle

const STEP_SECONDS := 0.14
## Pause after a skill's name appears, before the first strike.
const WINDUP_SECONDS := 0.12
## Pause on the "Enemy Turn" banner before the first enemy moves. The player's
## banner doesn't block, so input is live as soon as the phase starts.
const ENEMY_BANNER_SECONDS := 0.6
## Short beat after a status appears, so a new icon registers.
const STATUS_SECONDS := 0.2

var board_view: BoardView
var _views: Dictionary[int, UnitView] = {}
var _queue: Array[GameEvent] = []
var _playing: bool = false
## Types of every event played, in order. Tests read this to check that
## animations ran in the same order as the rules.
var played: Array[StringName] = []
var _sound: AudioStreamPlayer


func register(unit: UnitState, view: UnitView) -> void:
	_views[unit.id] = view


func view_for(unit: UnitState) -> UnitView:
	return _views.get(unit.id)


func _ready() -> void:
	_sound = AudioStreamPlayer.new()
	add_child(_sound)


func is_busy() -> bool:
	return _playing


func enqueue(event: GameEvent) -> void:
	_queue.append(event)
	if not _playing:
		_play_queue()


func wait_idle() -> void:
	if _playing:
		await idle


func _play_queue() -> void:
	_playing = true
	while not _queue.is_empty():
		var event: GameEvent = _queue.pop_front()
		await _play(event)
		played.append(event.type)
	_playing = false
	idle.emit()


func _play(event: GameEvent) -> void:
	match event.type:
		GameEvent.UNIT_MOVED:
			var view := view_for(event.unit)
			var points: Array[Vector2] = []
			for cell in event.path:
				points.append(board_view.cell_to_local(cell))
			await view.walk_along(points, STEP_SECONDS)
			EventBus.unit_moved.emit(event.unit, event.path)
		GameEvent.ACTIONS_CHANGED:
			var view := view_for(event.unit)
			if view != null and event.unit.is_player():
				# Only your own units grey out; enemies always look ready.
				view.set_spent(event.unit.actions.is_spent())
			EventBus.actions_changed.emit(event.unit)
		GameEvent.SKILL_USED:
			var caster_view := view_for(event.unit)
			if not event.path.is_empty():
				caster_view.face_toward(board_view.cell_to_local(event.path[0]))
			EventBus.skill_used.emit(event.unit, event.skill)
			await get_tree().create_timer(WINDUP_SECONDS).timeout
		GameEvent.STRIKE:
			await _play_strike(event)
		GameEvent.DAMAGED:
			await view_for(event.unit).take_hit(event.amount, event.hp_after)
			EventBus.unit_damaged.emit(event.unit, event.amount)
		GameEvent.DIED:
			var dead := view_for(event.unit)
			_views.erase(event.unit.id)
			await dead.die()
			EventBus.unit_died.emit(event.unit)
		GameEvent.PHASE_STARTED:
			if event.team == Enums.Team.PLAYER:
				EventBus.round_started.emit(event.amount)
			EventBus.phase_started.emit(event.team, event.amount)
			if event.team != Enums.Team.PLAYER:
				await get_tree().create_timer(ENEMY_BANNER_SECONDS).timeout
		GameEvent.BATTLE_ENDED:
			EventBus.battle_ended.emit(event.outcome)
		GameEvent.HEALED:
			var healed := view_for(event.unit)
			if healed != null:
				await healed.heal_to(event.amount, event.hp_after)
			EventBus.unit_healed.emit(event.unit, event.amount)
		GameEvent.STATUS_APPLIED, GameEvent.STATUS_CHANGED, GameEvent.STATUS_REMOVED:
			var owner_view := view_for(event.unit)
			if owner_view != null:
				match event.type:
					GameEvent.STATUS_APPLIED:
						owner_view.add_status_icon(event.status, event.amount)
						if event.status.def.show_on_unit:
							await get_tree().create_timer(STATUS_SECONDS).timeout
					GameEvent.STATUS_CHANGED:
						owner_view.set_status_stacks(event.status, event.amount)
					GameEvent.STATUS_REMOVED:
						owner_view.remove_status_icon(event.status)
			EventBus.statuses_changed.emit(event.unit)
		GameEvent.TELEPORTED:
			var jumper := view_for(event.unit)
			if jumper != null:
				await jumper.teleport_to(board_view.cell_to_local(event.path[0]))
			EventBus.unit_moved.emit(event.unit, event.path)
		GameEvent.UNIT_SPAWNED:
			var view := UnitView.new()
			view.setup(event.unit)
			view.position = board_view.cell_to_local(event.unit.cell)
			view.modulate.a = 0.0
			board_view.units_root.add_child(view)
			register(event.unit, view)
			var fade := view.create_tween()
			fade.tween_property(view, "modulate:a", 1.0, 0.25)
			await fade.finished
			EventBus.unit_spawned.emit(event.unit)
		GameEvent.MARKS_CHANGED:
			board_view.marks.set_marks(StringName(event.text), event.path, event.icon)
		GameEvent.CARDS_CHANGED:
			EventBus.cards_changed.emit(event.team)
		GameEvent.SHADOWS_CHANGED:
			board_view.shadows.set_shadows(event.unit, view_for(event.unit), event.path)
		GameEvent.FLOATING_TEXT:
			var text_view := view_for(event.unit)
			if text_view != null:
				text_view.float_text(event.text, event.color)
				await get_tree().create_timer(STATUS_SECONDS).timeout
		_:
			push_warning("Presenter has no player for event %s" % event.type)


func _play_strike(event: GameEvent) -> void:
	var attacker := view_for(event.unit)
	var target := view_for(event.target)
	if target == null:
		return
	if not event.path.is_empty():
		# A Shadow's copy: the ghost on that cell lunges, not the unit.
		await _ghost_lunge(event.unit, event.path[0], target.position)
	elif attacker != null and event.melee:
		await attacker.lunge_toward(target.position)
	elif attacker != null:
		attacker.face_toward(target.position)
	EventBus.strike_shown.emit(event.unit, event.target, event.amount, event.text)
	var skill := event.skill
	if skill != null and skill.hit_fx != null:
		HitFx.spawn(board_view, target.position + Vector2(0, -20),
				skill.hit_fx, skill.hit_fx_grid)
	if skill != null and skill.hit_sound != null:
		_sound.stream = skill.hit_sound
		_sound.play()


func _ghost_lunge(owner: UnitState, cell: Vector2i, target_pos: Vector2) -> void:
	var ghost := board_view.shadows.ghost_at(owner, cell)
	if ghost == null:
		return
	var home := ghost.position
	var dir := (target_pos - home).normalized()
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "position", home + dir * UnitView.LUNGE_DISTANCE * 1.5,
			UnitView.LUNGE_SECONDS).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "modulate:a", 0.9, UnitView.LUNGE_SECONDS)
	await tween.finished
	var back := ghost.create_tween()
	back.tween_property(ghost, "position", home, UnitView.LUNGE_SECONDS * 1.5)
