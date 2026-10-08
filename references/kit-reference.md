# Incarnate: Canonical Kit Reference

Canonical source: the "BFTA (flat damage era?)" folder under Incarnate > References, plus the BFTA Master sheet from the same period. Where copies disagree, this doc picks one and records the other under **Alt**. Every pick is open until Michael resolves it. The full Master sheet is transcribed in `references/kit-reference-master-sheet.md`.

## 0. As built in milestone 5 (2026-10-07). Read this first

Michael's direction (see `references/design-decisions.md`) replaced the precedence rule and number translation in sections 1 and 3:

- **The kits follow the 2014 cards and the Master sheet.** The booklets are background only.
- **Card damage stays.**
  - New ranges: Bronze 1–3, Silver 2–4, Gold 3–5.
  - The first pass uses the medians: 2, 3 and 4.
- **Settled picks:**
  - Rending Claws: +1 Power per 2 damage already dealt this turn.
  - Probability Armor: Evasion, now dodge charges.
  - Power, Armor, Evasion and Accuracy work as listed in the decisions log.
- **Built:**
  - **Bloodthane:** Blade Fury, Rending Claws, Rage Strike, Bloody Rush, Acute Coagulant, Verve Magnet, Adrenal Surge, Violent Transfusion (sheet version), Bloodrage (sheet version).
  - **Bound in Blood:** the 2014 Pacts. Until suits exist, the trigger is a stand-in: striking a foe you've already struck this turn.
  - **Traceless:** Illusive Shadows (Shadowstep, Shadowstrike, Probability Armor), Displacer Strike, Gloom Edge, Phantom Dash, Chimeric Cloak, Mirage Shift with Shadow Swap, Tactical Distortion (Master wording), Perfect Decoy, Shadowstorm.
- **Deviations to revisit:**
  - **Bloodrage** gives a strike-only Power snapshot when cast.
  - **Shadowstorm** creates Shadows to fill 3 squares.
  - **Shadow copies of area skills** (Phantom Dash) strike a single foe.
  - **Phantom Dash** leaves one Shadow, not two.
  - **A Shadow can't copy the same use of the skill that made it** (Michael, 2026-10-08).
  - **Perfect Decoy** has no teleport yet.
  - **Chimeric Cloak** doesn't stop health loss.
  - **Blind** makes the next strike count as dodged; the 25% miss chance is gone.
  - **Cripple** is −2 move until the unit's next walk.
  - **Recharge vs refresh:** recharging a skill takes 1 off its cooldown; refreshing makes it ready at once.
- **Not built:**
  - Heroic versions and Talents.
  - Alpha-only skills: Plasma Boil, Crimson Haze, Synaptic Flood, Titan Charge.
  - Suit bonuses. Since M6 (2026-10-08) cards have suits and come from real decks, but nothing reads the suit yet.
- **Settled 2026-10-08 (Michael):** Bloodthane's Ultimate is **Bloodrage** (sheet), and his Recovery is the **sheet Violent Transfusion**. The booklet alternatives below stay for reference only.

## 1. Sources and what each one is

| Source | Date (from backup timestamps) | Damage notation | Covers |
|---|---|---|---|
| **Booklets** (`Booklets/<class>/*1-4.svg`, PDFs) | ~Sept 2013 | **Flat numbers** ("strike for 4 damage") plus card weaving | Lore, stats, quick rules, Innate, Basic, Ultimate, Recovery, tips, rules notes |
| **Cards** (`Cards/SVG/<class>/*.svg`, PNG exports) | Jan–Feb 2014 | Card unveils: (Br)/(Si)/(G) + Power | Standard/Heroic skill pairs, talents, ultimates, recoveries; Golgothon's boss cards |
| **BFTA Master sheet** (Google Sheet) | May 2014 (newest) | Card unveils | Every skill for BT, KB, SW, TS, TL, plus designer notes and Alpha flags |

The folder holds two eras. Only the booklets are the "flat damage" era; the cards and the sheet are the later unveil era. The two eras even have different Basics, Innates, Ultimates and Recoveries (see sections 4 and 5).

**Precedence rule used here (Claude's call):**
1. **Numbers and core system: the booklets.** Flat base damage, with cards spent for bonus damage, matches the settled "guaranteed minimum damage, cards add bonus" decision.
2. **Skill list and wording: the newest source**, Master sheet first, then cards. The booklets only list the core page, so the rest of each kit exists only in unveil form.
3. **Exception: mechanics that only work with unveils.** An example is BT's "a Blade is unveiled on a strike". These take the booklet version, because unveil triggers have nothing to fire on in a flat-damage game.

## 2. Core rules (booklet Quick Rules Primer)

- **Stats (all four booklets):** Health 40, Actions 3, Speed 3, Hand 3.
- **Actions:** 3 per turn, each used as a Skill, Move or Focus action. No type more than twice per turn.
  - Skill action: use any skill.
  - Move action: move your Speed, or use a skill with the **Maneuver** keyword.
  - Focus action: recharge a skill, or draw a card.
  - This maps closely onto the current move / skill / flex economy. Focus has no equivalent yet.
- **Cards:**
  - Draw one card at the start of each turn.
  - **Weaving:** discard a card to add its power value to any one strike, heal or shield.
  - **Heroic:** discard two cards matching the symbols on a Standard skill to play its Heroic version.
- **Movement:**
  - Moving is blocked by walls, pillars and enemy units. **Shifting** passes through enemies.
  - Rough terrain costs 2.
  - Ending a shift inside an enemy puts you in the nearest open square.
- **Recovery:** two Recovery uses per encounter for the whole group.
- **Ultimate:** once per encounter, free.
- **Turn:** "this turn" and "until end of turn" in the card text cover the enemy phase too (TS Pulse Ward says "at the start of each Enemy Phase", and Prepare reactions fire on foes' strikes). A player-phase buff therefore lasts until the next player phase.
- **Health loss vs damage:** "lose health" ignores shields and armor, and is not a strike (BT rules notes).

**Keywords:**
- **Free:** costs no action.
- **Reactive:** usable in response to another action.
- **Maneuver:** can be played as a move action.
- **Prepare:** a skill action to prepare; once prepared, the skill is free and reactive.
- **Active:** the effect lasts for the duration (the sheet's notes suggest renaming this to "Persistent").

**Statuses named in the text:**
- **Provoke:** taunt.
- **Cripple:** reduces a foe's movement for one move.
- **Weaken:** reduces the damage of the foe's next attack.
- **Blind:** the foe's next basic strike has a 25% miss chance.
- **Stun.**
- **Daze** (Golgothon).
- **Keen.**
- **Armor, Evasion, Shield.**

## 3. Translating unveil damage (superseded: see section 0)

The Soulstream deck tiers are Bronze 0–1, Silver 0–2 and Gold 1–3, each plus Power. A literal port draws damage that can be 0, which contradicts the settled decision. Proposal:

- **Fixed value per glyph: (Br) = 2, (Si) = 3, (G) = 4.** Cards are woven on top for bonus damage.
- **Anchors:**
  - Blade Fury: booklet **4** = (Br)(Br) → 4 ✓.
  - Displacer Strike: booklet **4**, card (Si) → 3. **Keep 4 for the Basic.**
  - Gloom Edge: (Si)(Si) → 6 (the 2023 prototype had 8).
- **Mismatch:** Violent Transfusion (G)(G) gives 8 against the booklet's 4. Recovery skills changed between eras anyway (see BT below).
- **"Per N health" conditions** (Rending/Culling Claws) were written for 400-HP bosses. Scale them to percentages, e.g. +1 per 25% of max health.

## 4. Bloodthane (Role: front-line brawler; Core: Blood Pacts; Difficulty: Medium)

### Bound in Blood (Innate): **booklet version chosen**

> When you strike the same foe for the second time in a turn, you may activate a Pact and bind it to that foe. That Pact remains active until you activate a different Pact in this way.

- **Rules notes:**
  - The Pact-bound foe is the one you struck to activate the Pact.
  - You may activate a new Pact on the same foe; the new Pact replaces the old one.
- **Pacts:** each has an on-activation effect plus an Active effect while it is the current Pact.

| Pact | On activation (to the bound foe) | Active (on the Bloodthane) |
|---|---|---|
| **Savagery** | loses 2 health | your strikes deal +1 damage |
| **Vampiric** | Weaken 1 | whenever you strike a foe, heal 1 |
| **Predation** | Cripple 1 | Speed +2 |

- **Alt, Master sheet (May 2014):**
  - Trigger: "whenever a Blade card is unveiled on a strike, you may bind a Pact to the struck foe; each Pact once per turn".
  - Pacts are one-shot only:
    - **Dominance:** Provoke the foe, +1 Armor until end of turn.
    - **Vampiric:** the foe loses 1, you heal 1.
    - **Predation:** Cripple the foe, you shift 1.
  - The designer note says "gain Blood Tokens when striking or struck, spend to activate Pacts", so this was still in flux.
- **Why the booklet:**
  - The Blade-unveil trigger needs unveils.
  - The booklet version is a complete, coherent loop: one active Pact to switch between, with a payoff for switching.
  - It is also the closest to the 2-hit trigger already built.
- **Differs from M4** (which used the 2023 pacts):
  - Savagery replaces Dominance.
  - Pacts become one active Pact on the Bloodthane, not one permanent Pact per foe.
  - The on-activation effects are new.
  - The Pact-preference UI carries over unchanged.

### Basic: Blade Fury (Melee)

- **Chosen:** strike for **4**. Once per turn, when you end a move action adjacent to a foe, you may play Blade Fury as a free action (booklet).
- **Alt, Master:** (Br)(Br); if played immediately after a move, +1 Power per 2 squares moved toward that foe this turn.

### Skills (Master sheet; Standard / Heroic pairs, rec = recharge)

| Slot | Standard | Heroic | Rec | Range | Notes |
|---|---|---|---|---|---|
| A1 | **Rending Claws**: (Si)(Si), +1 Power per 50 health the foe has | **Culling Claws**: (Si)(Si)(Br), +1 Power per 30 health the foe has lost | 2 | Melee | Card SVGs agree. **Alt (BT PNG exports):** Rending "+1 Power for each other strike you've made against that foe this turn"; Culling "+1 for each other strike an ally made against that foe this turn". The booklet tip ("best as the last attack in a turn… increase the health loss effect") describes yet another version. Designer note: "Awkward. Change back to damage trigger?" **This is the weakest-settled skill; candidate for the PNG version.** |
| A2 | **Rage Strike**: (G)(Si); whenever you are struck, recharge it | **Revenge Strike**: (G)(Si)(Si); whenever you are struck, strike that foe for (Br) and recharge it | 3 | Melee | The cards show Revenge as "Standard" (a typo); the sheet says Heroic. |
| AA1 | **Bloody Rush**: shift 3; strike each foe you shift through or adjacent to for (Si); if 3+ foes struck, +1 Armor until end of turn | **Bloody Revel**: same for (G); +1 Armor per foe struck | 3 | Special | The cards say "2+ foes" and (Br). The sheet is newer: 3 foes. Note: "Probably OP. Change both to shield?" |
| AA2 | *Plasma Boil* (Alpha): burst 2, each foe loses (Si), (Si)(Si) if at full health | *Plasma Parch* (Alpha) | 3 | Burst 2 | Sheet only; no card. |
| D1 | **Acute Coagulant**: heal (Si); Active (dur 2): heal (Br) at end of turn and whenever struck for 2+ | **Hyper Coagulant**: heal (G)(Si); Active: heal (Br) at end of turn and each time you are struck | **1** | Self | The cards show dur 2, rec 1, with heal (B) / (B)(B). M4 has rec 3 (from 2023). |
| D2 | *Crimson Haze* (Alpha): Provoke target foe, -3 Power on its next strike against you | *Crimson Convulsion* (Alpha) | 2 | Range 4 | Sheet only. |
| M1 | **Verve Magnet**: Maneuver; you and target unit are each forced 2 toward or away from each other; each forced ally heals 1, each forced foe loses 1 | **Verve Maelstrom**: burst 3, any number of units forced 3 toward or away from you, same ±1 | 3 | Range 5 | Matches the 2023 script (pull 2, cd 4; heal/damage not yet implemented then). |
| M2 | *Titan Charge* (Alpha): Maneuver, shift Speed+1, push units shifted through 1 | *Titan Blitz* (Alpha): Speed+2, push 2, Stun | 3 | Self | The cards say Speed+2 for both. |
| U1 | **Adrenal Surge**: target ally refreshes a skill and gains a skill action; their next Standard/Heroic skill this turn isn't exhausted | **Adrenal Frenzy**: same, and all Standard/Heroic skills this turn aren't exhausted | 4 / 3 | Range 4 | The cards say rec 3 for both. The 2023 prototype has an `adrenaline_surge.gd`. |
| U2 | *Synaptic Flood* / *Synaptic Overload* (Alpha) | | 1 / 3 | Self | Sheet only. |

**Recovery, Ultimate and Talents:**

- **Recovery, chosen: Violent Transfusion (Master/cards).** Target foe loses (G)(G); target ally is healed that much, +2 if the foe was slain. Range 5.
  - **Alt, booklet:** target foe loses 4; *you* gain 2 health for every health you've caused that foe to lose this turn; free if you just activated a Pact.
  - Settled 2026-10-08: the sheet version stays.
- **Ultimate: Bloodrage (Master/cards).** Free. Gain a skill action; this turn your strikes get +X Power, X = total damage you've dealt this turn.
  - Designer note: "OP. Change to damage of your last strike".
  - **Alt, booklet: Bloodlust.** Free. Choose a foe; this turn, every strike against it strikes again for the same amount; you also gain the Active benefits of all three Pacts this turn.
  - **Alt, BT PNG: Bloodrage v2.** +1 Action; whenever you play an attack skill, play a copy as a free action.
  - Settled 2026-10-08: **Bloodrage** (sheet) stays.
- **Talents (Master):**
  - **Blood Potence:** healing stores Potence stacks; your next strike spends them for +1 Power each.
  - **Lethal Predator:** strikes against foes below half health get Keen +3; recharge a skill when you slay.
  - **Primacy:** +1 Armor, +1 Power; once per turn, free Provoke on a target foe.
- **Booklet tip:** "Don't underestimate Adrenaline Surge. The Kindleborne and the Traceless, in particular, can do a lot with an extra action."

## 5. Traceless (Role: high-mobility disruptor; Core: Shadow copies; Difficulty: Very High)

The two eras differ most here.

| Mechanic | Booklet (2013, flat) | Master and cards (2014) | **Chosen** |
|---|---|---|---|
| Shadow creation | Whenever you shift out of a square, you may place a Shadow there | Same | Same |
| Shadow lifetime | Shadows **fade at end of turn** | Persist; **max 3** on the field | **Master** (persistent, cap 3): it supports Mirage Shift, Shadowstorm and set-up turns |
| Shadowstep | Free: consume a Shadow, teleport to its square | Same | Same |
| Copying | **Shadowstrike keyword** on specific skills: **every** Shadow copies the strike at **half damage** (total damage only, no riders) | **Innate trigger:** when you play any attack skill, **one** Shadow may copy it (full strike, from its own square, same range), then is consumed | **Master.** Gloom Edge, Phantom Blur, Phantasmal Killer, Versatility and Shadowstorm are all written against it |
| Probability Armor | +1 **Armor** per Shadow | +1 **Evasion** per Shadow | **Armor**: Evasion means a hit/miss roll, which conflicts with guaranteed hits. Flagged |
| Shadow blocking | Not targetable; don't block movement or line of sight | Same | Same |

### Basic: Displacer Strike (Melee)

- **Chosen:** shift 2 squares; before or after the shift, strike target foe for **4**. A Shadow copying it shifts 2 additional squares (Master).
- **Alt, booklet:** Shadowstrike (each Shadow copies at half damage).
- **Note:** the shift out of your square drops a Shadow, which is the core combo. From melee range, Displacer Strike to the far side of the foe, then Gloom Edge; the new Shadow copies the attack (booklet tip).

### Skills

| Slot | Standard | Heroic | Rec | Range | Notes |
|---|---|---|---|---|---|
| A1 | **Gloom Edge**: (Si)(Si); inflict Blind on each foe struck by a Shadow copying this | **Stifling Gloom**: (G)(Si); Stun instead | 2 (cards) | Melee | The sheet leaves rec blank; the cards say 2. 2023: 8 dmg, cd 2. |
| AA1 | **Phantom Dash**: shift 2; each foe shifted through for the first time this turn adds +2 to the shift; then strike each foe shifted through this turn for (Si) | **Phantom Blur**: (G); Shadows copying it aren't consumed | 3 | Special | The rules note says the extension counts as a second shift, so it drops a second Shadow. |
| D1 | **Chimeric Cloak**: Prepare. Until end of turn, the next strike or effect that would affect you negatively has no effect on you | **Chimeric Screen**: all such strikes and effects this turn | 3 | Self | **Cards and sheet agree. M4 (2023 halving) must change** to full negation of the next harmful strike or effect, through the enemy phase. |
| M1 | **Mirage Shift**: Maneuver; place a Shadow in target square; until end of turn, you may swap squares with a Shadow as a free action | **Mirage Dance**: any ally may swap with a Shadow or a willing ally as a free action | 3 | Range 6 | The booklet tip calls it "Mirage Jump": swapping doesn't consume the Shadow. |
| U1 | **Tactical Disruption** (cards): your strikes against target foe deal (Br) bonus and you choose all its targets and focuses this turn | **Tactical Distortion** (cards): burst 4 version | 3 | Range 4 | **Alt, Master:** the names are swapped (Distortion = Standard); Free; change one target of the chosen foe's skills once this turn, or all of them until end of turn (Heroic). **Chosen: Master** (newer; Free fits a reaction). Needs enemy intents to be visible first. |
| A2, AA2, D2, M2, U2 | (blank in the sheet) | | | | Never designed. |

**Recovery, Ultimate and Talents:**

- **Recovery, chosen: Perfect Decoy (Master/cards).** Free, Reactive, unlimited range. The next time damage would bring an *ally* below 1 health this turn, prevent it, heal that ally (G)(Si), and they may teleport 4.
  - **Alt, booklet:** self only; consume a Shadow and teleport to it; prevent the strike; heal 16.
- **Ultimate, chosen: Shadowstorm (Master).** Teleport each Shadow anywhere; until end of turn any number of Shadows can copy a skill with Shadowstrike.
  - The cards add: "Shadows are not consumed by Shadowstep or Shadowstrike this turn".
  - **Alt, booklet: Simulacrum.** Free; a Shadow becomes a targetable, blocking Simulacrum minion under your control that lasts several turns.
- **Talents (Master):**
  - **Dark Harmony:** when you and a Shadow strike the same target, both strikes get +1 Power.
  - **Phantasmal Killer:** a Shadow that slays isn't consumed and may immediately play Displacer Strike with +1 Power, up to 3 times per turn.
  - **Versatility:** once per turn, a Shadow may copy an ally's attack instead.

## 6. Other kits (not in M5; see the Master transcription)

- **Soulweaver: built in M7 (2026-10-08).** See the decisions log for the calls made. Built: Fates Intertwined (Tether + the four Infusions), Spirit Flare, Soul Echo (card version), Dread Diffusion, Strength in Unity, Essence Shift, Well of Souls, Conveyance, Anima Nexus. Not built: the Alpha-only sheet skills (Steal Spirit, Essence Gyre, Renewing Glow, Astral Jump, the unnamed U2), Heroic versions and Talents.
  - Fates Intertwined: at turn start, Tether to an ally within 5. Once per turn, when you unveil a card, activate an Infusion: Potent (both basic-attack free), Stalwart (both shielded 1), Sage (both recharge a skill), Elusive (both shift 2).
  - The Infusion trigger now works on real unveils: any card a Soulweaver skill uses (Michael, 2026-10-08).
  - Basic: **Spirit Flare** (Alpha). Cards: Soul Echo/Cascade, Dread Diffusion/Expulsion, Strength in Unity/Unbreakable Union, Essence Shift/Meld, Well/Sea of Souls, Conveyance, Anima Nexus.
  - Some card names differ from the sheet (Soul Spike/Lance in the sheet, Soul Echo/Cascade on the cards).
- **Kindleborne: built in M8 (2026-10-08).** See the decisions log for the calls made. Built: Rising Heat (with the Stoke skill for Ignite and Dissipate), Tinderbolt, Wracking Flame, Stoking Blast, Cinder Wave, Ember Shield, Flickerstep, Ash Augur, Cauterizing Brand, Burnout. Not built: the Alpha-only sheet skills (Fiery Burst, Choking Ash, Frictious Feet, Hearthfire), Heroic versions and Talents.
  - Rising Heat: store unveiled cards as Heat (max 5); discard 5+ value to **Ignite** (next skill free) or **Dissipate** (heal (Si), +1 Feint).
  - **Card vs sheet:** where they differ, the newer sheet wins, per section 1. Flickerstep: sheet (G)+2, card (G)(G)+1. Cauterizing Brand: sheet (G)(G)(G), card (G)(G)(Si). Burnout: sheet "copy the next 3 Ignited skills", card "on each Ignite, strike a foe for the Heat discarded".
  - *Note:* the Soulweaver port took Well of Souls' recharge from its card (3; sheet 4) and Soul Echo from its card (the sheet's Soul Spike needs the Attunement grid).
- **Techsage: Modular Technology.** Gain 1 Energy per turn; spend it on Mods (Power Cycler, Reflex Armor, Ballistic Shaper). Several slots are blank; the roster decision says the Techsage may be set aside.
- **Golgothon (boss):**
  - Basics with targeting rules: **Grave Smash** (move 4 toward the foe who dealt the most damage this turn; strike (B)(B)(B) + Daze, else Carrion Spew); **Carrion Spew** (highest-health foe in range 6, (B)(B), force 1 in a random direction).
  - Scripts: **Death's Grasp** (burst 6, (B), pull 5); **Death's Caress** (burst 6, lose 7 minus distance); **Unquenched** (enrage stack +1 Power, Restless Dead marks become Welcoming Dead minions); **Welcoming Dead** (summon 3 near the farthest foe).
  - The 8-page booklet (`Booklets/Golgothon`) is not yet extracted.

## 7. What changes in M5 because of this

- **Bound in Blood rework:**
  - One active Pact (Savagery, Vampiric or Predation), with on-activation effects plus Active effects.
  - Replaces the per-foe permanent Pacts from M4.
- **Chimeric Cloak rework:** Prepare; full negation of the next harmful strike or effect until the next player phase.
- **Acute Coagulant:** recharge 1, and a duration-2 heal-over-time that also heals when struck for 2+.
- **Blade Fury:** add the once-per-turn free play after ending a move adjacent to a foe.
- **Port per this doc:** Rending Claws, Rage Strike, Bloody Rush, Verve Magnet, Adrenal Surge, Displacer Strike, Illusive Shadows (Shadowstep, Shadowstrike, Probability Armor), Gloom Edge, Phantom Dash, Mirage Shift, Tactical Distortion.
- **Heroic versions** wait for the Soulstream rules.
- **Decision needed first:** the glyph-to-number translation in section 3, and Bloodlust vs Bloodrage.
