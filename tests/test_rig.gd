class_name TestRig
extends RefCounted
## A resolver on a small ASCII board (see BoardFixture), with recorded
## events and scripted player answers. For rules tests.
##   var rig := TestRig.make(self, ["P E ."])

var fixture: BoardFixture
var board: BoardState
var resolver: ActionResolver
var log: TestEvents
var answers: TestAnswers


static func make(test: GutTest, rows: Array[String], move: int = 4) -> TestRig:
	var rig := TestRig.new()
	rig.fixture = BoardFixture.parse(rows, move)
	rig.board = rig.fixture.board
	rig.resolver = ActionResolver.new()
	rig.resolver.board = rig.board
	rig.log = TestEvents.new()
	rig.resolver.events = rig.log
	rig.answers = TestAnswers.new()
	rig.answers.log = rig.log
	rig.resolver.player_decisions = rig.answers
	for node: Node in [rig.resolver, rig.log, rig.answers]:
		test.add_child_autofree(node)
	return rig


## The first player unit (P on the map).
func player() -> UnitState:
	return fixture.mover


func ally(i: int = 0) -> UnitState:
	return fixture.allies[i]


func enemy(i: int = 0) -> UnitState:
	return fixture.enemies[i]


## Gives [param unit] a kit: its skills and passives, applied now. The
## unit keeps the fixture's health (12), so rules tests use small numbers
## whatever the kits' real health is.
func equip(unit: UnitState, kit: UnitDef) -> void:
	unit.def.skills = kit.skills.duplicate()
	for passive in kit.passives:
		await resolver.apply_status(unit, passive, unit)


func skill(unit: UnitState, id: StringName) -> SkillDef:
	for s in unit.skills():
		if s.id == id:
			return s
	return null


func use(unit: UnitState, id: StringName, picks: Array = []) -> bool:
	var typed: Array[Vector2i] = []
	typed.assign(picks)
	return await resolver.request_skill(unit, skill(unit, id), typed)


## Starts a fresh turn for [param unit] (as the battle loop would).
func new_turn(unit: UnitState) -> void:
	await resolver.start_turn(unit)


## A new round: "until end of turn" effects end.
func new_round() -> void:
	await resolver.start_round()


static func cells(list: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(list)
	return out


## A status for tests.
static func status(id: StringName, duration: int = 0,
		clock: Enums.StatusClock = Enums.StatusClock.OWNER_TURN) -> StatusDef:
	var st := StatusDef.new()
	st.id = id
	st.display_name = String(id)
	st.duration = duration
	st.clock = clock
	return st
