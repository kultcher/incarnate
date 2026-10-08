# Incarnate

Tactical boss-fight game, rebuilt from *Boss Fight: Tactics Arena* (BFTA 4.0, 2023).
Godot 4.7, GDScript, Compatibility renderer.

- Architecture plan: https://claude.ai/code/artifact/60feca30-fc72-4d76-a80d-f6298d00c19c
- Design review: https://claude.ai/code/artifact/9c1310fd-512b-44a4-95eb-0c77d3bf29d9

## Status: milestone 6 (the Soulstream: card decks, hands and the shared row)

Run the project (F5) to open the test arena: your three Incarnates against
three Shamblers.

- Left-click one of your units to select it. Blue cells are where it can
  move; hover to preview the path, click to move.
- Each unit gets Move 1, Skill 1 and Flex 1 per turn. Flex pays for a second
  move or a second skill. Switch between units at any time.
- Skills: press **1**-**9** and **0**, or click the icon. Hover a skill for its
  cost, recharge and text. Greyed-out skills can't be used right now.
- Targeted skills ask for cells; right-click undoes a pick, then cancels.
- **Path skills** (Bloody Rush, Phantom Dash): click squares one at a time.
  The path may pass through foes but must end on an empty square. Click the
  last square again (or press **Enter**) to stop early.
- **Cards** (bottom right): click a card in the selected unit's hand or the
  shared Soulstream row to ready it for that unit's next skill; click again
  to put it back. See below.
- **Space** or **End Turn** ends your phase. **F9** toggles autoplay (the AI
  plays your side, prompts included).

### Damage: Soulstream cards

Skills strike for cards, e.g. "6 (Silver + Silver)": the number is the
average, and the cards are drawn when the skill lands. Bronze is 1-3, Silver
2-4, Gold 3-5.

- **Decks:** each tier is a 60-card deck: four suits (Blade, Orb, Portal,
  Ward), each with 5 low, 6 middle and 4 high cards. Discards are reshuffled
  in when a deck runs out. Enemies draw from their own decks.
- **Hands and the shared row:** at the start of your phase each Incarnate
  draws a Silver card (holding up to 2), and the shared row gets a card of a
  random tier (up to 3). Unspent cards carry over.
- **Readying:** click held or shared cards before using a skill. The skill
  uses them in place of its lowest-tier draws (any card can stand in for any
  tier) and draws the rest blind. Readied cards it doesn't need go back.
- The log under the round counter shows each strike's cards.
- Suits don't do anything yet; suit bonuses and Heroic versions come later.

- **Power**: +1 per point (raises a card a tier). Heals get it too.
- **Armor**: -1 per point on strikes against you. A strike always deals at least 1.
- **Evasion**: one dodge per round per point, used automatically. A dodge
  cancels the strike's lowest card; a one-card strike becomes a **graze** for 1.
- **Accuracy**: each point means the target needs one more dodge to dodge you.
- **Health loss** (Vampiric Pact, Violent Transfusion) isn't a strike: no
  Armor, no dodges.
- "Until end of turn" lasts until the next round starts, so it covers the
  enemy phase too.

### Bloodthane

| Skill | Cost | Recharge | What it does |
| --- | --- | --- | --- |
| Blade Fury | Skill | - | 4 (Br+Br); right after a move, +1 Power per 2 squares closed on the foe |
| Rending Claws | Skill | 2 | 6 (Si+Si), +1 Power per 2 damage already dealt this turn |
| Rage Strike | Skill | 3 | 7 (G+Si); recharges by 1 whenever a foe strikes you |
| Bloody Rush | Skill | 3 | Path of up to 3; strikes each foe passed or beside it for 3; 3+ foes: +1 Armor |
| Acute Coagulant | Skill | 1 | Heal 3; for 2 turns, heal 2 at end of turn and when struck for 2+ |
| Verve Magnet | Maneuver | 3 | You and a unit within 5 are pulled together or pushed apart 2; allies heal 1, foes lose 1 |
| Adrenal Surge | Skill | 4 | Ally within 4 refreshes a skill, gains a skill action, next standard skill isn't exhausted |
| Violent Transfusion | Recovery | - | A foe loses 8; an ally (or you) heals that much, +2 on a kill |
| Bloodrage | Free, once | - | Gain a skill action; strikes get +Power equal to damage dealt this turn |

**Bound in Blood** (passive): strike a foe you've already struck this turn and
you may bind a Pact to it, each Pact once per turn. **Dominance**: Provoke
the foe, +1 Armor. **Vampiric**: the foe loses 1, you heal 1. **Predation**:
Cripple the foe, then you may shift 1. Tick "Always choose this", or click
the passive's icon, to bind one Pact without being asked. (The 2014 trigger
is a Blade card on the strike; the two-strike rule stands in until suits
do something.)

### Traceless

**Illusive Shadows** (passive): every shift leaves a Shadow on the square you
left (at most 3; a new one replaces the oldest). Shadows don't block and
can't be struck. After you use an attack, you're asked whether a Shadow
copies it at a foe in reach; that Shadow is then used up. A Shadow can't
copy the same use of the skill that made it (a Displacer Strike's own
Shadow can't copy that Displacer Strike). Each Shadow is +1
Evasion (Probability Armor).

| Skill | Cost | Recharge | What it does |
| --- | --- | --- | --- |
| Displacer Strike | Skill | - | Shift up to 2 (through foes); strike an adjacent foe for 3 before or after. Copies reach 5 |
| Shadowstep | Free | - | Teleport to a Shadow, using it up |
| Gloom Edge | Skill | 2 | 6 (Si+Si); a foe struck by a copy is Blinded |
| Phantom Dash | Skill | 3 | Path of 2, +2 per foe passed through; strikes each foe passed for 3 |
| Chimeric Cloak | Skill | 3 | Prepare: negate the next strike or harmful status from a foe this turn (you're asked) |
| Mirage Shift | Maneuver | 3 | Shadow on an empty square within 6; swap with Shadows for free this turn |
| Shadow Swap | Free | - | After Mirage Shift: swap places with a Shadow, which stays |
| Tactical Distortion | Free | 3 | Mark a foe within 4: once this turn you may redirect its skill |
| Perfect Decoy | Free, Recovery | - | This turn, the first lethal strike on any ally is prevented and they heal 7 |
| Shadowstorm | Free, once | - | Put Shadows on any 3 empty squares; any number may copy each attack this turn |

Recovery skills: 2 per battle for the whole team. Statuses: **Provoked**
(the AI goes for whoever provoked it), **Crippled** (-2 move until its next
move), **Blinded** (its next strike counts as dodged).

**Soulweaver:** placeholder Strike until its kit is ported. **Shamblers:**
8 HP, move 3, Claw for 3 (Silver), one attack per turn. They're training
dummies: the AI clears them in 2 rounds.

Not in yet: Heroic versions, Talents, suit bonuses, Perfect Decoy's
teleport, and Titan Charge and the other Alpha-only skills. The AI uses
damage and healing skills but not the utility ones yet.

## Layout

| Folder | What lives there | May depend on |
| --- | --- | --- |
| `core/` | Rules and battle state as plain data: board, pathing, targeting, units, action points, the Soulstream (`core/cards/`), the resolver, the AI planner | `defs/` only |
| `defs/` | Resource scripts for content: `UnitDef`, `SkillDef`, `TargetStep`, effects, `StatusDef` and status behaviors | `core/` |
| `content/` | The `.tres` content files | `defs/`, `art/` |
| `battle/` | The battle scene, turn loop (`BattleController`), input (`PlayerController`), `EnemyAI`, spawn markers | everything |
| `view/` | Drawing: board, unit sprites, the Presenter that plays events in order | `core/`, `defs/` |
| `ui/` | HUD | `core/` via EventBus |
| `levels/` | Arena scenes | `view/`, `battle/` |
| `autoload/` | `EventBus`, the only autoload | `core/` |
| `tests/` | GUT tests: `unit/` for rules, `integration/` for the real scene | everything |
| `tools/` | Arena and kit builders, script checker, screenshot helper; `tools/dev/` has the autoplay stats scene | everything |
| `references/` | Design log, kit reference and the 2013-14 archive. Godot ignores it (`.gdignore`) | - |

## Editing the arena

`levels/test_arena.tscn` is a normal scene. Paint terrain on **Ground** and
obstacles on **Obstacles**. A tile blocks movement if its `blocks_move` custom
data is on, and `move_cost` sets the cost of entering it (rough terrain = 2).
Move or add **UnitSpawn** markers under **Spawns** to place units.

`tools/build_test_arena.gd` regenerates the arena and both tilesets from
scratch, which overwrites any edits.

## Tests

In the editor: open the **GUT** panel at the bottom and click **Run All**.

From a terminal:

```
godot --headless --path . -s addons/gut/gut_cmdln.gd
godot --headless --path . --script res://tools/check_scripts.gd
```

`check_scripts` compiles every project script and fails on any error. Run it
too: a script that fails to compile can make GUT skip tests without failing.

Strict typing is on: an untyped variable or loop variable is an error, not a warning.

## How a battle runs

`BattleController.run()` is the whole loop: player phase, enemy phase, next
round, until one side is gone. Each side is played by a `TurnDriver`: the
`PlayerController` (your input) or `EnemyAI`. They're interchangeable, which
is how autoplay works and how tests run whole battles with no input.

`AiPlanner` (in `core/ai/`) picks one action at a time: the best skill from
where the unit stands (each effect scores itself through `AiScore`: damage,
kills, wounded foes, Provoke, needed healing), else a move to a cell it can
attack from, else a move toward the nearest foe. Skills with no scoring
effect (most utility skills) are left alone for now. It uses the same `Pathing` and `Targeting` functions as the
player's highlights, so it can only choose legal actions.

## Statuses

Buffs, debuffs, passives and Pacts are all one thing: a `StatusDef` resource
(`content/statuses/`) with a duration, a stacking rule, optional stat
modifiers (`{ &"move": -2 }`), tags, and an optional **behavior** for
anything more. A behavior (`defs/statuses/behaviors/`) overrides hooks the
resolver calls: `on_turn_start`, `on_round_start`, `before_damage_taken`
(cancel or change a strike: Chimeric Cloak), `after_damage_taken`,
`after_damage_dealt` (Bound in Blood), `before_status_received` (block a
debuff), `on_moved` (Shadows), `before_skill_targets` (Tactical Distortion),
`after_skill` (Shadowstrike), `stat_bonus` (Evasion per Shadow).

- `clock` picks what counts the duration down: the owner's turns, or rounds
  (for "until end of turn").
- Tags drive simple rules: `taunt`, `debuff`, `blind`, `end_on_move`,
  `no_cooldown_next`.
- Stats are always computed (`unit.get_stat(&"armor")`), never overwritten.
- Statuses with a `link` end when the linked unit dies.
- Work that should happen after the current action (Pact and Shadowstrike
  prompts) goes on the resolver's follow-up queue.
- Choices go through `resolver.decide()`: the PromptDialog for the player, an
  instant pick for the AI, autoplay and tests.

## Adding a skill

A skill is a `SkillDef` resource in `content/skills/<unit>/`. It has:

- **targets**: one `TargetStep` per click. Each step has a shape (self,
  adjacent, within a range), where it's measured from, and what must be there
  (enemy, ally, empty, one of your Shadows...). A step can instead use a
  `TargetRule` for custom picks (Displacer Strike).
- **path**: for skills that shift along clicked squares, a `PathSpec`
  (budget, extra squares per foe passed) replaces the targets.
- **effects**: `EffectDef`s that run in order. `DamageEffect` strikes for a
  list of card tiers; a `PowerBonus` adds skill-specific Power. Others heal,
  apply statuses, shift, force, teleport, place Shadows...
- **cost** (Skill, Maneuver = move action, Free), **cooldown** (recharge),
  `uses_per_battle`, `requires_status`, and the Shadow-copy fields.
- **description**: `{damage}` and similar placeholders are filled in from the
  effects ("6 (Silver + Silver)"), so the text always matches the numbers.

The Bloodthane and Traceless kits are written by `tools/build_kits.gd`
(`godot --headless --path . --script res://tools/build_kits.gd`). The `.tres`
files are the source of truth after that; edit them in the editor. Re-running
the builder overwrites them.

For a quick balance check, run `tools/dev/autoplay_stats.tscn` (20 AI-vs-AI
battles with shuffled decks; prints outcomes and skill use).

## Conventions

- Shared enums live only in `core/enums.gd` (`Enums.Team`, `Enums.Cost`, ...).
- Occupancy lives only in `BoardState`. Never track it anywhere else.
- Sequence with `await`, never with timers.
- No `get_node("/root/...")` and no `call_group` for game logic. `battle.gd` passes references in.

## Art

Units and terrain come from BFTA 4.0. Unit sheets are one row per facing
(down, left, right, up). Set `sheet_columns` and `idle_column` on each `UnitDef`.
