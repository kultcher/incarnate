class_name StatusInstance
extends RefCounted
## One copy of a status on one unit.

var def: StatusDef
## The unit carrying it. Held weakly (like source and link): the unit holds
## its statuses, and Pacts link units to each other, so strong references
## would keep dead units alive in a cycle.
var owner: UnitState:
	get: return _owner.get_ref() as UnitState
## Who applied it (may be the owner, or null for battle-start passives).
var source: UnitState:
	get: return _source.get_ref() as UnitState if _source != null else null
var stacks: int = 1
## Owner's turns left. Ignored when def.duration is 0 (permanent).
var turns_left: int = 0
## Another unit this status is tied to. Each Pact pairs a debuff on the foe
## (linked to the Bloodthane) with a buff on the Bloodthane (linked to the
## foe). Linked statuses end when their link dies.
var link: UnitState:
	get: return _link.get_ref() as UnitState if _link != null else null
## A remembered player choice, e.g. Bound in Blood's preferred Pact.
## -1 = none (ask each time).
var choice: int = -1
## Scratch state for the status's behavior (Pacts bound this turn, whether
## a once-per-turn effect has been used...).
var data: Dictionary = {}

var _owner: WeakRef
var _source: WeakRef
var _link: WeakRef


func _init(p_def: StatusDef, p_owner: UnitState, p_source: UnitState = null,
		p_link: UnitState = null) -> void:
	def = p_def
	_owner = weakref(p_owner)
	_source = weakref(p_source) if p_source != null else null
	_link = weakref(p_link) if p_link != null else null
	turns_left = p_def.duration


func is_permanent() -> bool:
	return def.duration <= 0


func describe() -> String:
	var text := def.description
	if def.behavior != null:
		var values := def.behavior.describe_values()
		for key: String in values:
			text = text.replace("{%s}" % key, str(values[key]))
	return text


func _to_string() -> String:
	return "%s(x%d)" % [def.id, stacks]
