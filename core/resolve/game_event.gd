class_name GameEvent
extends RefCounted
## Something that happened in the rules, for the Presenter to play back.
## Kept as one small class with a type tag until there are enough event
## kinds to justify subclasses.

const UNIT_MOVED := &"unit_moved"
const ACTIONS_CHANGED := &"actions_changed"
const SKILL_USED := &"skill_used"
const STRIKE := &"strike"
const DAMAGED := &"damaged"
const DIED := &"died"
const PHASE_STARTED := &"phase_started"
const BATTLE_ENDED := &"battle_ended"
const HEALED := &"healed"
const STATUS_APPLIED := &"status_applied"
const STATUS_REMOVED := &"status_removed"
const STATUS_CHANGED := &"status_changed"
const FLOATING_TEXT := &"floating_text"
const TELEPORTED := &"teleported"
const SHADOWS_CHANGED := &"shadows_changed"
const CARDS_CHANGED := &"cards_changed"
const UNIT_SPAWNED := &"unit_spawned"
const MARKS_CHANGED := &"marks_changed"
const SHADOWS_READY := &"shadows_ready"

var type: StringName
var unit: UnitState
## Second unit involved: the struck unit for STRIKE.
var target: UnitState
## UNIT_MOVED: the squares walked. TELEPORTED: the destination.
## SHADOWS_CHANGED: the owner's Shadows at that moment. STRIKE: the cell the
## strike comes from, when that isn't the attacker's (a Shadow's copy).
var path: Array[Vector2i] = []
var skill: SkillDef
var amount: int = 0
var melee: bool = false
## HP right after this hit. The view shows this, not the unit's current HP,
## which may already be lower by the time the event plays.
var hp_after: int = 0
## PHASE_STARTED: whose phase. CARDS_CHANGED: whose cards. [member amount] holds the round number.
var team: Enums.Team
var outcome: Enums.Outcome = Enums.Outcome.NONE
## STATUS_*: the instance. Its stacks are copied into [member amount] so the
## view shows the count at this moment.
var status: StatusInstance
var text: String = ""
var color := Color.WHITE
## MARKS_CHANGED: the marks' icon ([member text] is the mark id, [member path]
## its cells).
var icon: Texture2D


static func unit_moved(p_unit: UnitState, p_path: Array[Vector2i]) -> GameEvent:
	var e := _make(UNIT_MOVED, p_unit)
	e.path = p_path.duplicate()
	return e


static func actions_changed(p_unit: UnitState) -> GameEvent:
	return _make(ACTIONS_CHANGED, p_unit)


static func skill_used(p_unit: UnitState, p_skill: SkillDef, picks: Array[Vector2i]) -> GameEvent:
	var e := _make(SKILL_USED, p_unit)
	e.skill = p_skill
	e.path = picks.duplicate()
	return e


static func strike(attacker: UnitState, p_target: UnitState, hit: Hit) -> GameEvent:
	var e := _make(STRIKE, attacker)
	e.target = p_target
	e.melee = hit.melee
	e.skill = hit.skill
	e.amount = hit.amount
	e.text = hit.breakdown()
	if hit.spec.has_origin():
		e.path = [hit.spec.origin]
	return e


static func teleported(p_unit: UnitState, to: Vector2i) -> GameEvent:
	var e := _make(TELEPORTED, p_unit)
	e.path = [to]
	return e


static func unit_spawned(p_unit: UnitState) -> GameEvent:
	return _make(UNIT_SPAWNED, p_unit)


## [param p_unit]'s Shadows that can use an inherited skill now ([member path]).
static func shadows_ready(p_unit: UnitState, cells: Array[Vector2i]) -> GameEvent:
	var e := _make(SHADOWS_READY, p_unit)
	e.path = cells.duplicate()
	return e


static func marks_changed(id: StringName, cells: Array[Vector2i], p_icon: Texture2D) -> GameEvent:
	var e := _make(MARKS_CHANGED, null)
	e.text = String(id)
	e.path = cells.duplicate()
	e.icon = p_icon
	return e


## A hand or the shared row of [param p_team] changed.
static func cards_changed(p_team: Enums.Team) -> GameEvent:
	var e := _make(CARDS_CHANGED, null)
	e.team = p_team
	return e


static func shadows_changed(p_unit: UnitState) -> GameEvent:
	var e := _make(SHADOWS_CHANGED, p_unit)
	e.path = p_unit.shadows.duplicate()
	return e


## [param p_unit] lost [param p_amount] HP, leaving [param hp_after].
static func damaged(p_unit: UnitState, p_amount: int, hp_after: int, p_skill: SkillDef) -> GameEvent:
	var e := _make(DAMAGED, p_unit)
	e.amount = p_amount
	e.skill = p_skill
	e.hp_after = hp_after
	return e


static func died(p_unit: UnitState) -> GameEvent:
	return _make(DIED, p_unit)


## [param p_unit] regained [param p_amount] HP, reaching [param hp_now].
static func healed(p_unit: UnitState, p_amount: int, hp_now: int) -> GameEvent:
	var e := _make(HEALED, p_unit)
	e.amount = p_amount
	e.hp_after = hp_now
	return e


static func status_applied(inst: StatusInstance) -> GameEvent:
	return _status_event(STATUS_APPLIED, inst)


static func status_removed(inst: StatusInstance) -> GameEvent:
	return _status_event(STATUS_REMOVED, inst)


static func status_changed(inst: StatusInstance) -> GameEvent:
	return _status_event(STATUS_CHANGED, inst)


static func floating_text(p_unit: UnitState, p_text: String, p_color: Color) -> GameEvent:
	var e := _make(FLOATING_TEXT, p_unit)
	e.text = p_text
	e.color = p_color
	return e


static func _status_event(p_type: StringName, inst: StatusInstance) -> GameEvent:
	var e := _make(p_type, inst.owner)
	e.status = inst
	e.amount = inst.stacks
	return e


static func phase_started(p_team: Enums.Team, round_number: int) -> GameEvent:
	var e := _make(PHASE_STARTED, null)
	e.team = p_team
	e.amount = round_number
	return e


static func battle_ended(p_outcome: Enums.Outcome) -> GameEvent:
	var e := _make(BATTLE_ENDED, null)
	e.outcome = p_outcome
	return e


static func _make(p_type: StringName, p_unit: UnitState) -> GameEvent:
	var e := GameEvent.new()
	e.type = p_type
	e.unit = p_unit
	return e


func _to_string() -> String:
	return String(type)
