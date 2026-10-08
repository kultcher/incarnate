class_name BattleStats
extends RefCounted
## Per-unit totals for the end-of-battle report: damage dealt (strikes and
## health loss to foes), healing done, shield given, actions taken, squares
## moved and Soulstream cards used. Units whose def has report_as_group (the
## Welcoming Dead) are summed into one row that tracks damage, how many were
## spawned and how many were slain. The resolver records; the HUD reads
## rows() and report().

class Row:
	var name: String
	var team: Enums.Team
	var group: bool = false
	var damage: int = 0
	var healing: int = 0
	var shield: int = 0
	var actions: int = 0
	var moved: int = 0
	## Soulstream cards activated or spent on a boon.
	var cards: int = 0
	## Group rows: units spawned and slain.
	var spawned: int = 0
	var slain: int = 0

var _rows: Dictionary[String, Row] = {}
## Row keys in the order units first appeared.
var _order: Array[String] = []


func record_damage(source: UnitState, target: UnitState, amount: int) -> void:
	if source == null or amount <= 0 or not source.is_foe(target):
		return
	_row(source).damage += amount


func record_heal(healer: UnitState, amount: int) -> void:
	if healer != null and amount > 0:
		_row(healer).healing += amount


func record_shield(source: UnitState, amount: int) -> void:
	if source != null and amount > 0:
		_row(source).shield += amount


func record_action(unit: UnitState) -> void:
	if unit != null:
		_row(unit).actions += 1


func record_moved(unit: UnitState, squares: int) -> void:
	if unit != null and squares > 0:
		_row(unit).moved += squares


func record_card(unit: UnitState) -> void:
	if unit != null:
		_row(unit).cards += 1


func record_spawned(unit: UnitState) -> void:
	_row(unit).spawned += 1


func record_slain(unit: UnitState) -> void:
	_row(unit).slain += 1


## Makes sure [param unit] has a row (so units that did nothing still show).
func track(unit: UnitState) -> void:
	_row(unit)


func rows() -> Array[Row]:
	var out: Array[Row] = []
	for key in _order:
		out.append(_rows[key])
	return out


## "Welcoming Dead: 24 spawned, 15 slain", one line per group row.
func group_lines() -> Array[String]:
	var lines: Array[String] = []
	for row in rows():
		if row.group:
			lines.append("%s: %d spawned, %d slain" % [row.name.trim_suffix(" (all)"),
					row.spawned, row.slain])
	return lines


## A plain-text table, for the console or a bug report.
func report() -> String:
	var lines: Array[String] = ["%-20s %6s %6s %6s %7s %6s %5s" % [
			"Unit", "Damage", "Healed", "Shield", "Actions", "Moved", "Cards"]]
	for row in rows():
		if row.group:
			lines.append("%-20s %6d" % [row.name, row.damage])
		else:
			lines.append("%-20s %6d %6d %6d %7d %6d %5d" % [row.name, row.damage,
					row.healing, row.shield, row.actions, row.moved, row.cards])
	lines.append_array(group_lines())
	return "\n".join(lines)


func _row(unit: UnitState) -> Row:
	if unit.shadow_of != null:
		unit = unit.shadow_of
	var group := unit.def.report_as_group
	var key := ("group:%s" % unit.def.id) if group else ("unit:%d" % unit.id)
	if not _rows.has(key):
		var row := Row.new()
		row.name = unit.def.display_name + (" (all)" if group else "")
		row.team = unit.team
		row.group = group
		_rows[key] = row
		_order.append(key)
	return _rows[key]
