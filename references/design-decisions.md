# Incarnate / BFTA: Design Decisions

A running log of settled design calls. The newest entries go at the top.

Working docs:
- Architecture plan: https://claude.ai/code/artifact/60feca30-fc72-4d76-a80d-f6298d00c19c
- Design review (archive review and verdicts): https://claude.ai/code/artifact/9c1310fd-512b-44a4-95eb-0c77d3bf29d9
- **Canonical kit reference: `claude/kit-reference.md`** (full Master sheet transcription in `claude/kit-reference-master-sheet.md`)
- Old design archive: Google Drive folder "BFTA Random"
- Canonical sources: Incarnate > References > "BFTA (flat damage era_)" (booklets and cards), plus the BFTA Master sheet
- 2023 Godot prototype: BFTA 4.0 folder on Michael's PC (reference only)
- New project: C:\Users\kultc\OneDrive\Desktop\Godot\Incarnate (Godot 4.7, gets its own repo)

## 2026-10-07 (Soulstream direction and stats; Michael, with Claude's proposals he accepted)

- **The kits follow the 2014 version** (cards plus the Master sheet). The Attunement Grid progression is out of scope.
- **Card damage stays.** Skills strike for Soulstream cards, e.g. "(Si)(Si)" means two Silver cards, which are drawn blind or spent from held cards. This keeps "bonus if you used a <suit> card" as design space.
- **New card ranges:**
  - Bronze 1–3, Silver 2–4, Gold 3–5. No strike can miss.
  - One tier step is exactly ±1 to a card's value.
  - Health values will be retuned later.
- **First kit pass uses the median card values:** Bronze 2, Silver 3, Gold 4. Suit bonuses and other Soulstream-only effects are left not-yet-implemented until the Soulstream is built.
- **Rending Claws:** +1 Power for every 2 damage you've already dealt this turn.
- **Power:**
  - Each point raises one card in the strike a tier.
  - Past Gold, each point is +1 damage.
- **Armor:**
  - Each point lowers one card in an incoming strike a tier.
  - Past Bronze, each point is −1 damage.
  - A strike never deals less than 1.
- **Evasion is dodge charges:**
  - Each point is one dodge per round, refreshed at the start of your side's turn.
  - A dodge cancels the strike's lowest card.
  - A one-card strike becomes a **graze**: it deals 1 and keeps its riders.
  - Dodges are used automatically on the first eligible strikes.
- **Accuracy cancels Evasion point for point:** each point means the defender needs one more dodge to dodge that strike. Its redraw-keep-better bonus waits for the Soulstream.
- **Heroic versions** are not in yet. The proposal on the table: a skill turns Heroic when the cards it used include both of its Heroic suit symbols.
- **Soulstream economy proposal (not built yet):**
  - Each Incarnate gets +1 card per turn, holding up to 2.
  - The shared Soulstream gets +1 card per round, up to about 3, and unspent cards carry over.
  - Enemies draw from their own deck.

### Claude's implementation calls for M5 (provisional)
- **Bound in Blood:**
  - Uses the 2014 Pacts (Dominance, Vampiric, Predation), each one-shot and each bindable once per turn.
  - Until suits exist, the "a Blade card is unveiled on a strike" trigger is stood in by "you strike a foe you've already struck this turn".
- **"Until end of turn" means until the start of the next round.** A turn covers both phases, so a buff you get in your phase lasts through the enemy phase. Statuses like this count down once per round, not on their owner's turns.
- **"Recharge" vs "refresh":**
  - Recharge a skill = its cooldown drops by 1.
  - Refresh a skill = it's ready at once.
- **Blind** (on a foe) makes its next strike count as dodged. That fits the no-miss rule, where the booklet's version was a 25% miss.
- **Provoke:** the AI strongly prefers attacking the unit that provoked it.
- **Cripple:** −2 move until the unit's next move action.
- **Shadows:** at most 3, and placing another replaces the oldest. Normal walking doesn't drop Shadows, only shifts do.
- **Left out of this pass:**
  - Heroic versions and Talents.
  - Skills only in the Master sheet (marked Alpha there): Plasma Boil, Crimson Haze, Synaptic Flood, and Titan Charge, which is also on a card.
  - Ravage, which is from 2023 and not in the 2014 kit, is removed.

## 2026-10-07 (canonical reference)

Partly superseded by the entry above: the kits follow the 2014 cards and Master sheet, not the booklets, and cards use the median values. Rending Claws and Probability Armor (Evasion) are settled.

- **Canonical source** (Michael): the flat-damage-era folder. Where copies disagree, Claude picks one and notes the alternative in `claude/kit-reference.md` for later resolution.
- **The folder holds two eras** (Claude's finding):
  - The booklets (~Sept 2013) use flat damage.
  - The cards (Jan–Feb 2014) and the Master sheet (May 2014) use card-unveil damage.
- **Still open:**
  - BT Ultimate: Bloodlust (booklet) or Bloodrage (sheet). M5 uses Bloodrage.
  - BT Recovery: booklet or sheet Violent Transfusion. M5 uses the sheet version.

## 2026-10-07 (milestone 4, provisional; Claude's calls, open to change)

Superseded in M5 by the 2014 kits (see the top entry): Bound in Blood uses the 2014 one-shot Pacts, Chimeric Cloak fully negates the next harmful strike or effect, and Acute Coagulant uses the 2014 numbers.

- **Bound in Blood trigger:** each strike adds a Blood-bound mark to the foe (max 2). Marks clear at the start of the foe's turn, so it means "hit the same foe twice in one of your turns", as in the 2023 tooltip. The marks are shared across the Bloodthane's actions in that turn (Blade Fury plus Blade Fury, or one Ravage on one foe).
- **Pact prompt timing:** asked once the action's hits have played, not mid-skill. A killing blow binds nothing (resolves the 2023 TODO). Declining binds nothing; another hit that turn asks again.
- **One Pact per foe.** A bound foe gets no more marks.
- **Pact preference:** "Always choose this" in the prompt, or click the passive's icon to pick one in advance or go back to "ask each time". This implements the earlier Pact UX decision.
- **Dominance Pact:** the Bloodthane takes 1 less damage from that foe (never below 1), and the AI gets +3 score for attacking him.
- **Vampiric Pact:** the foe loses 1 HP at the start of each of its turns and the Bloodthane heals that much.
- **Predation Pact:** foe -1 move, Bloodthane +1 move. Several Predation Pacts still give him only +1. His boon ends when that foe dies.
- **Acute Coagulant:** heal 4 now, then **2** at the start of each of the next 2 turns, cooldown 3. The 2023 data said 2 and its tooltip said 4; I went with the data.
- **Chimeric Cloak:** a self buff, cooldown 3, until your next turn. When a foe strikes, you're asked whether to use it. Damage is halved, rounded down (in your favour). If that prevents less than 3, the Cloak stays ready; otherwise it's used up. Hits from allies don't trigger it.
- **AI and autoplay** answer prompts instantly: bind Vampiric, always use the Cloak.

## 2026-10-07 (milestone 3, provisional; Claude's calls, open to change)

- **Refresh per side:** each side's action points refresh and cooldowns tick at the start of that side's own phase, not at the start of the round.
- **Monsters have no flex point** by default (a per-unit `flex_points` setting): they can move and attack, but never attack twice. The 2023 enemies also moved and hit once.
- **Shambler:** 8 HP, move 3, Claw for 3 damage (the 2023 enemy hit for 5).
- **Placeholder Strike** (3 damage, adjacent) for Traceless and Soulweaver until their kits are ported.
- **Battle end:** victory when no enemies remain, defeat when no Incarnates remain, checked after every action. A round cap (60) ends AI-vs-AI runs that can't reach each other in a draw.
- **Autoplay (F9):** the AI can play the player's side, for fast balance checks.
- **Balance note:** with the AI playing both sides, the Incarnates beat three Shamblers in 2 rounds. The Shamblers are training dummies, not a test of the kits.

## 2026-10-06 (milestone 2, provisional; Claude's calls, open to change)

- **Cooldown counting:** cooldown N means the skill is ready again N of the caster's turns after use (Ravage, cooldown 2, used in round 1 is ready in round 3). It ticks at the start of the caster's turn.
- **Multi-hit on a dead target:** if an earlier hit kills the target, later hits aimed at it are skipped, not redirected.
- **Blade Fury** costs a skill point for now. The 2013 "free action after a move" variant isn't in yet.

## 2026-10-06 (later)

- **Rebuild order:** build the solid game first; tune mechanics by playtesting. The Godot version also serves as a fast playtesting tool for the board game.
- **Pact UX:** no Pact is selected by default. When Bound in Blood triggers, the player is prompted to pick a Pact; if one is already selected, it applies without asking.
- **Bloody Rush:** the three-step path version.
- **Shadow echoes:** start with the player picking each echo's targets; revisit if it feels fiddly.
- **Test framework:** GUT (Claude's pick).
- **Porting order:** Bloodthane and Traceless first (from the 2023 prototype). Then Soulweaver, then Kindleborne, both from their 2014 kits (BFTA Master sheet). Then Golgothon, the first boss, once every player kit is complete.

## 2026-10-06

- **Turn structure: side-based.** All player units act, then all enemies. Within the player phase, units spend actions in any order (unit 1 sets up, unit 2 executes, unit 1 finishes). This is core to the teamwork design.
- **Squad size: 4 Incarnates** under one player. Trim individual kits before cutting a unit; good onboarding may make the full kits manageable.
- **Action economy: move / skill / flex** (from the 2023 prototype). Two standard actions in one turn is where the set-up-and-payoff play comes from.
- **Soulstream: Texas Hold'em style.** Each Incarnate holds about 2 cards of its own and pairs them with a shared face-up row that refills separately. *(Being revised: see the Soulstream economy proposal in the top entry.)*
- **Randomness: no misses, every card deals at least 1.** *(Updated 2026-10-07: originally "guaranteed hits with a fixed minimum damage, cards add bonus damage on top". Damage now comes from cards, using the new ranges in the top entry.)*
- **Structure: a narrative campaign.** Exact shape TBD.
- **Roster: the original five Incarnates** (Bloodthane, Traceless, Soulweaver, Kindleborne, Techsage). The Techsage may be set aside for now. The 2025 concepts (Stonemind, Stormheart, Griefweaver, Timebound, Dreamshaper, Lawkeeper) are early ideas only.
- **Damage scale: keep the low values** (around 12 health, skills dealing 2–9). Multiply by 10 later if more room is needed.
- **Table-era bookkeeping limits are lifted.** Recharge and duration tracking, AoE shapes, reaction stacks, complex boss scripts, telegraphs and terrain/line of sight can all be used freely. The limit is now player readability.

## Still open
- Co-op multiplayer: ever in scope?
- The campaign's shape (authored bosses, gauntlet/affix modes, progression between fights).
- The Soulstream's exact rules: the proposals in the top entry (Heroic by suit match, hand and shared-row income) are not confirmed yet.
- BT Ultimate (Bloodlust vs Bloodrage) and BT Recovery version.
