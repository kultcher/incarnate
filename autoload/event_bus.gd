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
## A strike landed: [param text] is its breakdown ("Silver Blade 4 + ...").
signal strike_shown(attacker: UnitState, target: UnitState, amount: int, text: String)
signal unit_died(unit: UnitState)
## A unit joined the battle mid-fight (a summon).
signal unit_spawned(unit: UnitState)
signal unit_healed(unit: UnitState, amount: int)
## A unit gained, lost or changed a status.
signal statuses_changed(unit: UnitState)
## A hand or the shared Soulstream row of [param team] changed.
signal cards_changed(team: Enums.Team)
## The player primed or unprimed cards for the selected unit's next skill.
signal cards_primed(cards: Array[Card])
## The player is choosing step [param step] of [param skill]'s targets.
signal targeting_started(unit: UnitState, skill: SkillDef, step: int)
signal targeting_ended()
## What the encounter's next enemy phase will do (empty: nothing to show).
signal intents_changed(intents: Array[Intent])
