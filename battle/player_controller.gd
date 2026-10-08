class_name PlayerController
extends TurnDriver
## Plays the player's phase: turns mouse and keyboard input into requests
## for the resolver. Input only works during the player's phase.
##
## Units can be selected, moved and use skills in any order, as often as
## their action points allow, so one unit can act, hand off to another, and
## come back.
##   Left click own unit     select it
##   Left click blue cell    move there
##   1-9 / skill button      start targeting that skill
##   Left click red cell     pick a target (multi-step skills ask again)
##   Path skills             click squares one by one; click the last square
##                           again (or press Enter) to stop early
##   Right click / Esc       undo the last pick, cancel targeting, deselect
##   Space / End Turn button end the player's phase
##   Click a card (HUD)      ready it for the selected unit's next skill
##   Left click a Shadow     use a skill it inherited this turn (Traceless)

## Emitted when the player ends their phase (or the battle ends during it).
signal turn_ended

enum State { INACTIVE, IDLE, UNIT_SELECTED, TARGETING, BUSY }

var board: BoardState
var board_view: BoardView
var resolver: ActionResolver
var presenter: Presenter

var state: State = State.INACTIVE
var selected: UnitState
var skill: SkillDef
var picks: Array[Vector2i] = []
## Cards from the selected unit's hand or the shared row, readied for its
## next skill. Cleared when the skill is used or another unit is selected.
var readied: Array[Card] = []
## Asks the player to confirm something: (title, text, icon, yes label) ->
## bool. Set by Battle (the HUD's prompt). Without it, nothing is asked.
var confirm: Callable
var _reach: Pathing.Reach
var _valid: Array[Vector2i] = []
var _hover_cell := Vector2i(-1, -1)


func _ready() -> void:
	EventBus.unit_died.connect(_on_unit_died)


func _unhandled_input(event: InputEvent) -> void:
	if state == State.INACTIVE:
		return
	if event is InputEventMouseMotion:
		_update_hover(board_view.mouse_cell())
	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			click_cell(board_view.mouse_cell())
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			back()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		back()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.is_echo():
		var key := (event as InputEventKey).keycode
		if key >= KEY_1 and key <= KEY_9:
			begin_targeting_index(key - KEY_1)
			get_viewport().set_input_as_handled()
		elif key == KEY_0:
			begin_targeting_index(9)
			get_viewport().set_input_as_handled()
		elif key == KEY_ENTER or key == KEY_KP_ENTER:
			finish_path()
			get_viewport().set_input_as_handled()
		elif key == KEY_SPACE:
			end_turn_from_input()
			get_viewport().set_input_as_handled()


## Gives the player control until they end the phase.
func take_turn(_team: Enums.Team) -> void:
	state = State.IDLE
	_check_exhausted()
	await turn_ended


## End Turn button / Space: asks first if a unit still has actions left.
func end_turn_from_input() -> void:
	if state == State.INACTIVE or state == State.BUSY:
		return
	var idle: Array[String] = []
	for unit in board.units():
		if unit.is_player() and unit.is_alive() and not unit.actions.is_spent():
			idle.append(unit.def.display_name)
	if not idle.is_empty() and confirm.is_valid():
		var text := "%s still %s actions left. End your turn anyway?" % [
				", ".join(idle), "has" if idle.size() == 1 else "have"]
		if not await confirm.call("End turn?", text, null, "End turn"):
			return
	request_end_turn()


## Ends the player's phase now. Ignored while an action is playing out.
func request_end_turn() -> void:
	if state == State.INACTIVE or state == State.BUSY:
		return
	_finish_turn()


func is_active() -> bool:
	return state != State.INACTIVE


func _finish_turn() -> void:
	_end_targeting()
	_clear_readied()
	if selected != null:
		var view := presenter.view_for(selected)
		if view != null:
			view.set_selected(false)
		selected = null
		EventBus.unit_deselected.emit()
	_reach = null
	board_view.clear_highlights()
	state = State.INACTIVE
	turn_ended.emit()


## Public so tests and debug tools can drive the controller without a mouse.
func click_cell(cell: Vector2i) -> void:
	if state == State.BUSY or state == State.INACTIVE or not board.in_bounds(cell):
		return
	if state == State.TARGETING:
		if skill.is_path() and not picks.is_empty() and cell == picks[-1]:
			await finish_path()
		elif _valid.has(cell):
			await _pick(cell)
		return
	if state == State.UNIT_SELECTED and _reach != null and _reach.can_reach(cell):
		await _move_selected(cell)
		return
	var unit := board.unit_at(cell)
	if unit != null and unit.is_player():
		select(unit)
		return
	var shadow := _shadow_at(cell)
	if shadow != null:
		select(shadow)
	else:
		deselect()


## A stand-in for a player's Shadow on [param cell] that can use an inherited
## skill now, or null.
func _shadow_at(cell: Vector2i) -> UnitState:
	if board.is_occupied(cell):
		return null
	for owner in board.units():
		if owner.is_player() and owner.shadows.has(cell) \
				and not resolver.shadow_skill_list(owner, cell).is_empty():
			return resolver.shadow_proxy(owner, cell)
	return null


func select(unit: UnitState) -> void:
	if state == State.BUSY or state == State.INACTIVE:
		return
	_end_targeting()
	if selected != null and presenter.view_for(selected) != null:
		presenter.view_for(selected).set_selected(false)
	if unit != selected:
		_clear_readied()
	selected = unit
	state = State.UNIT_SELECTED
	if presenter.view_for(unit) != null:
		presenter.view_for(unit).set_selected(true)
	board_view.shadows.selected_cell = unit.cell if unit.shadow_of != null else Vector2i(-1, -1)
	_refresh_range()
	EventBus.unit_selected.emit(unit)


func deselect() -> void:
	if state == State.BUSY or state == State.INACTIVE:
		return
	_end_targeting()
	_clear_readied()
	if selected != null and presenter.view_for(selected) != null:
		presenter.view_for(selected).set_selected(false)
	selected = null
	board_view.shadows.selected_cell = Vector2i(-1, -1)
	_reach = null
	state = State.IDLE
	board_view.clear_highlights()
	EventBus.unit_deselected.emit()


## Right click: undo one pick, else cancel targeting, else deselect.
func back() -> void:
	match state:
		State.TARGETING:
			if picks.is_empty():
				_end_targeting()
				state = State.UNIT_SELECTED
				_refresh_range()
			else:
				picks.pop_back()
				_show_targeting()
		State.UNIT_SELECTED:
			deselect()


## Starts targeting the selected unit's skill in bar slot [param index].
func begin_targeting_index(index: int) -> void:
	if selected == null or index < 0 or index >= selected.skills().size():
		return
	begin_targeting(selected.skills()[index])


func begin_targeting(p_skill: SkillDef) -> void:
	if selected == null or state == State.BUSY or state == State.INACTIVE:
		return
	if not _usable(selected, p_skill):
		return
	_end_targeting()
	skill = p_skill
	picks.clear()
	if skill.targets.is_empty() and not skill.is_path():
		await _use_skill()
		return
	state = State.TARGETING
	_show_targeting()


## Re-reads the selected unit's options, e.g. after a new round refreshes points.
func refresh() -> void:
	if selected != null and state == State.UNIT_SELECTED:
		_refresh_range()


func _pick(cell: Vector2i) -> void:
	picks.append(cell)
	if skill.is_path():
		if Targeting.path_is_full(board, selected, skill, picks) \
				and Targeting.path_can_finish(board, selected, skill, picks):
			await _use_skill()
		else:
			_show_targeting()
		return
	if picks.size() < skill.targets.size():
		_show_targeting()
		return
	await _use_skill()


## Path skills: stop the path where it is, if it may end there.
func finish_path() -> void:
	if state != State.TARGETING or skill == null or not skill.is_path():
		return
	if Targeting.path_can_finish(board, selected, skill, picks):
		await _use_skill()


func _use_skill() -> void:
	state = State.BUSY
	board_view.clear_highlights()
	var used_skill := skill
	var used_picks: Array[Vector2i] = picks.duplicate()
	var used_cards := _valid_readied()
	# Once-per-battle and team-limited skills ask first.
	if (used_skill.slot == Enums.Slot.ULTIMATE or used_skill.slot == Enums.Slot.RECOVERY) \
			and selected.shadow_of == null and confirm.is_valid():
		var kind := "your Ultimate (once per battle)" if used_skill.slot == Enums.Slot.ULTIMATE \
				else "a Recovery (%d left for the team)" % resolver.recoveries_left(selected.team)
		if not await confirm.call(used_skill.display_name,
				"Use %s, %s?" % [used_skill.display_name, kind], used_skill.icon, "Use it"):
			state = State.TARGETING if not used_picks.is_empty() else State.UNIT_SELECTED
			if state == State.TARGETING:
				picks.pop_back()
				_show_targeting()
			else:
				_end_targeting()
				_refresh_range()
			return
	_end_targeting()
	_clear_readied()
	if selected.shadow_of != null:
		await resolver.request_shadow_skill(selected, used_skill, used_picks)
	else:
		await resolver.request_skill(selected, used_skill, used_picks, used_cards)
	_after_action()


## The skill can be started now: its cost, recharge and rules, and a target.
## A Shadow's stand-in uses its inherited skills for free.
func _usable(unit: UnitState, p_skill: SkillDef) -> bool:
	if unit.shadow_of != null:
		return resolver.can_use_shadow(unit, p_skill) and resolver.has_targets(unit, p_skill)
	return resolver.can_use(unit, p_skill) and resolver.has_targets(unit, p_skill)


## Readies [param card] for the selected unit's next skill, or puts it back.
## Only the selected unit's hand and the shared row can be readied.
func toggle_card(card: Card) -> void:
	if selected == null or selected.shadow_of != null or state == State.BUSY \
			or state == State.INACTIVE:
		return
	if readied.has(card):
		readied.erase(card)
	elif selected.hand.has(card) or resolver.soulstream(selected.team).row.has(card):
		readied.append(card)
	else:
		return
	EventBus.cards_readied.emit(readied)


## Readied cards still in the hand or the row (a card may have been spent).
func _valid_readied() -> Array[Card]:
	var out: Array[Card] = []
	var row := resolver.soulstream(selected.team).row
	for card in readied:
		if selected.hand.has(card) or row.has(card):
			out.append(card)
	return out


func _clear_readied() -> void:
	if readied.is_empty():
		return
	readied.clear()
	EventBus.cards_readied.emit(readied)


func _show_targeting() -> void:
	if skill.is_path():
		_valid = Targeting.path_next_cells(board, selected, skill, picks)
		board_view.show_cells(_valid, skill.path.highlight)
		board_view.pick_marks.show_path(selected.cell, picks,
				Targeting.path_can_finish(board, selected, skill, picks))
		_update_hover(_hover_cell, true)
		EventBus.targeting_started.emit(selected, skill, picks.size())
		return
	var step := skill.targets[picks.size()]
	_valid = Targeting.valid_cells(board, selected, skill, picks.size(), picks)
	board_view.show_cells(_valid, step.highlight)
	board_view.pick_marks.show_picks(picks)
	_update_hover(_hover_cell, true)
	EventBus.targeting_started.emit(selected, skill, picks.size())


func _end_targeting() -> void:
	if skill == null:
		return
	skill = null
	picks.clear()
	_valid.clear()
	board_view.pick_marks.clear()
	EventBus.targeting_ended.emit()


func _move_selected(cell: Vector2i) -> void:
	state = State.BUSY
	board_view.clear_highlights()
	await resolver.request_move(selected, cell)
	_after_action()


## Back to the selected unit once an action has played out, unless the
## battle ended or the unit died during it.
func _after_action() -> void:
	if is_over.call():
		state = State.IDLE
		_finish_turn()
		return
	if selected != null and selected.shadow_of != null:
		# A Shadow fades after acting: go back to its owner if it did.
		var owner := selected.shadow_of
		var again := _shadow_at(selected.cell) if owner.shadows.has(selected.cell) else null
		selected = again if again != null else (owner if owner.is_alive() else null)
		board_view.shadows.selected_cell = Vector2i(-1, -1)
		if selected != null and selected.shadow_of != null:
			board_view.shadows.selected_cell = selected.cell
		elif selected != null and presenter.view_for(selected) != null:
			presenter.view_for(selected).set_selected(true)
	if selected == null or not selected.is_alive():
		selected = null
		state = State.IDLE
		board_view.clear_highlights()
		EventBus.unit_deselected.emit()
	else:
		state = State.UNIT_SELECTED
		_refresh_range()
		EventBus.unit_selected.emit(selected)
	_check_exhausted()


## Tells the HUD when no player unit can do anything more this phase.
func _check_exhausted() -> void:
	for unit in board.units():
		if unit.is_player() and not unit.actions.is_spent():
			return
	EventBus.player_out_of_actions.emit()


func _on_unit_died(unit: UnitState) -> void:
	if unit == selected and state != State.BUSY:
		deselect()


func _refresh_range() -> void:
	if resolver.can_move(selected):
		_reach = Pathing.reachable(board, selected, selected.get_stat(&"move"))
		board_view.show_cells(_reach.destinations, Enums.Highlight.MOVE)
	else:
		_reach = null
		board_view.clear_highlights()
	_update_hover(_hover_cell, true)


func _update_hover(cell: Vector2i, force: bool = false) -> void:
	if cell == _hover_cell and not force:
		return
	_hover_cell = cell
	if state == State.BUSY:
		return
	if state == State.UNIT_SELECTED and _reach != null and _reach.can_reach(cell):
		board_view.show_path(_reach.path_to(cell), cell)
	elif state == State.TARGETING and skill.area != null and _valid.has(cell):
		# Preview the squares the skill would hit (Cinder Wave).
		var hovered: Array[Vector2i] = picks.duplicate()
		hovered.append(cell)
		board_view.show_path(skill.area.cells(board, selected, hovered), cell)
	else:
		board_view.show_hover(cell)
