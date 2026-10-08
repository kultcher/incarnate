class_name Tethers
extends RefCounted
## The Soulweaver's Tether (Fates Intertwined). The Soulweaver carries
## TETHER linked to its ally; the ally carries TETHERED linked back, so either
## one dying ends both. Under Anima Nexus, "a Tethered ally" means every ally.

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


static func is_tethered(unit: UnitState, ally: UnitState, board: BoardState) -> bool:
	return allies_of(unit, board).has(ally)


## [param unit] and its Tethered allies, the unit first.
static func with_allies(unit: UnitState, board: BoardState) -> Array[UnitState]:
	var out: Array[UnitState] = [unit]
	out.append_array(allies_of(unit, board))
	return out
