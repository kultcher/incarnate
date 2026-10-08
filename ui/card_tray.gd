class_name CardTray
extends PanelContainer
## The Soulstream on the HUD: the selected Incarnate's hand and the shared
## row. Clicking a card readies it for that unit's next skill (or unreadies
## it); readied cards stand raised with a bright border.

signal card_clicked(card: Card)

const CARD_SIZE := Vector2(46, 64)
const TIER_COLORS: Array[Color] = [
	Color(0.62, 0.38, 0.22),  # Bronze
	Color(0.58, 0.62, 0.68),  # Silver
	Color(0.82, 0.64, 0.2),   # Gold
]
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
	_row_label = _caption("Shared Soulstream")
	box.add_child(_row_label)
	_row_row = _card_row()
	box.add_child(_row_row)
	_hand_label = _caption("Hand")
	box.add_child(_hand_label)
	_hand_row = _card_row()
	box.add_child(_hand_row)


## Shows [param row] and, if [param holder] isn't null, its hand.
## Cards are clickable only when [param interactive].
func show_cards(holder: UnitState, row: Array[Card], readied: Array[Card],
		interactive: bool) -> void:
	_fill(_row_row, row, readied, interactive, "the shared row")
	_hand_label.visible = holder != null
	_hand_row.visible = holder != null
	if holder != null:
		_hand_label.text = "%s's hand" % holder.def.display_name
		_fill(_hand_row, holder.hand, readied, interactive, "your hand")


func _fill(container: HBoxContainer, cards: Array[Card], readied: Array[Card],
		interactive: bool, where: String) -> void:
	for child in container.get_children():
		child.queue_free()
	if cards.is_empty():
		var none := _caption("(empty)")
		none.modulate.a = 0.6
		container.add_child(none)
		return
	for card in cards:
		container.add_child(card_button(card, readied.has(card), interactive, where))


func card_button(card: Card, is_readied: bool, interactive: bool, where: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not interactive
	var tint := TIER_COLORS[int(card.tier)]
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = tint.lightened(0.15) if state == "hover" else tint
		style.set_corner_radius_all(5)
		style.border_color = Color(1, 1, 0.85) if is_readied else tint.darkened(0.45)
		style.set_border_width_all(3 if is_readied else 2)
		b.add_theme_stylebox_override(state, style)
	# Readied cards sit higher in their row.
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if is_readied else Control.SIZE_SHRINK_END
	if is_readied:
		b.tooltip_text = "%s (readied). Click to put it back." % card
	else:
		b.tooltip_text = "%s from %s. Click to ready it: your next skill uses it in place of one of its draws." \
				% [card, where]

	var icon := TextureRect.new()
	icon.texture = SUIT_ICONS[int(card.suit)]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 8
	icon.offset_right = -8
	icon.offset_top = 22
	icon.offset_bottom = -8
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	var value := Label.new()
	value.text = str(card.value)
	value.add_theme_font_size_override("font_size", 20)
	value.add_theme_color_override("font_outline_color", Color.BLACK)
	value.add_theme_constant_override("outline_size", 5)
	value.position = Vector2(5, 0)
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(value)

	b.pressed.connect(card_clicked.emit.bind(card))
	return b


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
