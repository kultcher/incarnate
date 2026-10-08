# BFTA Design Review

Oct 6, 2026 · @Michael Smith

## The archive at a glance

BFTA has been rebuilt five times since 2012. Each rebuild kept the same goal, an MMO raid boss fight on a grid, and changed how randomness, resources and bookkeeping worked so the game could run on a table.

| Era | Key documents | What defined it | What it dropped |
| --- | --- | --- | --- |
| 2023 Godot prototype | BFTA 4.0 project | Move / skill / flex points, cooldowns, Pacts and Shadows ported to code, flat damage | The Soulstream (only a stub scene), Heroic skills, bosses |
| Late 2013–2014 | New BFTA, BFTA Master sheet, class booklets, Fall 2014 scratch | Damage drawn from Soulstream cards ("unveil"), bronze/silver/gold decks, Power stat, Attunement Grid for unlocking skills mid-fight | Fixed damage numbers; considered dice again in Fall 2014 |
| Mid 2013 | Player Guide v0.1b, PnP alpha pack, Golgothon script, class docs (May–July) | 3 Actions (Move / Skill / Focus), recharge tracker, 4-suit Soulstream deck, weaving for bonus damage and Heroic flips, Echoing, shared Recovery | Diagonal movement, flux scaling on player skills (bosses kept a version), Heroic Surge card |
| Early 2013 | Starter Guide v.02, Decimatrix Cassia, Electro-Core, Gauntlet Mode | Actions replace AP, Time Track playmat, flux (♦) scaling, Heroic Surge card | Dice rolls, hero points on a timer |
| 2012 | Original Design Doc v0.2, Player's Guide v1.0β | 4 AP per turn, 1 AP per square, d20 crit and avoid rolls, 500 health, tank / healer / damage roles, hero point every 4th turn, tiers and loot | (first version) |
|  |  |  |  |

In January 2025 there's also a short Claude chat pasted into *Ideas & Scratchpads* with six new Incarnate concepts (Stonemind, Stormheart, Griefweaver, Timebound, Dreamshaper, Lawkeeper) and lore notes about the Heedless and the Ascendancy.

## What BFTA is

Five ideas survive every rewrite. They're the design, so the review measures each old concession against them.

1. **Every fight is a boss fight.** The 2013 Starter Guide says there are no "throwaway" fights, and the Next Big Thing post repeats it: "no warm-ups, no throwaway fights".
2. **Bosses are puzzles you solve.** Bosses follow a script, and the 2012 design doc wanted players to win through "smart planning and pattern recognition". Golgothon is the clearest example: Death's Grasp pulls everyone in on turns 2, 5, 8 and 11, and Death's Caress punishes anyone still close on the turn after.
3. **Teamwork is the main mechanic.** Many skills only pay off through an ally: Soulweaver Tethers, Adrenal Surge, Mirage Dance's swaps. Players could also interleave actions freely within the player phase. This is the "unit 1 sets up, unit 2 executes, unit 1 finishes" play you want to keep.
4. **Attacks always hit.** The 2012 guide made every attack hit because "missing is never very fun", and no later era brought to-hit rolls back. Any randomness lives elsewhere.
5. **Each Incarnate has its own engine.** Innate skills give every class a unique resource or board presence: Pacts, Shadows, Heat, Tethers, Mods.

## Table-era concessions, revisited

Two kinds of limits shaped BFTA, and a video game built with AI help removes most of both. **Table limits** (bookkeeping, measuring, needing a human to run the boss) go away because the computer does that work. **Solo-developer limits** (what you could realistically code) shrink because systems like an encounter scripting language, an enemy-intent display or a reaction stack are now days of work, not months. One limit stays: what a player can hold in their head on a turn.

| Concession | Why it existed | What changes now | Verdict |
| --- | --- | --- | --- |
| Small flat numbers (mid-2013 skills deal 2–9 damage; 2014 Incarnates have 12 health) | Mental math at the table | The engine does the math, but small numbers still read better. Effects once too fiddly to compute by hand become fine, like Severing Claws' "loses 1 health for every 100 health it has" or bonus damage split across targets, because a preview shows the result. | Keep |
| Randomness from a shared card deck (the Soulstream) | Dice were slow; a deck added variance and doubled as a resource | The engine shuffles and tracks hands, suits and discards, and can show players what's coming | Bring back |
| Recharge and duration tracked by moving cards along a playmat | State had to be visible on the table | Free in code, so "when this recharges" and "Exhausted:" effects cost nothing. Several 2014 skills (Borer Charge, Steal Spirit, the Stormherald idea) were built on them. | Bring back |
| A human Raid Boss running a written script | No other way to run the boss | The engine runs the script and can display each enemy's intent during the player phase | Rework |
| Boss complexity capped by what a GM can track | Decimatrix Cassia needed a four-phase checklist to run | Complexity is free to run. The limit becomes whether the player can read it. | Bring back |
| Random 2×2 terrain tiles on a 10×10 map | Variety without printing maps | Hand-built arenas per boss, terrain that changes mid-fight, and walls between squares with line of sight are all cheap | Rework |
| Area shapes measured by hand (cones, waves, Wall X "moved like a unit", zones) | Rulers and table arguments | The engine computes them and the UI highlights them before you commit | Bring back |
| Reactions resolving last-in-first-out, with "complete rules" left to another document | Hard to adjudicate at a table | The engine resolves them exactly; the cost moves to how often the game stops to ask | Keep |
| One player per Incarnate, 4–5 unique Incarnates, plus a GM | The table's social model | One player commanding a whole Tether multiplies the decisions in every turn | Rework |
| Progression either between fights (talents, gear, reward points) or mid-fight (2014 Attunement Grid), never both | Too much to track at once | Both are cheap to track; the question is pacing, not cost | Bring back |
| Encounter variety from hand-drawn Gauntlet affix decks | Paper cards and manual setup | Rolling enemy affixes procedurally is trivial | Bring back |
| Boss clues delivered as paper lore handouts | The only channel available | An in-game dossier that fills in as you see each ability used | Rework |

## Three big bets

Three ideas have the most to gain from the move to a video game. Each was cut or shrunk because of the table, and each already has substantial material in the archive.

### 1. Bosses as scripted puzzles that show their next move

A BFTA boss already is a script: a timeline (Golgothon acts on fixed turn numbers), triggers (Cassia's afflictions combine, so Goo plus Spores spawns four Oozes), and targeting rules ("the foe who dealt the most damage this turn"). In the game, that script becomes data the engine runs. Each turn, everything the boss will do is shown on the board during the player phase: Death's Caress drawn as a damage-by-distance ring, Magnetaur's drones with their arrows.

This makes "solve the boss" the core loop. It also gives the set-up-then-execute teamwork something concrete to plan around: you see the pull coming, one unit Swaps an ally out of it, another punishes the boss.

The archive is ready to mine:

- **Golgothon**: a complete script.
- **Decimatrix Cassia**: complete, and the most mechanically rich.
- **Magnetaur**: half-built. Seeker drones lock onto a row or column; magnets link two players who take damage if they touch.
- **Electro-Core**: a cone covering a quarter of the room, and Sparklings spawned by player movement.
- **Filth**: rat swarms, a spreading disease cured at a well with limited charges, and hovels players can block.
- **Ooze storm**: minions that merge into bigger ones.

The 2012 lore handouts become a boss dossier that fills in as you see each ability used.

### 2. The Soulstream as the shared team resource

The Soulstream is the most distinctly BFTA system, and the Godot prototype skipped it (only a stub card scene exists). Use the mid-2013 version:

- One shared four-suit deck (Blades, Orbs, Portals, Wards).
- Each Incarnate draws a card every turn; a Focus action draws another.
- Weaving cards into a skill adds bonus damage and flips it to its Heroic side.

The Soulstream also ties the team together. Soulweaver can trade cards with a Tethered ally, and Soulfont squares on the map draw extra cards.

Two changes for the digital version:

- **Every attack hits for a guaranteed base.** The late-2013 "unveil" system drew each skill's whole damage from the deck, which made plans unreliable. Instead, keep a fixed minimum and let players spend cards they hold for bonus damage on top (2013's weaving did this). A 3 coming up still feels good, but you can plan a kill around the minimum. Exact rules to come.
- **Hold'em-style draws.** Each Incarnate keeps about 2 cards of its own and combines them with a shared face-up row that refills separately. This builds on the 2014 note about a shared "field" of about four cards, and makes card use a team decision about who takes what.

### 3. A run of boss fights instead of a flat campaign

The 2012 doc's long-term goal was "a complete raiding experience". The pieces are already scattered through the archive:

- **Loot**: each player picks a piece from the boss's loot table before the fight and wins it only on victory.
- **Gauntlet Mode**: escalating waves with basic and advanced affix decks.
- **Rewards**: earned "win or lose".
- **Attunement Grid**: a build-up grid unlocked with Soulstream cards.

In a game, these fit a run structure. A run is a short chain where every stop is a boss or an affixed elite pack. Between fights you choose talents and gear, and a loss still earns something toward the next run. I'd move the Attunement Grid between fights, not into them, so each turn stays about the board.

## Ideas to leave behind

Not every old system was a concession. Some were tried and fairly rejected, and being cheap to code now isn't a reason to bring them back.

- **Damage drawn from cards ("unveil", bronze / silver / gold decks).** It conflicts with attacks-always-hit: you can't plan a kill if the damage is unknown until you commit. Keep damage fixed and put the variance in which cards and options you have.
- **d20 crit and avoid rolls, d6 bonus damage (2012).** Already dropped in 2013. The Fall 2014 "dice already?" note shouldn't revive them for the same reason.
- **1 AP per square of movement (2012).** Precise, but slow to play and hard to preview. Speed-based move actions read better.
- **Diagonal movement at 1.5 squares (early 2013).** Dropped by mid-2013 and rightly so: orthogonal grids are easier to read and to telegraph against.
- **Fixed tank / healer / damage roles in five-player parties (2012).** The 2013 Incarnates moved to hybrid roles like Front-line Brawler and Combo Spellcaster, which suits a small squad better.
- **Flux (♦) and ▲▼ scaling notation.** A compact way to do arithmetic on paper. On screen, just show the final number.
- **A human GM.** The 2012 doc already asked "Does the game need a GM?" The scripted boss answers no.

## New risks once code is cheap

When building stops being the bottleneck, the limits become the player's attention, how much the game interrupts, and balance. AI helps directly with the last one.

- **The player's complexity budget.** The 2013 rules gave each Incarnate 4 core skills plus 5 standard skills, each with a Heroic side. One person commanding four Incarnates is 36 skills plus a Soulstream hand on every turn; at the table that load was split across four players. Options: field 3 Incarnates, trim the loadout to 4 core plus 3 standard, or both.
- **Prompt fatigue.** Pacts, Chimeric Cloak, Perfect Decoy and every Reactive skill ask a question mid-resolution. Give each reaction an Always / Ask / Never setting, and default the obvious ones to Always.
- **Readability.** Cassia-level bosses only work if every threat is on the board before the player commits: the boss's next actions shown on the board (its intent), affliction icons, damage previews. Treat this display as part of each boss's design, not as polish.
- **Balance.** The 2014 master sheet has more than a dozen notes guessing whether a skill is OP or UP; it was tuned by feel. The architecture already lets the rules run without visuals. So a simple bot can play thousands of fights after every change and report win rates by squad and boss, plus how often each skill gets used. Claude can write those bots and summarize the results; the judgment calls stay yours.
- **Art is now the bottleneck.** Code and content text are cheap; sprites, effects and animation still aren't. The 2012 doc's idea of an 8- or 16-bit homage, which the prototype already follows, keeps that cost manageable.

## What this changes in the architecture plan

The layers in BFTA Rebuild: Architecture Plan still hold. These bets add five systems and widen three existing ones.

**New systems**

- **Encounter scripts.** A boss is a `.tres` with a turn timeline, triggers and target-selection rules ("most damage dealt this turn", "random, prefer not already struck"). The resolver runs it during the enemy phase. Minions keep the simple scored AI.
- **Intent layer.** At the start of each player phase, the encounter script lists what it will do; the Presenter draws those threats on the board and updates them if you move the targets.
- **Soulstream model.** A deck, hands and an optional face-up field, all in core. Weaving becomes a step in the resolver before effects run. A `SkillDef` gains a `heroic` variant and the suits needed to unlock it.
- **Simulation harness.** A headless runner plus a scripted bot, added after milestone 3, so balance is measured from milestone 4 on.
- **Echoing.** A downed state with 1 action and a per-turn health drain on allies, as a status rather than special-case code.

**Widened systems**

- **Turn flow.** Units spend actions in any order across the player phase, so you can switch to another unit with actions left over. The planned input states already allow this; the plan should say so explicitly.
- **Targeting shapes.** Add burst, range-burst, cone, wave and a drawn wall path to `adjacent`, `within` and `line`.
- **Board model.** Walls on cell edges as well as solid cells, line of sight, and rough, elevated and Soulfont terrain.

## Decisions

All six were settled on October 6, 2026. Co-op multiplayer and the campaign's exact shape are still open.

- [x] **Squad size: 4 Incarnates.** Trim individual kits before cutting a unit from the field; with good onboarding the full kits may be manageable as they are.
- [x] **Action economy: move / skill / flex.** Being able to take two standard actions in a turn is where the set-up-and-payoff play comes from.
- [x] **Soulstream: Texas Hold'em style.** Each Incarnate holds about 2 cards of its own and pairs them with a shared face-up row that refills separately.
- [x] **Structure: a narrative campaign.** Its exact shape can wait.
- [x] **Roster: start with the original five.** The Techsage may sit out for now. The 2025 concepts stay early ideas.
- [x] **Damage scale: keep the low values.** Multiply everything by 10 later if the design needs more room.

## Sources

All from the *BFTA Random* folder in your Google Drive.

- [BFTA Player Guide (v0.1b, mid-2013)](https://drive.google.com/file/d/0B4wo7AB0bdugM1pabm0xZDZOMjg/view)
- [BFTA Player's Starter Guide v.02 (early 2013)](https://docs.google.com/document/d/1ivi0zKFmdV70ELwYXi6hN8DxwNrSTRKi0h74bfrggcc/edit)
- [BFTA Player's Guide (2012)](https://docs.google.com/document/d/1PrgqryXQrxLzZz3ku_pniqG9FYKt57n3iI-9kYY1AHs/edit)
- [BFTA Original Design Doc](https://docs.google.com/document/d/1EUvbeo6x1E-5stHez3ZyHvg9Dl5JjGCxzhadFLX3vpQ/edit)
- [BFTA PnP](https://docs.google.com/document/d/1kNUOpzpU6KbFqxvE6G5uxCisEImbFSOnlu3fyDFsVtw/edit)
- [Golgothon the Restless (encounter script)](https://drive.google.com/file/d/0B4wo7AB0bdugZHlOajFyY3p5VU0/view)
- [Boss: Decimatrix Cassia](https://docs.google.com/document/d/17sD9GWMLYMYxuuXUeYwKuV3nI4YXuj1fijaky1UUlSs/edit)
- [Magnet Boss 7/5](https://docs.google.com/document/d/1G87vKSq18xzRPkIm5JCM2lioj3ivAAiXNRoVf_FP5VI/edit)
- [Boss: Electro-Core](https://docs.google.com/document/d/1Ft0-fKkG4XLwKxEUE1NhAmd1lQgINa8kpp9twJNLD34/edit)
- [Boss Concept: "Filth"](https://docs.google.com/document/d/1vJ3Sbe0yI8XPf2XXBo-0UHFzJ35mS9F8tDH8HPqx96U/edit)
- [Gauntlet Mode](https://docs.google.com/document/d/1jrqvrQd4akF46w8c1qwpkmfOUAKlkUOzdm4MFP0d_PY/edit)
- [BFTA Master (2014 skill sheet)](https://docs.google.com/spreadsheets/d/1IKgEPwYKhGnwY6uI3WECryVGjMUKkhIeisQd0i-k1c8/edit)
- [Bloodthane booklet (BTBook.png, 2014)](https://drive.google.com/file/d/0B4wo7AB0bdugUEpIYkJVYXFVVEE/view)
- Class docs: [Bloodthane (5/31)](https://docs.google.com/document/d/1XrW8HssV-_6EOy9d6ji7ZtmRM8ElSt0rhksJFDDzsWI/edit), [Traceless (6/8)](https://docs.google.com/document/d/1iHyl5JKw7aSFdXEkjQECBArr2Ozl2U6VbY4cmOVHhSw/edit), [Soulweaver (6/8)](https://docs.google.com/document/d/14DTFv-y4A3cpap9ntMnjWfYSRnAx1hGGPQ_WD0Sb2SE/edit), [Techsage (6/15)](https://docs.google.com/document/d/1ywdcshDKJTJZ5KeEGXWa875Y7Tr-kLLIFrsCIn76Eac/edit), [New Kindleborne 7/14](https://docs.google.com/document/d/1TtpFObZxdwVYaMwQ3lThGTqHULKoGzPu9Hcj61NAYL8/edit), [New BFTA](https://docs.google.com/document/d/1VY_eTFbQt-2Xmy1SsPH_urj6gYVtvaQRlRDvV3wprmg/edit)
- Scratchpads: [Progression](https://docs.google.com/document/d/1xKkQFFElUIwf3dUgtQqHd9Sje-Py9XSW217dcU6UcTA/edit), [Fall 2014](https://docs.google.com/document/d/1uNRrkFpJZTS-J3-u1buwPUZvaxq7VnKZ4LR9UG8eZh8/edit), [From Email](https://docs.google.com/document/d/1LrJ8jJw-st8WuLKY9Pj94jAxoVJx_PhmASuKd8fZQvY/edit), [IDeas](https://docs.google.com/document/d/1WRKyu62XPlNPdBKdMlt4QFr_C2zmGF-0t6qSUvpgGlI/edit), [Buffs Debuffs](https://docs.google.com/document/d/1Ik88BsZDMsUCvntRJA_SqFNc-OxElh70V_Oa8gq8UGI/edit), [Claude Incarnate Ideas](https://docs.google.com/document/d/1RidV0leBWnXI3OeUN9h391ASxUllM-pZSQyU4Q_YH5M/edit)
- [Next Big Thing](https://docs.google.com/document/d/100Rh_IrPQPePBwYPC_en-vCRKIxkSL6ngBCXbGDGbY8/edit)
