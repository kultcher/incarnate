extends GutTest
## Every Incarnate attack works against a Large (2x2) foe from every square
## around it: the foe is a legal pick (on any of its squares in reach) and
## the strike lands. Reach counts from the foe's nearest square, never its
## top-left one.

const KITS: Array[UnitDef] = [
	preload("res://content/units/bloodthane.tres"),
	preload("res://content/units/traceless.tres"),
	preload("res://content/units/soulweaver.tres"),
	preload("res://content/units/kindleborne.tres"),
]

const BOARD: Array[String] = [
	". . . . . . . .",
	". . . . . . . .",
	". . . . . . . .",
	". . . . . . . .",
	". . . . . . . .",
	". . . . . . . .",
	". . . . . . . .",
	"P . . . . . . .",
]
const BIG_AT := Vector2i(3, 3)


func _big() -> UnitDef:
	var def := BoardFixture.make_def()
	def.id = &"big_dummy"
	def.max_hp = 500
	def.footprint = 2
	return def


## Skills with one enemy pick (or Displacer Strike's foe-then-square picks).
func _attacks(kit: UnitDef) -> Array[SkillDef]:
	var out: Array[SkillDef] = []
	for skill in kit.skills:
		if not skill.has_tag(&"attack") or skill.is_path():
			continue
		if skill.targets.size() == 1 or skill.id == &"displacer_strike":
			out.append(skill)
	return out


func test_every_attack_reaches_a_large_foe_from_every_side() -> void:
	var failures: Array[String] = []
	for kit in KITS:
		for skill in _attacks(kit):
			var probe := TestRig.make(self, BOARD)
			var big := UnitState.new(_big(), Enums.Team.ENEMY)
			probe.board.place_unit(big, BIG_AT)
			for spot in probe.board.cells_around(big):
				var rig := TestRig.make(self, BOARD)
				await rig.equip(rig.player(), kit)
				var foe := UnitState.new(_big(), Enums.Team.ENEMY)
				rig.board.place_unit(foe, BIG_AT)
				rig.board.move_unit(rig.player(), spot)
				await rig.new_turn(rig.player())
				var picks := _picks(rig, skill, foe)
				if picks.is_empty():
					failures.append("%s from %s: no pick on the foe" % [skill.id, spot])
					continue
				if not await rig.resolver.request_skill(rig.player(), skill, picks):
					failures.append("%s from %s: rejected %s" % [skill.id, spot, picks])
					continue
				if foe.hp >= foe.def.max_hp:
					failures.append("%s from %s: no damage" % [skill.id, spot])
	assert_eq(failures, [] as Array[String], "\n".join(failures))


## A legal pick on [param foe] (and, for Displacer Strike, staying put).
func _picks(rig: TestRig, skill: SkillDef, foe: UnitState) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var first := Targeting.valid_cells(rig.board, rig.player(), skill, 0, out)
	for cell in rig.board.cells_of(foe):
		if first.has(cell):
			out.append(cell)
			break
	if out.is_empty():
		return out
	if skill.targets.size() == 2:
		var second := Targeting.valid_cells(rig.board, rig.player(), skill, 1, out)
		if not second.has(rig.player().cell):
			return [] as Array[Vector2i]
		out.append(rig.player().cell)
	return out


func test_every_square_of_a_large_foe_can_be_clicked_for_displacer_strike() -> void:
	var rig := TestRig.make(self, BOARD)
	await rig.equip(rig.player(), KITS[1])
	var foe := UnitState.new(_big(), Enums.Team.ENEMY)
	rig.board.place_unit(foe, BIG_AT)
	rig.board.move_unit(rig.player(), Vector2i(4, 5))  # South of the bottom-right square.
	var skill := rig.skill(rig.player(), &"displacer_strike")
	var cells := Targeting.valid_cells(rig.board, rig.player(), skill, 0, [] as Array[Vector2i])
	for cell in rig.board.cells_of(foe):
		assert_has(cells, cell)


func test_forced_movement_counts_from_the_nearest_square() -> void:
	var rig := TestRig.make(self, BOARD)
	var foe := UnitState.new(_big(), Enums.Team.ENEMY)
	rig.board.place_unit(foe, BIG_AT)
	rig.board.move_unit(rig.player(), Vector2i(4, 6))
	var pulled := await rig.resolver.force_unit(rig.player(),
			rig.board.nearest_cell(foe, rig.player().cell), 3, true)
	assert_eq(pulled, 1, "One square closes the gap to its bottom-right square")
	assert_eq(rig.board.distance_to(foe, rig.player().cell), 1)
