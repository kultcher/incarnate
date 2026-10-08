# Incarnate

Tactical boss-fight game, rebuilt from *Boss Fight: Tactics Arena* (BFTA 4.0, 2023).
Godot 4.7, GDScript, Compatibility renderer.

- Architecture plan: https://claude.ai/code/artifact/60feca30-fc72-4d76-a80d-f6298d00c19c
- Design review: https://claude.ai/code/artifact/9c1310fd-512b-44a4-95eb-0c77d3bf29d9

## Status: milestone 10 (suit Soulstream, flat numbers)

Run the project (F5) and pick a battle from the menu:

- **Golgothon the Restless**: the first boss (see below).
- **Test arena**: your four Incarnates against three Shamblers, a sandbox.

Incarnates have **40 health**, the scale the 2014 cards were written for.

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
- **Cards** (bottom left, beside the skill bar): **double-click** a card in
  the selected unit's hand or the shared Soulstream row to activate it;
  **click** to prime it for that unit's next skill. See below.
- The selected unit's health, actions, Heat and statuses sit in their own
  panel to the right of the skill bar.
- **Space** or **End Turn** ends your phase; if a unit still has actions
  left you're asked first. **F9** toggles autoplay (the AI plays your side,
  prompts included).
- A green **FREE** badge marks a skill that a status makes free right now
  (Potent, Spirit Flare's replay, Ignite, a Burnout echo).
- Ultimates and Recovery skills ask for confirmation before they go off.
- Automatic choices (a recharge, Heat spent, a knockback resisted) show as
  floating text and in the log.
- When the battle ends, the end screen (and the console) shows a report:
  damage, healing, shield given, actions, squares moved and cards used for
  each unit. The Welcoming Dead share one damage row, with how many were
  spawned and slain.

### Numbers and the Soulstream

Spec: `references/soulstream-spec.md`.

**Numbers are flat.** Skills still use the 2014 tier notation internally,
read as fixed values: Bronze 2, Silver 3, Gold 4. "(Si)(Si)" strikes for 6.
The skill update pass will write plain numbers, boons and Heroics.

**Cards are suits.** One 60-card deck per side: 9 each of Blade, Ward, Orb
and Portal, 4 Wilds, and 2 of each two-suit pair including doubles (Blade x2,
Blade + Ward...). Discards are reshuffled in when it runs out.

- **Hands and the shared row:** at the start of your phase each Incarnate
  draws a card (hands hold 2: a third draw activates the oldest card first),
  and the shared row gets a card (up to 3). Any Incarnate can use a row card.
- **Double-click: activate** for the card's base effect, once per suit
  (free). A Wild asks which suit.
  - **Blade:** +1 damage on your next attack.
  - **Ward:** +2 Shield until end of turn.
  - **Portal:** +1 move until end of turn.
  - **Orb:** recharge a skill by 1.
- **Click: prime** for the unit's next skill. A skill with a boon suit
  spends one matching card for its **boon** and two (or one double) for its
  **Heroic**. No skill has a boon yet, so primed cards stay in the hand.
- **Flips:** only specific effects flip cards. So far that's Fates
  Intertwined (Soulweaver).

- **Power**: +1 per point. Heals get it too.
- **Armor**: -1 per point on strikes against you. A strike always deals at least 1.
- **Evasion**: one dodge per round per point, used automatically. A dodge
  cancels the strike's smallest part (one per tier); a one-part strike
  becomes a **graze** for 1.
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
can't be struck. When you use Displacer Strike, Gloom Edge or Phantom Dash,
each Shadow already on the board **inherits** it until end of turn (the
Shadow that same use made doesn't). Click a Shadow (they glow when one has
a skill with a target) to see its skills and use one from its square, for
free, as if it were the Traceless; the Shadow then fades. A Shadow's
Displacer Strike shifts 2 squares further, and moves the Shadow. Each
Shadow is +1 Evasion (Probability Armor).

| Skill | Cost | Recharge | What it does |
| --- | --- | --- | --- |
| Displacer Strike | Skill | - | Shift up to 2 (through foes); strike an adjacent foe for 3 before or after. Shadows shift 4 |
| Shadowstep | Free | - | Teleport to a Shadow, using it up |
| Gloom Edge | Skill | 2 | 6 (Si+Si); a foe struck by a Shadow's Gloom Edge is Blinded |
| Phantom Dash | Skill | 3 | Path of 2, +2 per foe passed through; strikes each foe passed for 3 |
| Chimeric Cloak | Skill | 3 | Prepare: negate the next strike or harmful status from a foe this turn (you're asked) |
| Mirage Shift | Maneuver | 3 | Shadow on an empty square within 6; swap with Shadows for free this turn |
| Shadow Swap | Free | - | After Mirage Shift: swap places with a Shadow, which stays |
| Tactical Distortion | Free | 3 | Mark a foe within 4: once this turn you may redirect its skill |
| Perfect Decoy | Free, Recovery | - | This turn, the first lethal strike on any ally is prevented and they heal 7 |
| Shadowstorm | Free, once | - | Put Shadows on any 3 empty squares; this turn Shadows don't fade, each can use each inherited skill once |

Recovery skills: 2 per battle for the whole team. Statuses: **Provoked**
(the AI goes for whoever provoked it), **Crippled** (-2 move until its next
move), **Blinded** (its next strike counts as dodged).

### Soulweaver

**Fates Intertwined** (passive): use **Tether** (free, once per turn) to
Tether yourself to an ally within 5. At the start of your turn you flip the
top Soulstream card, and its suit's Infusion goes to you and your Tethered
ally, with no prompt. An ally you Tether later that turn gets it too.
- Blade: **Potent** (a free basic attack this turn).
- Ward: **Stalwart** (shield 1).
- Orb: **Sage** (recharge a skill by 1).
- Portal: **Elusive** (a free shift of 2: Elusive Shift appears on the bar).

A two-suit card brings both Infusions; a Wild lets you pick.

| Skill | Cost | Recharge | What it does |
| --- | --- | --- | --- |
| Spirit Flare | Skill | - | Strike a foe within 4 for 3 (Si), or heal an ally within 4 for 3. After a kill or healing an ally to full, the next one this turn is free (once per turn) |
| Tether | Free | 1 | Tether to an ally within 5 |
| Soul Echo | Skill | 2 | Strike a foe within 4 for 6 (Si+Si), +2 Power per Blade in the shared row (a Blade x2 counts twice, a Wild once) |
| Dread Diffusion | Skill | 3 | Strike a foe within 4 for 5 (Si+Br), force it 3 away; foes next to its path take 2 (Br) and are forced 1 |
| Strength in Unity | Skill | 3 | Shield you and an ally within 5 against 4 (G) each this turn; recharges by 1 if that ally is Tethered |
| Essence Shift | Maneuver | 3 | Teleport next to your Tethered ally, or they teleport next to you |
| Well of Souls | Skill | 3 | You and your Tethered ally may each take a card from the shared row into your hand |
| Conveyance | Recovery | - | Choose an ally within 5; each other ally (you included) may lose 1; they heal 6 (Si+Si) per health lost |
| Anima Nexus | Free, once | - | This turn, everything that reaches your Tethered ally, and your heals and shields on any ally, reach every ally |

**Shields** absorb damage from strikes (not health loss) until used up or the
turn ends; more shielding adds to the same shield.

### Kindleborne

**Rising Heat** (passive, provisional rework): each skill you pay an action
for adds 1 **Heat** (up to 5, shown in the unit panel). Ignited skills,
Burnout replays and free skills add none. **Stoke** (free) spends it:
- **Ignite** (2 Heat, one more for each Ignite this turn) makes your next
  skill this turn cost no action.
- **Dissipate** (2 Heat) heals 3 and gives +1 Evasion this turn.

| Skill | Cost | Recharge | What it does |
| --- | --- | --- | --- |
| Tinderbolt | Skill | - | Strike a foe within 4 for 2 (Br), +1 Power per attack skill already used this turn |
| Stoke | Free | - | Ignite or Dissipate (needs 2+ Heat) |
| Wracking Flame | Skill | 2 | Strike a foe within 4 for 6 (Si+Si), +1 Power per Heat |
| Stoking Blast | Skill | 2 | Strike a foe within 4 for 6 (Si+Si); recharges by 1 if Ignited |
| Cinder Wave | Skill | 2 | Strike each foe in a wave 3 wide and 4 deep for 3 (Si). Hover a direction to see it |
| Ember Shield | Skill | 3 | Shield yourself against 4 (G); this turn, strike back for 3 (Si) whenever a foe strikes you |
| Flickerstep | Maneuver | 4 | Teleport up to 6 (G + 2) this turn (Flicker, free). Recharges by 1 whenever you Ignite |
| Ash Augur | Free | 3 | Gain 2 Heat |
| Cauterizing Brand | Recovery | - | An ally (or you) loses 3 (Si) more each time a strike damages them this turn; at end of turn, heal 12 (G+G+G) |
| Burnout | Free, once | - | The next 3 skills you Ignite this turn can each be used once more for free, ignoring recharge |

**Shamblers:** 8 HP, move 3, Claw for 3 (Silver), one attack per turn.
They're training dummies. The Kindleborne's sprite is a recolored
Soulweaver for now.

### Golgothon the Restless

A Large (2x2) graveyard elemental with 300 health, from the 2013 encounter
booklet and the 2014 boss cards (`references/golgothon-reference.md`).
**During your phase, the panel under End Turn and the board show what he
will do**, and they update as you act.

| Round | He does |
| --- | --- |
| 2, 5, 8... | **Death's Grasp**: strikes everyone within 6 for 2 (Br), then pulls them 5 toward him |
| 3, 6, 9... | **Death's Caress**: everyone within 6 loses 7 minus their distance (the numbers on the board) |
| 4, 7, 10... | **Unquenched**: +1 Power; gravestones rise as Welcoming Dead (1 health each from him) |
| Every round | **Grave Smash** (moves 4 toward whoever hurt him most this turn, tramples, strikes 8 and Dazes; else Spews), **Carrion Spew** (5 to the healthiest in range 6, knocked 1 square), **Welcoming Dead** (3 minions around whoever is furthest) |

**Welcoming Dead:** 5 health, strike for 2. Two next to you hold you in
place (no walking or shifting; teleports work). Slain ones leave a gravestone.
Unquenched makes them move and hit harder. **Daze:** your cooldowns don't
tick next turn. Golgothon has **Resolve 2** (the first of each debuff is
absorbed), **Sturdy 1** and **Trample**. Killing him wins, even with minions
left.

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
| `levels/` | Arena scenes; `levels/golgothon/` has the boss arena, battle scene and encounter script | `view/`, `battle/` |
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
`after_skill` (Shadows inheriting a skill), `stat_bonus` (Evasion per Shadow).

- `clock` picks what counts the duration down: the owner's turns, or rounds
  (for "until end of turn").
- Tags drive simple rules: `taunt`, `debuff`, `blind`, `end_on_move`,
  `no_cooldown_next`.
- Stats are always computed (`unit.get_stat(&"armor")`), never overwritten.
- Statuses with a `link` end when the linked unit dies.
- Work that should happen after the current action (Pact
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
  `uses_per_battle`, `requires_status`, `shadow_use` (Shadows inherit it) and
  `copy_status` (a status a Shadow's strike adds).
- **description**: `{damage}` and similar placeholders are filled in from the
  effects ("6 (Silver + Silver)"), so the text always matches the numbers.

The Bloodthane and Traceless kits are written by `tools/build_kits.gd`
(`godot --headless --path . --script res://tools/build_kits.gd`). The `.tres`
files are the source of truth after that; edit them in the editor. Re-running
the builder overwrites them.

For a quick balance check, run `tools/dev/autoplay_stats.tscn` (20 AI-vs-AI
battles with shuffled decks; prints outcomes and skill use). Add
`-- golgothon` for the boss fight, and a number for how many battles.

The Golgothon encounter is written by `tools/build_golgothon.gd` (statuses,
units, the arena and its Encounter node). A boss is an `Encounter` node in its
level: it plays the enemy phase as a script and lists its intents.

## Conventions

- Shared enums live only in `core/enums.gd` (`Enums.Team`, `Enums.Cost`, ...).
- Occupancy lives only in `BoardState`. Never track it anywhere else.
- Sequence with `await`, never with timers.
- No `get_node("/root/...")` and no `call_group` for game logic. `battle.gd` passes references in.

## Art

Units and terrain come from BFTA 4.0. Unit sheets are one row per facing
(down, left, right, up). Set `sheet_columns` and `idle_column` on each `UnitDef`.
