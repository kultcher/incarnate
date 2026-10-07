class_name PactDef
extends Resource
## One of Bound in Blood's Pacts (2014 version): a one-shot effect when bound
## to a struck foe. Each field is optional.

@export var display_name: String
@export var icon: Texture2D
@export_multiline var description: String
## Put on the bound foe, linked to the Bloodthane (Provoke, Cripple).
@export var foe_status: StatusDef
## Put on the Bloodthane (Dominance: +1 Armor until end of turn).
@export var self_status: StatusDef
## Health the bound foe loses (Vampiric).
@export var foe_health_loss: int = 0
## Health the Bloodthane heals (Vampiric).
@export var self_heal: int = 0
## Squares the Bloodthane may then shift (Predation).
@export var self_shift: int = 0

const COLOR := Color(1.0, 0.55, 0.55)


func bind(bloodthane: UnitState, foe: UnitState, r: ActionResolver) -> void:
	r.announce(foe, display_name, COLOR)
	if foe_status != null:
		await r.apply_status(foe, foe_status, bloodthane, bloodthane)
	if self_status != null:
		await r.apply_status(bloodthane, self_status, bloodthane)
	if foe_health_loss > 0:
		r.lose_health(foe, foe_health_loss)
	if self_heal > 0:
		r.heal(bloodthane, self_heal)
	if self_shift > 0 and bloodthane.is_alive():
		await _shift(bloodthane, r)


## Asks where to shift (one square per step for now: self_shift is 1).
func _shift(unit: UnitState, r: ActionResolver) -> void:
	var cells: Array[Vector2i] = []
	var labels: Array[String] = []
	var names := { Vector2i.UP: "Up", Vector2i.RIGHT: "Right", Vector2i.DOWN: "Down", Vector2i.LEFT: "Left" }
	for dir: Vector2i in BoardState.DIRECTIONS:
		var cell := unit.cell + dir
		if not r.board.blocks_move(cell) and not r.board.is_occupied(cell):
			cells.append(cell)
			labels.append(names[dir])
	if cells.is_empty():
		return
	var request := DecisionRequest.new()
	request.team = unit.team
	request.title = display_name
	request.icon = icon
	request.text = "%s may shift 1 square." % unit.def.display_name
	for label in labels:
		request.add_option("Shift " + label.to_lower())
	request.decline_label = "Stay"
	request.ai_choice = DecisionRequest.DECLINED
	var choice := await r.decide(request)
	if choice >= 0 and choice < cells.size():
		var path: Array[Vector2i] = [cells[choice]]
		await r.shift_unit(unit, path)
