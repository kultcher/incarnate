class_name PromptDialog
extends Control
## A modal choice on the HUD layer: "Bind which Pact?", "Use Chimeric Cloak?".
## A Control with a full-screen blocker, not a Window, so nothing pauses.
##   1-9    pick an option        Esc    decline (when allowed)

signal _answered(index: int)

const OPTION_ICON := 44.0

var _panel: PanelContainer
var _title: Label
var _icon: TextureRect
var _text: Label
var _options: VBoxContainer
var _remember: CheckBox
var _decline: Button
var _request: DecisionRequest


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.09, 0.97)
	style.border_color = Color(0.75, 0.25, 0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_panel.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(40, 40)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(_icon)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.55))
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_title)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(420, 0)
	_text.add_theme_font_size_override("font_size", 16)
	box.add_child(_text)

	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 6)
	box.add_child(_options)

	_remember = CheckBox.new()
	_remember.text = "Always choose this (click the passive's icon to change)"
	_remember.focus_mode = Control.FOCUS_NONE
	_remember.add_theme_icon_override("unchecked", _box_icon(false))
	_remember.add_theme_icon_override("checked", _box_icon(true))
	box.add_child(_remember)

	_decline = Button.new()
	_decline.custom_minimum_size = Vector2(0, 36)
	_decline.focus_mode = Control.FOCUS_NONE
	_decline.pressed.connect(func() -> void: _answer(DecisionRequest.DECLINED))
	box.add_child(_decline)


## Shows [param request] and waits for the player. Returns an option index
## or DecisionRequest.DECLINED.
func ask(request: DecisionRequest) -> int:
	_request = request
	_title.text = request.title
	_icon.texture = request.icon
	_icon.visible = request.icon != null
	_text.text = request.text
	for child in _options.get_children():
		child.queue_free()
	for i in request.options.size():
		_options.add_child(_option_button(i, request.options[i]))
	_remember.visible = request.offer_remember
	_remember.button_pressed = false
	_decline.visible = not request.decline_label.is_empty()
	_decline.text = request.decline_label
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.12)
	var index: int = await _answered
	request.remember = request.offer_remember and _remember.button_pressed
	visible = false
	_request = null
	return index


func is_open() -> bool:
	return _request != null


## Answers the open question, as if clicked. For tests and keyboard input.
func pick(index: int) -> void:
	if _request != null:
		_answer(index)


func set_remember(on: bool) -> void:
	_remember.button_pressed = on


func _option_button(index: int, option: DecisionRequest.DecisionOption) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, OPTION_ICON + 12)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon = option.icon
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", int(OPTION_ICON))
	b.text = "%d  %s\n     %s" % [index + 1, option.label, option.description] \
			if not option.description.is_empty() else "%d  %s" % [index + 1, option.label]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = 420
	b.pressed.connect(func() -> void: _answer(index))
	return b


## The default theme's checkbox is nearly invisible on this dark panel.
static func _box_icon(checked: bool) -> ImageTexture:
	var size := 18
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var edge := Color(0.9, 0.8, 0.7)
	for i in size:
		for w in 2:
			img.set_pixel(i, w, edge)
			img.set_pixel(i, size - 1 - w, edge)
			img.set_pixel(w, i, edge)
			img.set_pixel(size - 1 - w, i, edge)
	if checked:
		img.fill_rect(Rect2i(5, 5, size - 10, size - 10), Color(0.95, 0.35, 0.35))
	return ImageTexture.create_from_image(img)


func _answer(index: int) -> void:
	if _request == null:
		return
	if index == DecisionRequest.DECLINED and _request.decline_label.is_empty():
		return
	_answered.emit(index)


func _unhandled_input(event: InputEvent) -> void:
	if _request == null:
		return
	if event.is_action_pressed(&"ui_cancel"):
		_answer(DecisionRequest.DECLINED)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.is_echo():
		var key := (event as InputEventKey).keycode
		if key >= KEY_1 and key <= KEY_9 and key - KEY_1 < _request.options.size():
			_answer(key - KEY_1)
			get_viewport().set_input_as_handled()
