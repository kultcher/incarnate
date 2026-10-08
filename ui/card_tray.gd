class_name CardTray
extends PanelContainer
## The Soulstream on the HUD: the selected Incarnate's hand and the shared
## row. Double-click a card to activate it (its base effects); click it to
## prime it for the unit's next skill's boon or Heroic (click again to
## unprime). Primed cards stand raised with a bright border.

signal card_clicked(card: Card)
signal card_activated(card: Card)

const CARD_SIZE := Vector2(46, 64)
const SUIT_COLORS: Array[Color] = [
	Color(0.62, 0.24, 0.22),  # Blade
	Color(0.24, 0.42, 0.66),  # Orb
	Color(0.44, 0.3, 0.62),   # Portal
	Color(0.3, 0.52, 0.34),   # Ward
]
const WILD_COLOR := Color(0.72, 0.6, 0.22)
const SUIT_ICONS: Array[Texture2D] = [
	preload("res://art/cards/blade.png"),
	preload("res://art/cards/orb.png"),
	preload("res://art/cards/portal.png"),
	preload("res://art/cards/ward.png"),
]

var _hand_label: Label
var _hand_row: HBoxContainer
var _row_label: Label
var _row_row: HBoxContainer


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.08, 0.8)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_hand_label = _caption("Hand")
	box.add_child(_hand_label)
	_hand_row = _card_row()
	box.add_child(_hand_row)
	_row_label = _caption("Shared Soulstream")
	box.add_child(_row_label)
	_row_row = _card_row()
	box.add_child(_row_row)


## Shows [param row] and, if [param holder] isn't null, its hand.
## Cards are clickable only when [param interactive].
func show_cards(holder: UnitState, row: Array[Card], primed: Array[Card],
		interactive: bool) -> void:
	_fill(_row_row, row, primed, interactive, "the shared row")
	_hand_label.visible = holder != null
	_hand_row.visible = holder != null
	if holder != null:
		_hand_label.text = "%s's hand" % holder.def.display_name
		_fill(_hand_row, holder.hand, primed, interactive, "your hand")


func _fill(container: HBoxContainer, cards: Array[Card], primed: Array[Card],
		interactive: bool, where: String) -> void:
	for child in container.get_children():
		child.queue_free()
	if cards.is_empty():
		var none := _caption("(empty)")
		none.modulate.a = 0.6
		container.add_child(none)
		return
	for card in cards:
		container.add_child(card_button(card, primed.has(card), interactive, where))


## What activating [param card] does, for tooltips.
static func effect_text(card: Card) -> String:
	if card.is_wild():
		return "pick a suit: " + ", ".join(ActionResolver.SUIT_TEXT.values()).to_lower()
	var parts: Array[String] = []
	for suit in card.suits:
		parts.append(ActionResolver.SUIT_TEXT[suit].trim_suffix("."))
	return ", then ".join(parts)


func card_button(card: Card, is_primed: bool, interactive: bool, where: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not interactive
	var tint := WILD_COLOR if card.is_wild() else SUIT_COLORS[int(card.suits[0])]
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = tint.lightened(0.15) if state == "hover" else tint
		if card.suits.size() == 2 and card.suits[0] != card.suits[1]:
			# Two suits: the second colours the lower half's border.
			style.border_color = SUIT_COLORS[int(card.suits[1])].lightened(0.2)
		else:
			style.border_color = tint.darkened(0.45)
		if is_primed:
			style.border_color = Color(1, 1, 0.85)
		style.set_corner_radius_all(5)
		style.set_border_width_all(3 if is_primed or card.suits.size() == 2 else 2)
		b.add_theme_stylebox_override(state, style)
	# Primed cards sit higher in their row.
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if is_primed else Control.SIZE_SHRINK_END
	var head := "%s (primed)" % card if is_primed else "%s, in %s" % [card, where]
	b.tooltip_text = "%s.\nDouble-click: %s.\nClick: %s it for your next skill's boon or Heroic." \
			% [head, effect_text(card), "unprime" if is_primed else "prime"]

	if card.is_wild():
		var w := Label.new()
		w.text = "W"
		w.add_theme_font_size_override("font_size", 26)
		w.add_theme_color_override("font_outline_color", Color.BLACK)
		w.add_theme_constant_override("outline_size", 5)
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		w.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		w.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(w)
	elif card.suits.size() == 1:
		b.add_child(_suit_icon(card.suits[0], 6, 8))
	else:
		b.add_child(_suit_icon(card.suits[0], 4, 34))
		b.add_child(_suit_icon(card.suits[1], 34, 4))

	b.pressed.connect(card_clicked.emit.bind(card))
	b.gui_input.connect(func(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.double_click and mb.button_index == MOUSE_BUTTON_LEFT \
				and not b.disabled:
			card_activated.emit(card))
	return b


## A suit icon filling the card from [param top] to [param bottom] pixels
## in from its edges.
func _suit_icon(suit: Enums.Suit, top: int, bottom: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = SUIT_ICONS[int(suit)]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 6
	icon.offset_right = -6
	icon.offset_top = top
	icon.offset_bottom = -bottom
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _card_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.custom_minimum_size = Vector2(0, CARD_SIZE.y + 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row
