class_name Tethers
extends RefCounted
## The Soulweaver's Tether (Fates Intertwined). The Soulweaver carries
## TETHER linked to its ally; the ally carries TETHERED linked back, so either
## one dying ends both. Under Anima Nexus, "a Tethered ally" means every ally,
## and anything the Soulweaver does to one ally reaches every ally (fan_out).

const TETHER := &"tether"
const TETHERED := &"tethered"
const NEXUS := &"anima_nexus"


## The allies [param unit] counts as Tethered to right now.
static func allies_of(unit: UnitState, board: BoardState) -> Array[UnitState]:
	var out: Array[UnitState] = []
	if unit.has_status(NEXUS):
		for other in board.units():
			if other != unit and other.team == unit.team and other.is_alive():
				out.append(other)
		return out
	for inst in unit.statuses:
		if inst.def.id == TETHER and inst.link != null and inst.link.is_alive():
			out.append(inst.link)
	return out


## Who an effect the Soulweaver aims at [param ally] reaches: just that ally,
## or every ally under Anima Nexus (the Soulweaver itself only if aimed at).
static func fan_out(caster: UnitState, ally: UnitState, board: BoardState) -> Array[UnitState]:
	var out: Array[UnitState] = [ally]
	if ally == null or ally == caster or caster.is_foe(ally) or not caster.has_status(NEXUS):
		return out
	for other in board.units():
		if other != caster and other != ally and other.team == caster.team and other.is_alive():
			out.append(other)
	return out


static func is_tethered(unit: UnitState, ally: UnitState, board: BoardState) -> bool:
	return allies_of(unit, board).has(ally)


## [param unit] and its Tethered allies, the unit first.
static func with_allies(unit: UnitState, board: BoardState) -> Array[UnitState]:
	var out: Array[UnitState] = [unit]
	out.append_array(allies_of(unit, board))
	return out
