class_name UnitState
extends RefCounted
## A unit during battle. Plain data: no nodes, no drawing.

static var _next_id: int = 1

var id: int
var def: UnitDef
var team: Enums.Team
var cell: Vector2i
var hp: int
var actions: ActionEconomy
## Turns left before each skill can be used again, keyed by skill id.
var cooldowns: Dictionary[StringName, int] = {}
## Times each skill has been used this battle (Ultimates: once per battle).
var uses: Dictionary[StringName, int] = {}
## Buffs, debuffs, passives and Pacts on this unit. Change them only through
## the resolver (apply_status / remove_status) so the view hears about it.
var statuses: Array[StatusInstance] = []
## The Traceless's Shadows, oldest first. Shadows don't block anything and
## can't be targeted; they belong to the unit that made them. Change them
## only through the resolver.
var shadows: Array[Vector2i] = []
## The action (ActionResolver.action_number) each Shadow was made in,
## missing if none. A Shadow can't copy the same use of a skill that made it.
var shadow_made_in: Dictionary[Vector2i, int] = {}
## Soulstream cards this Incarnate holds (see Soulstream). Enemies hold none.
## Change it only through the resolver.
var hand: Array[Card] = []

#region This turn
## Reset at the start of the unit's turn.

## Where the unit stood when its turn started.
var turn_start_cell: Vector2i
## Damage this unit's strikes have dealt this turn (Rending Claws, Bloodrage).
var turn_damage: int = 0
## Strikes this unit has landed on each foe this turn, by unit id.
var turn_strikes: Dictionary[int, int] = {}
## The unit's last action was a move (Blade Fury's bonus).
var last_action_was_move: bool = false
## Dodges spent since the unit's turn started.
var dodges_used: int = 0
#endregion


func _init(p_def: UnitDef, p_team: Enums.Team) -> void:
	id = _next_id
	_next_id += 1
	def = p_def
	team = p_team
	hp = p_def.max_hp
	actions = ActionEconomy.new(1, 1, p_def.flex_points)


## Base stat plus modifiers from statuses. Never stored: a stat is always
## recomputed, so two effects on the same stat can't overwrite each other.
func get_stat(stat: StringName) -> int:
	var value := 0
	match stat:
		&"move":
			value = def.move
		&"max_hp":
			value = def.max_hp
		&"power":
			value = def.power
		&"armor":
			value = def.armor
		&"evasion":
			value = def.evasion
		&"accuracy":
			value = def.accuracy
		&"strike_power":
			value = 0  # Power for strikes only, not heals (Bloodrage).
		_:
			push_error("Unknown stat: %s" % stat)
			return 0
	var counted: Dictionary[StringName, bool] = {}
	for inst in statuses:
		if inst.def.behavior != null:
			value += inst.def.behavior.stat_bonus(inst, stat)
		if not inst.def.stat_mods.has(stat):
			continue
		if not inst.def.stat_mods_stack:
			if counted.has(inst.def.id):
				continue
			counted[inst.def.id] = true
		value += inst.def.stat_mods[stat] * inst.stacks
	return maxi(value, 0)


## Dodges left this round.
func dodges_left() -> int:
	return maxi(get_stat(&"evasion") - dodges_used, 0)


func find_status(status_id: StringName) -> StatusInstance:
	for inst in statuses:
		if inst.def.id == status_id:
			return inst
	return null


func has_status(status_id: StringName) -> bool:
	return find_status(status_id) != null


func find_status_tag(tag: StringName) -> StatusInstance:
	for inst in statuses:
		if inst.def.has_tag(tag):
			return inst
	return null


func has_status_tag(tag: StringName) -> bool:
	return find_status_tag(tag) != null


func is_player() -> bool:
	return team == Enums.Team.PLAYER


func is_alive() -> bool:
	return hp > 0


func is_foe(other: UnitState) -> bool:
	return other != null and other.team != team


## The unit's own skills, then any its statuses grant (Elusive Infusion).
func skills() -> Array[SkillDef]:
	var granted: Array[SkillDef] = []
	for inst in statuses:
		var extra := inst.def.grants_skill
		if extra != null and not def.skills.has(extra) and not granted.has(extra):
			granted.append(extra)
	if granted.is_empty():
		return def.skills
	var all := def.skills.duplicate()
	all.append_array(granted)
	return all


func cooldown_left(skill: SkillDef) -> int:
	return cooldowns.get(skill.id, 0)


func strikes_on(foe: UnitState) -> int:
	return turn_strikes.get(foe.id, 0)


## Start-of-turn upkeep: refresh action points, tick cooldowns down, forget
## last turn. Status hooks and durations are run by ActionResolver.start_turn.
func start_turn() -> void:
	actions.refresh()
	for key: StringName in cooldowns.keys():
		cooldowns[key] = maxi(cooldowns[key] - 1, 0)
	turn_start_cell = cell
	turn_damage = 0
	turn_strikes.clear()
	last_action_was_move = false
	dodges_used = 0


func _to_string() -> String:
	return "%s#%d@%s" % [def.display_name, id, cell]
