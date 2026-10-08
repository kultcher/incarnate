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
## The player clicked a card in the Soulstream tray (prime it).
signal card_clicked(card: Card)
## The player double-clicked a card in the Soulstream tray (activate it).
signal card_activated(card: Card)

## Modal choices (Pacts, reactions). Lives on the HUD so it draws on top.
var prompt: PromptDialog
## The player's Soulstream (for the shared row), set by Battle.
var player_stream: Soulstream

const SKILL_BUTTON_SIZE := Vector2(64, 64)
## The battle report's columns.
const REPORT_COLUMNS: Array[String] = ["Unit", "Damage", "Healing", "Shield", "Actions",
		"Moved", "Cards"]
## Strikes kept in the log under the round counter.
const LOG_LINES := 5

var _round_label: Label
var _unit_label: Label
var _points_label: Label
var _hint_label: Label
## Rules check for the skill buttons (the resolver's can_use), set by Battle.
var can_use: Callable
## What a skill costs a unit right now (ActionResolver.cost_of), set by Battle.
## Skills made free by a status (Potent, Ignite, a Burnout replay) get a
## "FREE" badge.
var cost_of: Callable
## The battle's totals, for the report on the end screen. Set by Battle.
var stats: BattleStats
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
var _report: GridContainer
var _round: int = 0
var _my_phase: bool = true
var _targeting: SkillDef
var _targeting_step: int = 0
var _status_strip: HBoxContainer
var _tray: CardTray
var _primed: Array[Card] = []
## Heat, for the Kindleborne (in the unit panel).
var _heat_label: Label
var _report_notes: Label
var _log_label: Label
var _log: Array[String] = []
## What the boss will do this turn (Encounter intents).
var _intent_box: VBoxContainer
var _info_panel: PanelContainer


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

	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(left)
	_round_label = _label(22)
	left.add_child(_round_label)
	_log_label = _label(13)
	_log_label.modulate = Color(1, 1, 1, 0.8)
	left.add_child(_log_label)
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
	_end_turn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_end_turn.focus_mode = Control.FOCUS_NONE
	_end_turn.disabled = true
	_end_turn.pressed.connect(end_turn_pressed.emit)
	top.add_child(_end_turn)

	_intent_box = VBoxContainer.new()
	_intent_box.size_flags_horizontal = Control.SIZE_SHRINK_END
	_intent_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_intent_box.custom_minimum_size = Vector2(240, 0)
	_intent_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_box.add_theme_constant_override("separation", 4)
	var intent_margin := MarginContainer.new()
	intent_margin.add_theme_constant_override("margin_top", 52)
	intent_margin.size_flags_horizontal = Control.SIZE_SHRINK_END
	intent_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	intent_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_margin.add_child(_intent_box)
	root.add_child(intent_margin)

	# Bottom: the Soulstream tray, the skill bar (with its tooltip and hint),
	# and the selected unit's panel (health, actions, Heat, statuses).
	var bottom := HBoxContainer.new()
	bottom.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom.add_theme_constant_override("separation", 16)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)

	_tray = CardTray.new()
	_tray.size_flags_vertical = Control.SIZE_SHRINK_END
	_tray.card_clicked.connect(card_clicked.emit)
	_tray.card_activated.connect(card_activated.emit)
	bottom.add_child(_tray)

	var center := VBoxContainer.new()
	center.size_flags_vertical = Control.SIZE_SHRINK_END
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(center)
	_tooltip = _label(15)
	_tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip.custom_minimum_size = Vector2(420, 0)
	_tooltip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_skill_bar = HBoxContainer.new()
	_skill_bar.add_theme_constant_override("separation", 8)
	_skill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label = _label(14)
	_hint_label.modulate = Color(1, 1, 1, 0.75)
	center.add_child(_tooltip)
	center.add_child(_skill_bar)
	center.add_child(_hint_label)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_END
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.05, 0.08, 0.8)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	bottom.add_child(panel)
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(220, 0)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(info)
	_unit_label = _label(18)
	_unit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_points_label = _label(15)
	_points_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_heat_label = _label(15)
	_heat_label.modulate = Color(1.0, 0.75, 0.4)
	_status_strip = HBoxContainer.new()
	_status_strip.add_theme_constant_override("separation", 6)
	info.add_child(_unit_label)
	info.add_child(_points_label)
	info.add_child(_heat_label)
	info.add_child(_status_strip)
	_info_panel = panel

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
	EventBus.cards_changed.connect(func(_team: Enums.Team) -> void: _refresh_tray())
	EventBus.cards_primed.connect(_on_cards_primed)
	EventBus.strike_shown.connect(_on_strike_shown)
	EventBus.intents_changed.connect(_on_intents_changed)
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
	_refresh_tray()
	_show_banner("Round %d" % round_number if mine else "Enemy Turn",
			Color(0.55, 0.85, 1.0) if mine else Color(1.0, 0.45, 0.4))


func _on_battle_ended(outcome: Enums.Outcome) -> void:
	_end_turn.disabled = true
	_my_phase = false
	_refresh_tray()
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
	_fill_report()
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
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.08, 0.85)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(panel)
	_report = GridContainer.new()
	_report.columns = REPORT_COLUMNS.size()
	_report.add_theme_constant_override("h_separation", 22)
	_report.add_theme_constant_override("v_separation", 4)
	var report_box := VBoxContainer.new()
	report_box.add_theme_constant_override("separation", 8)
	panel.add_child(report_box)
	report_box.add_child(_report)
	_report_notes = _label(14)
	_report_notes.modulate = Color(1.0, 0.75, 0.7)
	report_box.add_child(_report_notes)
	var again := Button.new()
	again.text = "Play Again"
	again.custom_minimum_size = Vector2(180, 48)
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	again.pressed.connect(restart_pressed.emit)
	box.add_child(again)
	var menu := Button.new()
	menu.text = "Main Menu"
	menu.custom_minimum_size = Vector2(180, 40)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/main_menu.tscn"))
	box.add_child(menu)


## The end screen's table: one row per unit (the Welcoming Dead summed,
## damage only), from the BattleStats, and how many adds were spawned and
## slain under it.
func _fill_report() -> void:
	for child in _report.get_children():
		child.queue_free()
	if stats == null:
		return
	for title in REPORT_COLUMNS:
		var head := _label(14)
		head.text = title
		head.modulate = Color(1, 0.9, 0.6)
		_report.add_child(head)
	for row in stats.rows():
		var cells: Array[String] = [row.name, str(row.damage)]
		if row.group:
			cells.append_array(["-", "-", "-", "-", "-"])
		else:
			cells.append_array([str(row.healing), str(row.shield), str(row.actions),
					str(row.moved), str(row.cards)])
		for i in cells.size():
			var cell := _label(14)
			cell.text = cells[i]
			if i > 0:
				cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cell.modulate = Color(0.75, 0.9, 1.0) if row.team == Enums.Team.PLAYER else Color(1.0, 0.75, 0.7)
			_report.add_child(cell)
	_report_notes.text = "\n".join(stats.group_lines())
	_report_notes.visible = not _report_notes.text.is_empty()


func _show_unit(unit: UnitState) -> void:
	_shown = unit
	_refresh_unit()


func _clear_unit() -> void:
	_shown = null
	_targeting = null
	_unit_label.text = ""
	_points_label.text = ""
	_heat_label.text = ""
	_info_panel.visible = false
	_tooltip.text = ""
	_build_skill_bar()
	_build_status_strip()
	_refresh_tray()
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
	_targeting_step = step
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
	_hint_label.text += _primed_hint()
	_tooltip.text = _skill_text(skill)
	_build_skill_bar()


func _on_targeting_ended() -> void:
	_targeting = null
	_tooltip.text = ""
	if _shown != null:
		_refresh_unit()


func _refresh_unit() -> void:
	var unit := _shown
	_info_panel.visible = true
	_heat_label.text = _heat_text(unit)
	_heat_label.visible = not _heat_label.text.is_empty()
	if unit.shadow_of != null:
		_unit_label.text = "Shadow of the %s" % unit.shadow_of.def.display_name
		_points_label.text = "Free: use one inherited skill from this square (the Shadow then fades)."
		_build_skill_bar()
		_build_status_strip()
		_refresh_tray()
		if _targeting == null:
			_hint_label.text = "Pick an inherited skill. Right-click to deselect."
		return
	_unit_label.text = "%s\nHP %d/%d   Speed %d" % [
		unit.def.display_name, unit.hp, unit.get_stat(&"max_hp"), unit.get_stat(&"move")]
	var a := unit.actions
	_points_label.text = "Move %d   Skill %d   Flex %d" % [a.move, a.skill, a.flex]
	_build_skill_bar()
	_build_status_strip()
	_refresh_tray()
	if _targeting == null:
		if unit.skills().is_empty():
			_hint_label.text = "Click a blue cell to move. Right-click or Esc to deselect."
		else:
			_hint_label.text = "Click a blue cell to move, or pick a skill (1-%d). Right-click to deselect." \
					% unit.skills().size()
		_hint_label.text += _primed_hint()


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
	hotkey.text = str((index + 1) % 10) if index < 10 else ""
	hotkey.position = Vector2(4, 0)
	b.add_child(hotkey)
	var made_free: bool = usable and skill.cost != Enums.Cost.FREE and cost_of.is_valid() \
			and cost_of.call(_shown, skill) == Enums.Cost.FREE and _shown.shadow_of == null
	if made_free:
		var badge := _label(12)
		badge.text = "FREE"
		badge.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
		badge.position = Vector2(20, 46)
		b.add_child(badge)
		b.modulate = Color(1.15, 1.3, 1.15)
		b.tooltip_text = "Free right now. " + b.tooltip_text
	if cooldown > 0:
		var cd := _label(28)
		cd.text = str(cooldown)
		cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cd.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(cd)
	return b


func _refresh_tray() -> void:
	_tray.visible = player_stream != null
	if player_stream == null:
		return
	var holder := _shown if _shown == null or _shown.shadow_of == null else null
	_tray.show_cards(holder, player_stream.row, _primed, _my_phase and holder != null)
	if _shown != null:
		_heat_label.text = _heat_text(_shown)
		_heat_label.visible = not _heat_label.text.is_empty()


## "Heat 3/5" for a unit with Rising Heat, else "".
func _heat_text(unit: UnitState) -> String:
	var inst := unit.find_status(&"rising_heat")
	if inst == null:
		return ""
	var heat := inst.def.behavior as RisingHeatBehavior
	return "Heat %d/%d" % [unit.heat, heat.max_heat]


func _on_cards_primed(cards: Array[Card]) -> void:
	_primed = cards.duplicate()
	_refresh_tray()
	if _shown != null and _targeting == null:
		_refresh_unit()
	elif _targeting != null:
		_on_targeting_started(_shown, _targeting, _targeting_step)


## "Primed: Blade + Ward. Spent if your next skill has a matching boon."
func _primed_hint() -> String:
	if _primed.is_empty():
		return ""
	var names: Array[String] = []
	for card in _primed:
		names.append(str(card))
	return "\nPrimed: %s. Spent if your next skill has a boon of that suit." % ", ".join(names)


## "Enemy turn: Death's Caress / Grave Smash -> Bloodthane ..."
func _on_intents_changed(intents: Array[Intent]) -> void:
	for child in _intent_box.get_children():
		child.queue_free()
	if intents.is_empty():
		return
	var head := _label(15)
	head.text = "Enemy turn:"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_intent_box.add_child(head)
	for intent in intents:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var line := _label(13)
		line.text = intent.title
		if intent.target != null:
			line.text += " -> " + intent.target.def.display_name
		line.add_theme_color_override("font_color", intent.color.lightened(0.35))
		line.tooltip_text = intent.text
		line.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(line)
		if intent.icon != null:
			var icon := TextureRect.new()
			icon.texture = intent.icon
			icon.custom_minimum_size = Vector2(20, 20)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
		_intent_box.add_child(row)
		var detail := _label(11)
		detail.text = intent.text
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.custom_minimum_size = Vector2(240, 0)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		detail.modulate = Color(1, 1, 1, 0.75)
		_intent_box.add_child(detail)


func _on_strike_shown(attacker: UnitState, target: UnitState, amount: int, text: String) -> void:
	var who := attacker.def.display_name if attacker != null else "?"
	_log.append("%s hits %s for %d: %s" % [who, target.def.display_name, amount, text])
	while _log.size() > LOG_LINES:
		_log.pop_front()
	_log_label.text = "\n".join(_log)


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
