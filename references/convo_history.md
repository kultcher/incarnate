
So this is a much older project from many years ago, like Godot 3.5 era or maybe even originating before that, back when I was still just cobbling things together from tutorials and jury rigging things I didn't fully understand. Any of this salvageable or better to just start from scratch?
______
Read 2 files, ran 4 commands, and 2 more steps
I read through all of it. Short version: rewrite the code, but don't start from scratch. There's real value here. It just lives in the design and the assets more than in the scripts.

First, better news than you expected. This isn't Godot 3.5. The git history runs from March to April 2023, and the code is Godot 4 throughout (@onready, await, Callable, AStarGrid2D). So there's no 3→4 port to worry about. When you just opened it, Godot 4.7 updated a few files (project.godot and a couple of others now have today's date). That's harmless, and it's all under git.

What's worth keeping

The game design. This is the most valuable part. Bloodthane's Blood-bound stacks and three Pacts, the Traceless shadows that copy your strikes and let you swap places, Chimeric Cloak as a reaction, plus the move/skill/flex action economy and the skill slots (passive, basic, heavy, area, defense, maneuver, utility, ultimate). That's a coherent tactics combat system, and none of it has to be designed again.
The art, UI pieces, shaders and particle effects carry over as they are.
Your instincts were right. You already had a game state machine, per-unit state machines, a move component, a buff handler, skills as .tres Resources, and an effect queue of Callables. Your TODO even says "make skills into nodes… component system… visualize the action queue." The structure you were reaching for is the correct one; it just never got finished.
Why patching it would cost more than rewriting

"Is this tile occupied?" has three answers. Area2D overlaps, a tile.occupied flag, and AStar solid points all track it separately. That's why the suppress_collision/unsuppress_collision workaround exists, and part of it points at Global.collision_tiles, which doesn't exist anymore.
Short timers stand in for proper sequencing. create_timer(.1) is used to order map building, tile setup, finishing actions and turn flow. One of them, in actor_finished.gd, is missing .timeout, so it doesn't actually wait at all. Bugs like that are timing-dependent and miserable to track down.
Each skill describes its targeting twice. Once in the target_info dictionary and again in the execute() code, and the two drift apart. For example, Ravage's second target sets its highlight color to NEEDS_ENEMY, a different enum. It only works because both values happen to be 0.
The same enums are copied into about five files, and the pathfinding functions exist in both level_map.gd and skills_library.gd. Both copies of pathfind_shift share a bug: they only ignore other units for the first step.
Global sets up a second copy of the state machine even though Game_State already exists as an autoload.
The rewrite I'd do

One grid model as plain data, e.g. a dictionary from cell to unit and terrain. It's the only place occupancy is stored, and AStar and the highlighting both read from it. Use a TileMapLayer (Godot 4.3+) for visuals and click-to-cell lookup instead of 144 clickable Area2D tiles.
Skills as data plus effects. Each skill is a Resource with a list of targeting steps (e.g. "shift 2, then enemy within 1"), cooldown, type and a list of effects. One generic targeting controller walks through the steps, so skills stop awaiting send_target by hand.
One action/effect queue that resolves with await, not _process or timers. That's also where reactions like Chimeric Cloak and the Pact prompts plug in.
A signal-bus autoload plus one constants file for the enums.
The code is only about a month of work, so rebuilding the base cleanly is maybe a few weekends. Then the Bloodthane and Traceless kits move over one skill at a time, with the old scripts as the spec.

I could start by setting up that new structure inside this folder: grid model, turn and action queue, and a data-driven skill format, with Bloodthane's basic attack and Ravage ported as proof it works.
______

All right, nice. Can you write up an architecture plan for the new version?
______

Loaded skill

BFTA Rebuild: Architecture Plan
Claude Docs·Only you 
Outline's up. Now writing the goals section.

Used Claude Docs, used artifacts, and 2 more steps
I've written the architecture plan as a doc. I left you one question in a comment there: keep turns as all your units, then all enemies, or switch to each unit acting in initiative order. You can edit the doc directly or comment and I'll revise it.
______

All right, that looks good.

For now let's stick with the side-based turns, as part of the gameplay is meant to be like "unit 1 goes, sets something up, unit 2 executes on that, then unit 1 finishes the turn"

Before we move ahead, can you look through the BFTA folder in my Google drive? It contains a lot of old design work from the original tabletop version of this game, including a lot of stuff that was planned for the Godot version but I never got to.

Before I try and resurrect the project, I want to also do a design review, since the game has always been kind of a mishmash of tabletop and tactical RPG video game concepts, and some concessions were made for scope because I just wasn't sure I had the capability to go bigger. So I want to reevaluate those ideas through the lens of leverging AI where coding limitations are much less of a concern.
______

Check whether the working copy survived
I'll write the settled rules into the design log first, then build the next milestone: the full Bloodthane and Traceless kits on the 2014 data.

Ran 8 commands
I have the shape of the codebase back in view. Next I'll check what art the 2023 project left for icons, and which tests touch the APIs I'm about to change.

Read a file, ran 2 commands
The 2023 project only has art for a handful of skills, so I'll generate the rest in the same style as the existing claw and strike icons. I'll create the task list, then log the settled design.

Created 10 files, shared 2 files, and 108 more steps
Milestone 5 is on your computer: the Bloodthane and Traceless now have their full 2014 kits, built on the card-damage rules we agreed. All 150 tests pass, and every ported skill has at least one test.

How damage works now:

Skills strike for cards, shown in the text as e.g. "6 (Silver + Silver)". For now every card counts as its middle value: Bronze 2, Silver 3, Gold 4.
Power and Armor are ±1 per point, and a strike never deals less than 1.
Evasion is dodges per round. A dodge cancels the strike's lowest card, or turns a one-card strike into a 1-damage graze. Accuracy cancels dodges point for point.
"Until end of turn" lasts until the next round starts, so it covers the enemy phase too.
Bloodthane:

Blade Fury, Rending Claws (your "+1 Power per 2 damage this turn" version), Rage Strike, Bloody Rush, Acute Coagulant, Verve Magnet, Adrenal Surge, Violent Transfusion and Bloodrage.
Bound in Blood uses the 2014 one-shot Pacts: Dominance, Vampiric and Predation, each once per turn. Until cards have suits, the trigger is "strike a foe you've already struck this turn" instead of a Blade card.
Traceless:

Shifting leaves a Shadow, drawn as a ghost (at most 3). After an attack you're asked whether a Shadow copies it, and each Shadow gives one dodge per round.
Skills: Displacer Strike, Shadowstep, Gloom Edge, Phantom Dash, Chimeric Cloak (now fully cancels the next strike or debuff), Mirage Shift with Shadow Swap, Tactical Distortion, Perfect Decoy and Shadowstorm.
Interface: Bloody Rush and Phantom Dash are clicked out square by square; click the last square again or press Enter to stop early. Hotkeys go 1–9 plus 0, skill tooltips show cost and recharge, and skills you can't use right now are greyed out.

A separate reviewer went over the new rules code and found nine issues. I fixed all but two (one turned out to be correct as built, the other is a display choice), and added tests for the fixes. The most important one: the AI could freeze when its only option was a recovery skill the team had used up.

Not in yet:

Heroic versions, Talents and suit bonuses.
Perfect Decoy's teleport, and Cloak protection against health loss.
Titan Charge and the other skills that only appear in the Master sheet as Alpha.
The AI doesn't use the utility skills yet.
A few approximations are marked to revisit in the kit reference, for example Shadow copies of area attacks hit only one foe. Three Shamblers are still trivial: the AI won all 20 test battles in 2 rounds.

Please delete these old files in the project folder. I can't delete from here:

art/icons/ravage.png and ravage.png.import
content/skills/bloodthane/ravage.tres
In content/statuses/bloodthane/: blood_bound.tres, dominance_pact.tres, dominance_pact_boon.tres, pact_dominance.tres, pact_predation.tres, pact_vampiric.tres, predation_pact.tres, predation_pact_boon.tres, vampiric_pact.tres, vampiric_pact_boon.tres
In defs/statuses/behaviors/: drain_link.gd, heal_over_time.gd, reduce_damage_from_link.gd. I've emptied these three so the project still compiles until you delete them.
I've updated the design-decisions log and the kit reference in the project, and the README in your folder. The obvious next step is building the Soulstream itself (held cards, the shared row, suits, Heroics), which would turn on everything that's waiting on it.

shadow.png
targeting.png

Design decisions
Document·MD 

Kit reference
Document·MD 
______

Getting an error due to GHOST_COLOR being undefined in UnitView. I can fix that, but what was the intended color there? Just an alpha change?
______

Ran 3 commands
The new PNGs also differ byte for byte. I'll check whether they differ as images or only in encoding.

Ran a command, listed files on your computer
unit_view.gd hasn't changed since delivery, but shadow_layer.gd was edited after it, presumably by you while working around the error. I'll only replace unit_view.gd and leave your edit alone.

Saved files to your computer
The error was my mistake, not a missing design choice. A shell loop skipped the last file in the delivery list, so your computer got the milestone 4 version of view/unit_view.gd. I've now sent the correct one. Every other file checked out: the new icons were re-encoded but are pixel-identical.

To answer your question: it was a tint plus transparency, not just an alpha change. GHOST_COLOR := Color(0.45, 0.3, 0.75, 0.55) turns the Traceless's sprite dusky purple at 55% opacity for its Shadows.

The old file was also missing two functions the Shadows need: make_ghost(), which builds the translucent sprite copy, and teleport_to(), which handles the blink for Shadowstep and Shadow Swap. Without them those would have failed next, even with GHOST_COLOR defined.

view/shadow_layer.gd on your computer has a newer timestamp than my delivery, so I assumed you'd edited it and didn't overwrite it. The delivered version reads UnitView.GHOST_COLOR.a when fading ghosts in, which works again now. If you changed that line, you can put it back or keep yours.
______




