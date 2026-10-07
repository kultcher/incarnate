extends Node
## Global signals for UI that only needs to refresh.
## Game rules never listen to these; they are emitted by the Presenter as
## events finish playing, so the HUD stays in step with what's on screen.

signal unit_selected(unit: UnitState)
signal unit_deselected()
signal unit_moved(unit: UnitState, path: Array[Vector2i])
signal actions_changed(unit: UnitState)
signal round_started(round_number: int)
signal phase_started(team: Enums.Team, round_number: int)
signal battle_ended(outcome: Enums.Outcome)
## True while the AI is playing the player's side (F9).
signal autoplay_changed(on: bool)
## Every player unit has spent its points: time to end the turn.
signal player_out_of_actions()
signal skill_used(unit: UnitState, skill: SkillDef)
signal unit_damaged(unit: UnitState, amount: int)
signal unit_died(unit: UnitState)
signal unit_healed(unit: UnitState, amount: int)
## A unit gained, lost or changed a status.
signal statuses_changed(unit: UnitState)
## The player is choosing step [param step] of [param skill]'s targets.
signal targeting_started(unit: UnitState, skill: SkillDef, step: int)
signal targeting_ended()
