class_name Hud
extends CanvasLayer
## Round and phase, selected unit panel, skill bar, End Turn, phase banner
## and the victory/defeat screen.
## Listens to the EventBus and reads the shown unit's state; never touches
## the board or calls the resolver.

signal end_turn_pressed
signal skill_pressed(index: int)
signal restart_pressed
## The player clicked a status icon on the unit panel (Bound in Blood opens
## its Pact preference).
signal status_clicked(inst: StatusInstance)

## Modal choices (Pacts, reactions). Lives on the HUD so it draws on top.
var prompt: PromptDialog

const SKILL_BUTTON_SIZE := Vector2(64, 64)

var _round_label: Label
var _unit_label: Label
var _points_label: Label
var _hint_label: Label
## Rules check for the skill buttons (the resolver's can_use), set by Battle.
var can_use: Callable
var _skill_bar: HBoxContainer
var _tooltip: Label
var _shown: UnitState
var _end_turn: Button
var _end_turn_pulse: Tween
var _banner: Label
var _banner_tween: Tween
var _autoplay_label: Label
var _end_screen: Control
var _end_title: Label
var _round: int = 0
var _my_phase: bool = true
var _targeting: SkillDef
var _status_strip: HBoxContainer


func _ready() -> void:
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 16)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := HBoxContainer.new()
	top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)

	_round_label = _label(22)
	top.add_child(_round_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	_autoplay_label = _label(16)
	_autoplay_label.text = "AUTOPLAY (F9)  "
	_autoplay_label.modulate = Color(1.0, 0.85, 0.3)
	_autoplay_label.visible = false
	top.add_child(_autoplay_label)
	_end_turn = Button.new()
	_end_turn.text = "End Turn"
	_end_turn.tooltip_text = "End your turn (Space)"
	_end_turn.custom_minimum_size = Vector2(120, 40)
	_end_turn.focus_mode = Control.FOCUS_NONE
	_end_turn.disabled = true
	_end_turn.pressed.connect(end_turn_pressed.emit)
	top.add_child(_end_turn)

	var bottom := VBoxContainer.new()
	bottom.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	_tooltip = _label(15)
	_tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip.custom_minimum_size = Vector2(420, 0)
	_tooltip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_unit_label = _label(20)
	_points_label = _label(16)
	_skill_bar = HBoxContainer.new()
	_skill_bar.add_theme_constant_override("separation", 8)
	_skill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label = _label(14)
	_hint_label.modulate = Color(1, 1, 1, 0.75)
	bottom.add_child(_tooltip)
	bottom.add_child(_unit_label)
	_status_strip = HBoxContainer.new()
	_status_strip.add_theme_constant_override("separation", 6)
	bottom.add_child(_status_strip)
	bottom.add_child(_points_label)
	bottom.add_child(_skill_bar)
	bottom.add_child(_hint_label)

	_build_banner()
	_build_end_screen()

	prompt = PromptDialog.new()
	add_child(prompt)

	EventBus.round_started.connect(_on_round_started)
	EventBus.statuses_changed.connect(_on_unit_changed)
	EventBus.unit_healed.connect(func(unit: UnitState, _amount: int) -> void: _on_unit_changed(unit))
	EventBus.phase_started.connect(_on_phase_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.player_out_of_actions.connect(_pulse_end_turn)
	EventBus.autoplay_changed.connect(func(on: bool) -> void: _autoplay_label.visible = on)
	EventBus.unit_selected.connect(_show_unit)
	EventBus.unit_deselected.connect(_clear_unit)
	EventBus.actions_changed.connect(_on_unit_changed)
	EventBus.unit_damaged.connect(_on_unit_damaged)
	EventBus.targeting_started.connect(_on_targeting_started)
	EventBus.targeting_ended.connect(_on_targeting_ended)
	_clear_unit()


func _label(font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _on_round_started(n: int) -> void:
	_round = n
	if _shown != null:
		_refresh_unit()


func _on_phase_started(team: Enums.Team, round_number: int) -> void:
	_round = round_number
	var mine := team == Enums.Team.PLAYER
	_my_phase = mine
	if _shown == null:
		_hint_label.text = _idle_hint()
	_round_label.text = "Round %d  ·  %s" % [round_number, "Your turn" if mine else "Enemy turn"]
	_end_turn.disabled = not mine
	_stop_pulse()
	_show_banner("Round %d" % round_number if mine else "Enemy Turn",
			Color(0.55, 0.85, 1.0) if mine else Color(1.0, 0.45, 0.4))


func _on_battle_ended(outcome: Enums.Outcome) -> void:
	_end_turn.disabled = true
	_my_phase = false
	_hint_label.text = ""
	_stop_pulse()
	match outcome:
		Enums.Outcome.VICTORY:
			_end_title.text = "Victory"
			_end_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		Enums.Outcome.DEFEAT:
			_end_title.text = "Defeat"
			_end_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		_:
			_end_title.text = "Draw"
	_end_screen.visible = true
	_end_screen.modulate.a = 0.0
	create_tween().tween_property(_end_screen, "modulate:a", 1.0, 0.4)


func _pulse_end_turn() -> void:
	if _end_turn.disabled or _end_turn_pulse != null:
		return
	_end_turn_pulse = create_tween().set_loops()
	_end_turn_pulse.tween_property(_end_turn, "modulate", Color(1.4, 1.25, 0.7), 0.45)
	_end_turn_pulse.tween_property(_end_turn, "modulate", Color.WHITE, 0.45)


func _stop_pulse() -> void:
	if _end_turn_pulse != null:
		_end_turn_pulse.kill()
		_end_turn_pulse = null
	_end_turn.modulate = Color.WHITE


func _build_banner() -> void:
	_banner = _label(54)
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.size = Vector2(600, 90)
	_banner.position = -_banner.size / 2.0 + Vector2(0, -60)
	_banner.pivot_offset = _banner.size / 2.0
	_banner.modulate.a = 0.0
	add_child(_banner)


func _show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	if _banner_tween != null:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner.scale = Vector2(0.85, 0.85)
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.15)
	_banner_tween.parallel().tween_property(_banner, "scale", Vector2.ONE, 0.15)
	_banner_tween.tween_interval(0.6)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.3)


func _build_end_screen() -> void:
	_end_screen = ColorRect.new()
	(_end_screen as ColorRect).color = Color(0, 0, 0, 0.55)
	_end_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_end_screen.visible = false
	add_child(_end_screen)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end_screen.add_child(box)
	_end_title = _label(72)
	_end_title.add_theme_constant_override("outline_size", 12)
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_end_title)
	var again := Button.new()
	again.text = "Play Again"
	again.custom_minimum_size = Vector2(180, 48)
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	again.pressed.connect(restart_pressed.emit)
	box.add_child(again)


func _show_unit(unit: UnitState) -> void:
	_shown = unit
	_refresh_unit()


func _clear_unit() -> void:
	_shown = null
	_targeting = null
	_unit_label.text = ""
	_points_label.text = ""
	_tooltip.text = ""
	_build_skill_bar()
	_build_status_strip()
	_hint_label.text = _idle_hint()


func _idle_hint() -> String:
	if not _my_phase:
		return "Enemy turn..."
	return "Click one of your units to select it. Space ends your turn. F9 lets the AI play your side."


func _on_unit_changed(unit: UnitState) -> void:
	if unit == _shown:
		_refresh_unit()


func _on_unit_damaged(unit: UnitState, _amount: int) -> void:
	_on_unit_changed(unit)


func _on_targeting_started(_unit: UnitState, skill: SkillDef, step: int) -> void:
	_targeting = skill
	if skill.is_path():
		_hint_label.text = "%s: %s. Click the last square again (or Enter) to stop there. Right-click to go back." \
				% [skill.display_name, skill.path.prompt]
	else:
		var prompt := skill.targets[step].prompt
		if prompt.is_empty():
			prompt = "Pick a target"
		if skill.targets.size() > 1:
			prompt += " (%d of %d)" % [step + 1, skill.targets.size()]
		_hint_label.text = "%s: %s. Right-click to go back." % [skill.display_name, prompt]
	_tooltip.text = _skill_text(skill)
	_build_skill_bar()


func _on_targeting_ended() -> void:
	_targeting = null
	_tooltip.text = ""
	if _shown != null:
		_refresh_unit()


func _refresh_unit() -> void:
	var unit := _shown
	_unit_label.text = "%s   HP %d/%d   Speed %d" % [
		unit.def.display_name, unit.hp, unit.get_stat(&"max_hp"), unit.get_stat(&"move")]
	var a := unit.actions
	_points_label.text = "Move %d   Skill %d   Flex %d" % [a.move, a.skill, a.flex]
	_build_skill_bar()
	_build_status_strip()
	if _targeting == null:
		if unit.skills().is_empty():
			_hint_label.text = "Click a blue cell to move. Right-click or Esc to deselect."
		else:
			_hint_label.text = "Click a blue cell to move, or pick a skill (1-%d). Right-click to deselect." \
					% unit.skills().size()


func _build_skill_bar() -> void:
	for child in _skill_bar.get_children():
		child.queue_free()
	if _shown == null:
		return
	var skills := _shown.skills()
	for i in skills.size():
		_skill_bar.add_child(_skill_button(i, skills[i]))


func _skill_button(index: int, skill: SkillDef) -> Button:
	var b := Button.new()
	b.custom_minimum_size = SKILL_BUTTON_SIZE
	b.icon = skill.icon
	b.expand_icon = true
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = _skill_text(skill)
	var cooldown := _shown.cooldown_left(skill)
	var usable: bool = can_use.call(_shown, skill) if can_use.is_valid() \
			else cooldown == 0 and _shown.actions.can_pay(skill.cost)
	b.disabled = not usable
	if not usable:
		b.modulate = Color(0.45, 0.45, 0.45)
	if skill == _targeting:
		b.modulate = Color(1.3, 1.15, 0.7)
	b.pressed.connect(skill_pressed.emit.bind(index))
	b.mouse_entered.connect(func() -> void:
		if _targeting == null:
			_tooltip.text = _skill_text(skill))
	b.mouse_exited.connect(func() -> void:
		if _targeting == null:
			_tooltip.text = "")

	var hotkey := _label(14)
	hotkey.text = str((index + 1) % 10)
	hotkey.position = Vector2(4, 0)
	b.add_child(hotkey)
	if cooldown > 0:
		var cd := _label(28)
		cd.text = str(cooldown)
		cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cd.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(cd)
	return b


## "Gloom Edge (Skill action · Recharge 2): Strike target foe for..."
func _skill_text(skill: SkillDef) -> String:
	var text := "%s (%s): %s" % [skill.display_name, skill.cost_text(), skill.describe()]
	if _shown != null and skill.requires_status != &"" and not _shown.has_status(skill.requires_status):
		text += " [Not available right now.]"
	return text


func _build_status_strip() -> void:
	for child in _status_strip.get_children():
		child.queue_free()
	if _shown == null:
		return
	for inst in _shown.statuses:
		_status_strip.add_child(_status_button(inst))


func _status_button(inst: StatusInstance) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(36, 36)
	b.icon = inst.def.icon
	b.expand_icon = true
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	var lines: Array[String] = [inst.def.display_name, inst.describe()]
	if not inst.is_permanent():
		lines.append("%d turn%s left" % [inst.turns_left, "" if inst.turns_left == 1 else "s"])
	var bib := inst.def.behavior as BoundInBloodBehavior
	if bib != null:
		if inst.choice >= 0 and inst.choice < bib.pacts.size():
			lines.append("Pact: always %s (click to change)" % bib.pacts[inst.choice].display_name)
		else:
			lines.append("Pact: ask each time (click to choose one in advance)")
	b.tooltip_text = "\n".join(lines)
	b.mouse_entered.connect(func() -> void:
		if _targeting == null:
			_tooltip.text = "%s: %s" % [inst.def.display_name, inst.describe()])
	b.mouse_exited.connect(func() -> void:
		if _targeting == null:
			_tooltip.text = "")
	b.pressed.connect(status_clicked.emit.bind(inst))
	if inst.stacks > 1:
		var count := _label(14)
		count.text = str(inst.stacks)
		count.position = Vector2(24, 18)
		b.add_child(count)
	return b
