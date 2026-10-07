class_name Battle
extends Node2D
## Builds a battle from the arena scene, wires the parts together and starts
## the turn loop. Nothing else reaches into this node; parts get references
## from here.
##   F9   toggle autoplay: the AI plays your side too (for fast playtesting)

## Start with the AI playing the player's side (tests, balance runs).
@export var autoplay: bool = false

@onready var arena: BoardView = $Arena
@onready var camera: Camera2D = $Camera2D
@onready var battle_controller: BattleController = $BattleController
@onready var resolver: ActionResolver = $ActionResolver
@onready var presenter: Presenter = $Presenter
@onready var controller: PlayerController = $PlayerController
@onready var enemy_ai: EnemyAI = $EnemyAI
@onready var hud: Hud = $Hud

var board: BoardState
var player_decisions: PlayerDecisions


func _ready() -> void:
	board = BoardState.from_layers(arena.ground, arena.obstacles)

	presenter.board_view = arena
	resolver.board = board
	resolver.events = presenter
	controller.board = board
	controller.board_view = arena
	controller.resolver = resolver
	controller.presenter = presenter
	enemy_ai.board = board
	enemy_ai.resolver = resolver
	enemy_ai.presenter = presenter
	battle_controller.board = board
	battle_controller.resolver = resolver
	battle_controller.player_driver = controller
	battle_controller.enemy_driver = enemy_ai
	battle_controller.autoplay_driver = enemy_ai
	battle_controller.autoplay = autoplay
	player_decisions = PlayerDecisions.new()
	player_decisions.name = "PlayerDecisions"
	player_decisions.dialog = hud.prompt
	add_child(player_decisions)
	resolver.player_decisions = null if autoplay else player_decisions

	_spawn_units()
	_center_camera()

	hud.can_use = func(unit: UnitState, skill: SkillDef) -> bool:
		return resolver.can_use(unit, skill) and resolver.has_targets(unit, skill)
	hud.end_turn_pressed.connect(controller.request_end_turn)
	hud.skill_pressed.connect(controller.begin_targeting_index)
	hud.restart_pressed.connect(_restart)
	hud.status_clicked.connect(_on_status_clicked)
	battle_controller.run()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo() \
			and (event as InputEventKey).keycode == KEY_F9:
		set_autoplay(not battle_controller.autoplay)
		get_viewport().set_input_as_handled()


## Lets the AI play the player's side. Switching it on during your phase
## hands the rest of the phase to the AI.
func set_autoplay(on: bool) -> void:
	battle_controller.autoplay = on
	# Autoplay answers the player's prompts too (AI choices, no dialog).
	resolver.player_decisions = null if on else player_decisions
	EventBus.autoplay_changed.emit(on)
	if on:
		controller.request_end_turn()


func _spawn_units() -> void:
	for spawn: UnitSpawn in arena.spawns_root.get_children():
		if spawn.def == null:
			push_warning("Spawn %s has no unit def." % spawn.name)
			continue
		var cell := arena.local_to_cell(spawn.position)
		var unit := UnitState.new(spawn.def, spawn.team)
		board.place_unit(unit, cell)

		var view := UnitView.new()
		view.setup(unit)
		view.position = arena.cell_to_local(cell)
		arena.units_root.add_child(view)
		presenter.register(unit, view)
	arena.spawns_root.queue_free()


func _center_camera() -> void:
	var rect := arena.pixel_rect()
	camera.position = arena.position + rect.get_center() + Vector2(0, 30)


## Bound in Blood: choose a Pact to bind automatically, or "ask each time".
func _on_status_clicked(inst: StatusInstance) -> void:
	var bib := inst.def.behavior as BoundInBloodBehavior
	if bib == null or hud.prompt.is_open() or not inst.owner.is_player():
		return
	var request := DecisionRequest.new()
	request.title = "Pact preference"
	request.icon = inst.def.icon
	request.text = "Bind this Pact automatically whenever %s can bind one?" % inst.owner.def.display_name
	for pact in bib.pacts:
		request.add_option(pact.display_name, pact.description, pact.icon)
	request.decline_label = "Ask me each time"
	var answer := await hud.prompt.ask(request)
	inst.choice = answer
	EventBus.statuses_changed.emit(inst.owner)


func _restart() -> void:
	get_tree().reload_current_scene()
