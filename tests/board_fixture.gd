class_name BoardFixture
extends RefCounted
## Builds small boards from ASCII maps for tests.
##   .  open ground        #  blocked terrain     ~  rough (move cost 2)
##   P  player unit (the mover, first one found)
##   A  another player unit (ally)
##   E  enemy unit
## Units on special cells stand on open ground.

var board: BoardState
var mover: UnitState
var allies: Array[UnitState] = []
var enemies: Array[UnitState] = []


static func parse(rows: Array[String], move: int = 4) -> BoardFixture:
	var f := BoardFixture.new()
	var height := rows.size()
	var width := rows[0].replace(" ", "").length()
	f.board = BoardState.new(Vector2i(width, height))
	for y in height:
		var row := rows[y].replace(" ", "")
		for x in width:
			var cell := Vector2i(x, y)
			match row[x]:
				"#":
					f.board.set_terrain(cell, Terrain.new(true))
				"~":
					f.board.set_terrain(cell, Terrain.new(false, 2))
				"P":
					f.mover = f._add(cell, Enums.Team.PLAYER, move)
				"A":
					f.allies.append(f._add(cell, Enums.Team.PLAYER, move))
				"E":
					f.enemies.append(f._add(cell, Enums.Team.ENEMY, move))
	return f


static func make_def(move: int = 4) -> UnitDef:
	var def := UnitDef.new()
	def.id = &"test_unit"
	def.display_name = "Test Unit"
	def.max_hp = 12
	def.move = move
	return def


func _add(cell: Vector2i, team: Enums.Team, move: int) -> UnitState:
	var unit := UnitState.new(make_def(move), team)
	board.place_unit(unit, cell)
	return unit
