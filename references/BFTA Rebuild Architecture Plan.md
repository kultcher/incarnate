# BFTA Rebuild: Architecture Plan

Oct 6, 2026 · @Michael Smith

## Goals and principles

The rebuild keeps BFTA 4.0's design, art and effects, and replaces its code with a base built on Godot 4.7 around five rules. Each rule exists because breaking it caused a specific bug class in 4.0.

1. **Rules run on data, nodes only display.** Battle state lives in plain objects (`RefCounted`/`Resource`), not in Area2D overlaps or node trees. This makes the rules testable without a scene, and lets the AI simulate moves on a copy.
2. **One owner per fact.** Occupancy lives only in the board model; HP and cooldowns only in the unit's state. 4.0 tracked occupancy three ways (Area2D overlap, `tile.occupied`, AStar solid points) and needed the collision-suppression workaround to keep them in sync.
3. **Sequence with `await`, never timers.** Every `create_timer(.1)` used for ordering goes away. Things happen in order because each step awaits the one before.
4. **Content is data.** Units, skills and statuses are `.tres` files built from a small set of reusable parts. Code is written only for a genuinely new mechanic, not for each skill.
5. **Commands in, events out.** Input and AI send requests in; the rules emit events out; views react to events. Nothing reaches across with `get_node("/root/...")` or `call_group`.

**Carried over from 4.0:** the Bloodthane and Traceless kits (as the spec), everything under `GFX/` and `SFX/`, the shaders and particle scenes, the combat text scene, and the BurstParticles2D addon if it still loads in 4.7. The old project stays untouched as a reference.

## Architecture at a glance

The game splits into four layers that only talk downward with calls and upward with events: controllers decide, the resolver applies rules, the model holds state, and views play it back.

&#91;embedded content: architecture · 4 layers, 12 parts\]

Controllers only send requests; the resolver is the one place rules run; views never touch the model, they only play back events.

**Autoloads.** Only one: `EventBus`, a script of signals for UI that just needs to refresh. No `Global` holding references to the level, camera or current actor. Anything battle-specific belongs to the battle scene and is passed in explicitly.

**Battle scene tree**

```
Battle (Node2D, battle.gd: builds BattleState, wires the parts together)
├─ BoardView (Node2D)
│  ├─ Ground (TileMapLayer)
│  ├─ Obstacles (TileMapLayer, custom data: blocks_move, move_cost)
│  ├─ Highlights (TileMapLayer, one tile per highlight kind)
│  └─ Units (Node2D, holds UnitView instances)
├─ Camera2D
├─ BattleController (Node, turn loop)
├─ ActionResolver (Node, rules pipeline)
├─ Presenter (Node, plays events in order)
├─ PlayerController (Node, input states)
├─ EnemyAI (Node)
└─ HUD (CanvasLayer)
   ├─ UnitPanel, SkillBar, TurnBanner
   └─ PromptDialog (Control, not Window)
```

## Board model

`BoardState` is the only object that knows what is on a cell; pathing, targeting, the AI and the highlights all ask it.

- **Cells are `Vector2i`.** `BoardState` holds `size`, `terrain: Dictionary[Vector2i, Terrain]` (move cost, blocks movement, blocks sight) and `occupant: Dictionary[Vector2i, UnitState]`. Moving a unit is one call, `board.move_unit(unit, to)`, which updates both the unit's `cell` and the occupant map.
- **Levels are still painted in the editor.** At battle start, `BoardState.from_layers()` reads the `Obstacles` TileMapLayer's custom data (`blocks_move`, `move_cost`). This replaces `get_used_cells(1)` on the deprecated `TileMap`.
- **No node per tile.** Clicks become cells with `BoardView.local_to_map(get_local_mouse_position())`. Highlights are `set_cell()` calls on the `Highlights` layer. That removes 144 Area2D tiles, each running `_process` every frame.
- **Range and paths come from one flood fill.** `Pathing.reachable(board, from, budget, rules) -> Dictionary[Vector2i, Step]` is a Dijkstra fill that records cost and previous cell. It gives the highlight set and the exact path to any highlighted cell. `MoveRules` says whether to pass through units (shift), allies only, or ignore terrain (flyers). This fixes 4.0's `pathfind_shift` bug, which only ignored units on the first step.
- **AStarGrid2D is kept for long paths only**, mainly the AI walking toward a distant target. Its solid points are terrain only; units are never written into it.
- **Targeting shapes are pure functions** in `Targeting`: `adjacent`, `within(min, max)`, `line(dir, length)`, `self`, plus a filter (enemy, ally, empty, any unit). The UI highlights exactly what the rules will accept, because both call the same function.

## Units

Each unit is split three ways: a `UnitDef` resource says what it is, a `UnitState` object tracks it during battle, and a `UnitView` scene draws it.

| Part | Kind | Holds |
| --- | --- | --- |
| `UnitDef` | Resource (`.tres`) | Name, portrait, `SpriteFrames`, max HP, base move, skills by slot, passive (a `StatusDef`), AI profile |
| `UnitState` | RefCounted | Def, team, cell, HP, action points, cooldowns, statuses, flags such as `summoned` |
| `UnitView` | Scene (Node2D) | AnimatedSprite2D, HP bar, selection ring; a `unit_id` linking it to its state |

- **Stats are computed, never overwritten.** `unit.get_stat(&"move")` returns the base value plus modifiers from active statuses. In 4.0, Predation Pact set `movement = base_movement - 1` directly, so two effects on the same stat would overwrite each other.
- **One action economy object.** Each turn a unit gets 1 move, 1 skill and 1 flex point. `ActionEconomy.can_pay(cost)` and `pay(cost)` handle the rule that flex covers either. Skill buttons ask `can_pay` instead of reading the `ANY / NO_MOVE / NO_SKILL / SPENT` enum.
- **Cooldowns key on the `SkillDef`**, not its display name, so renaming a skill can't break them.
- **Summons are ordinary units.** A Traceless Shadow is a `UnitState` with the `summoned` flag and its own small `UnitDef`, so it can be targeted, moved and removed like anything else.
- **Views never hold game logic.** A `UnitView` doesn't know its HP until the Presenter tells it to animate a change.

## Skills

A skill is a `.tres` that lists the targets the player picks and the effects that follow. One generic targeting flow and one resolver run every skill, so most new skills need no new code.

```gdscript
class_name SkillDef extends Resource
@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export_multiline var description: String   # "Strike twice for {damage} damage."
@export var slot: Enums.Slot                 # BASIC, HEAVY, AREA, DEF, MNVR, UTIL, ULT
@export var cost: Enums.Cost                 # MOVE, SKILL, FREE
@export var cooldown: int
@export var tags: Array[StringName]          # &"attack", &"melee", &"move"
@export var targets: Array[TargetStep]
@export var effects: Array[EffectDef]
```

- **`TargetStep`** is one click: shape and range, measured from the caster or the previous pick; a filter (enemy, ally, empty, any); a highlight kind; and `unique`, which stops the same cell being picked twice (the Bloody Rush TODO).
- **`EffectDef`** subclasses each do one thing: `Damage`, `Heal`, `ApplyStatus`, `Move` (walk, shift or teleport), `Push`/`Pull`, `Swap`, `Summon`, `ModifyCooldown`. Each has `func apply(ctx: ActionContext) -> void`, which may `await`.
- **Selectors say who an effect hits:** caster, the unit or cell from step N, or units on or next to the path walked. Selectors are what let Bloody Rush be data instead of a custom script.
- **Tooltips come from the data.** `{damage}` in the description is filled from the effect's value, so the text can't drift from the numbers. In 4.0 several tooltips already disagreed with their stats.
- **Escape hatch:** an `EffectDef` subclass with a custom script, for the rare mechanic that fits nothing else.

**Four 4.0 skills, expressed in the new format**

| Skill | Cost, cooldown | Targets (in click order) | Effects |
| --- | --- | --- | --- |
| Ravage | Skill, 2 | 1) adjacent enemy; 2) adjacent enemy | Damage 4 to step 1's unit; Damage 4 to step 2's unit |
| Bloody Rush | Skill, 3 | 1–3) cell adjacent to the previous pick, passable for shift, unique | Move (shift) caster along the picks; Damage 2 to each enemy on or next to the path |
| Displacer Strike | Skill, 0 | 1) empty cell within 2 (shift); 2) enemy adjacent to step 1 | Move (shift) caster to step 1; Damage to step 2's unit |
| Mirage Shift | Move, 3 | 1) empty cell within 6, not through obstacles | Summon Shadow at step 1; ApplyStatus "Shadow Swap" to caster |
|  |  |  |  |

## Action resolution

Every action, from the player or the AI, goes through `ActionResolver.resolve(request)`. It's a single `async` function, so its order is the order things happen; there is no `_process` queue and no timers.

A request is `{caster, skill, picks}`. The resolver then:

1. **Validates** the picks with the same `Targeting` functions that drew the highlights, and checks cost and cooldown. An invalid request is rejected before anything changes.
2. **Pays** the cost, starts the cooldown, and sends `ActionStarted` to the Presenter.
3. **Runs each effect in order.** Every effect goes through a *before* event, the change itself, then an *after* event:
   1. *Before* (e.g. `BeforeDamage`, with a changeable `amount`): statuses on the units involved may modify or cancel it. Chimeric Cloak halves the amount here.
   2. *Apply*: the model changes (`hp -= amount`) and the event goes to the Presenter.
   3. *After* (e.g. `DamageDealt`): statuses may queue follow-ups. Blood-bound stacks and the Pact prompt start here.
4. **Drains follow-ups** before the action ends: deaths, triggered effects, Shadow echoes. A depth limit (say 32) catches accidental infinite trigger loops.
5. **Finishes**: sends `ActionFinished`, waits for the Presenter to catch up, checks victory or defeat, returns.

**Decisions without pausing the tree.** When a rule needs a choice (use Chimeric Cloak? which Pact?), the resolver calls `await decisions.choose(request)`. The player's `DecisionProvider` shows `PromptDialog`; the AI's answers instantly. Before asking, the resolver awaits `presenter.idle` so the player sees the hit that caused the question. Nothing calls `get_tree().paused`.

**Triggers and reactions are the same system.** A trigger is a status hook that acts on its own (Bound in Blood). A reaction is a status hook that first asks its owner (Chimeric Cloak). Both are found by asking the units involved in the event, not by connecting and disconnecting signals the way 4.0's `can_react.get_connections()` did.

**Rules don't wait for animations mid-step.** The model updates immediately and the Presenter plays the events in order behind it. The rules only wait at a decision and at the end of an action. The same resolver can therefore run with no Presenter at all, which is how the AI simulates options and how tests run.

## Statuses, passives and triggers

Buffs, debuffs, passives and Pacts are all one thing, a status: a `StatusDef` resource for what it is and a `StatusInstance` for one copy on one unit.

- **`StatusDef`**: id, name, icon, description, duration (turns, or permanent), stacking rule (refresh, add stacks, or unique), stat modifiers (e.g. `move: -1`), skills it grants while active, and an optional behavior script.
- **`StatusInstance`**: def, owner, source, stacks, turns left, and `link`, another unit it's tied to (each Pact pairs a buff with a debuff).
- **Hooks are virtual methods** on `StatusBehavior`: `on_turn_start`, `on_before_damage_taken`, `on_after_damage_dealt`, `on_moved`, `on_action_finished`, `on_removed`. The resolver calls them on the statuses of the units in each event. Nothing connects to signals by hand.
- **A passive is a permanent status** applied at battle start from `UnitDef.passive`.
- **Statuses can grant skills.** This replaces 4.0's temporary flex buttons: the skill shows up on the normal skill bar while the status lasts.

**How the two kits map onto this**

- **Bound in Blood** (Bloodthane passive). `on_after_damage_dealt` adds a Blood-bound stack to the target. At 2 stacks, if the target has no Pact, it asks for a decision and applies the linked pair:
  - *Predation*: stat modifiers, `move -1` on the foe and `+1` on the Bloodthane.
  - *Vampiric*: the debuff's `on_turn_start` queues Damage 1 to its owner and Heal 1 to its link.
  - *Dominance*: a damage-taken modifier on the Bloodthane against its link, plus a `taunted_by` tag the AI reads when choosing targets.
- **Traceless Shadows.** A Shadow is a summoned unit. The Traceless passive's `on_action_finished` checks for a BASIC skill and queues an *echo*: the same skill cast by each Shadow, with the player picking its targets. Mirage Shift's "Shadow Swap" status grants a free "Swap with Shadow" skill until end of turn. That replaces the hand-built button and the `kill_shadow_at_tile` group call.

## Turn flow, input and AI

The turn loop is a plain async loop in `BattleController`; the only state machine left is the small one for player input.

```gdscript
func run_battle() -> void:
    while outcome == Outcome.NONE:
        await start_round()      # refresh action points, tick cooldowns, on_turn_start hooks
        await player_phase()     # returns when the player ends the turn
        if outcome != Outcome.NONE: break
        await enemy_phase()      # each enemy: ai.choose() then resolver.resolve()
        await end_round()        # expire statuses
```

This keeps 4.0's side-based turns: all player units act, then all enemies. Within the player phase, units spend their actions in any order: one unit sets something up, a second acts on it, and the first finishes its turn afterwards. A top-level loop reads better as code than as one node per state, and it removes the second state machine that 4.0's `Global` was creating.

**Player input states** (one script, one enum):

- **Idle**: clicking a unit selects it; hovering shows info.
- **UnitSelected**: the skill bar is live; clicking an empty reachable cell is a move shortcut.
- **Targeting(step *n*)**: highlights come from `Targeting` for step *n* given the earlier picks. Right-click or Esc steps back one pick, then cancels. After the last pick, the request goes to the resolver.
- **Busy**: input is ignored while the resolver or Presenter is working.

**Enemy AI** starts simple and grows. Each enemy builds candidate actions (reachable cell × usable skill × legal target) with the same rule functions the player uses. It scores them: damage dealt, kills, distance to target, and weight toward a `taunted_by` unit for Dominance Pact. Then it picks the best. The rules are data, so a later AI can try candidates on a cloned `BattleState` before choosing. 4.0's version picked a random target and trimmed the path with a `Vector2i(0, 0)` filter, which broke whenever a real tile sat at (0, 0).

## Presentation

The `Presenter` turns the resolver's events into animation, one after another, so what's on screen always matches the order the rules ran in.

- **A queue of events, each with a player function.** `UnitMoved` tweens the view along its path. `DamageDealt` plays the lunge, spawns the VFX scene, shows combat text and drops the HP bar. `StatusApplied` adds the icon. Each is a small `async` function, and the Presenter awaits them in turn.
- **Parallel groups.** Events that share a group id play together, so Bloody Rush's hits land at once rather than one by one.
- **`presenter.idle`** is a signal the resolver awaits before decisions and at the end of each action.
- **The HUD updates as each event plays**, not when the model changes. The Presenter re-broadcasts each event on `EventBus` as it plays it, so an HP number drops when the hit lands on screen, not before.
- **The skill bar is built from the unit's skills plus status-granted ones.** Enabled state comes from `ActionEconomy.can_pay` and the cooldown. Tooltips come from the filled-in `description`.
- **`PromptDialog` is a Control on the HUD layer** with a full-screen blocker behind it, not a `Window`. That avoids 4.0's embedded-subwindow and pause problems.
- **Animation tools:** Tweens for movement and lunges, `AnimatedSprite2D` for frames, and the existing particle and shader scenes for hits. Hover previews (path, predicted damage) come later and read from the same `Targeting` and `Pathing` functions.

## Folder layout and conventions

Folders follow the layers, so a file's location tells you what it may depend on: `core/` never references `view/` or `ui/`.

```
res://
├─ autoload/        event_bus.gd
├─ core/            enums.gd, board_state.gd, battle_state.gd, unit_state.gd,
│                   action_economy.gd, pathing.gd, targeting.gd
│  └─ resolve/      action_resolver.gd, action_context.gd, game_event.gd, decision_provider.gd
├─ defs/            unit_def.gd, skill_def.gd, target_step.gd, status_def.gd, status_behavior.gd
│  └─ effects/      damage.gd, heal.gd, apply_status.gd, move.gd, push_pull.gd, summon.gd ...
├─ content/         the .tres files: units/, skills/bloodthane/, skills/traceless/, statuses/
├─ battle/          battle.tscn, battle.gd, battle_controller.gd, player_controller.gd, enemy_ai.gd
├─ view/            board_view, unit_view, presenter.gd, vfx/
├─ ui/              hud, skill_bar, unit_panel, prompt_dialog, combat_text
├─ levels/          test_arena.tscn
├─ art/, audio/     moved over from 4.0's GFX/ and SFX/
└─ tests/           unit tests for core/ (GUT or gdUnit4)
```

- **Static typing everywhere.** Set the *Untyped Declaration* warning to error in Project Settings.
- **Enums live in one place**, `core/enums.gd` (`class_name Enums`), instead of being copied into five files.
- **`class_name` on every core type and def**, `StringName` ids for skills and statuses.
- **No absolute node paths, no `call_group` for game logic.** References are passed in by `battle.gd`; broadcasts go through `EventBus`.
- **Tests cover `core/` from day one.** It has no nodes, so tests are quick to write: pathing around obstacles, flex point rules, damage modifiers, Pact triggers.
- **Small commits on git**, one milestone per branch.

## Build order

Build in six milestones. Each ends in something playable, with a concrete test that must pass before the next starts.

&#91;embedded content: build order · 6 milestones, 6 gates\]

Milestone 2 is the real test of the architecture: once Ravage resolves and animates correctly, every later skill is mostly new `.tres` files.

**Moving content over.** The old project is the spec, read-only. Port one skill at a time: read its 4.0 script and `.tres`, write the new `.tres`, and add a test for its behavior. Where 4.0's tooltip and numbers disagree (Displacer Strike says 3 damage but deals 4; Acute Coagulant's text says 4 per tick, its data says 2), decide which is intended before porting. Skills not yet looked at closely: Blade Fury, Verve Magnet, Adrenaline Surge, Gloom Edge, Illusive Shadows. Soulweaver exists in 4.0 only as a stub.

## Open questions

- [x] **New project location:** a fresh `Incarnate` folder next to `BFTA 4.0`, with its own repo.
- [x] **Pact UX:** no Pact is selected by default. When Bound in Blood triggers, the player picks one; if a Pact is already selected, it applies without asking.
- [x] **Bloody Rush:** the three-step version.
- [x] **Shadow echoes:** start with the player picking each echo's targets, and revisit if it feels fiddly.
- [x] **Test framework:** GUT, chosen by Claude since you had no preference.
- [x] **Porting order:** Soulweaver and later Kindleborne port from their fairly complete 2014 kits. Golgothon is the first boss, after every player kit is done, Kindleborne included.
