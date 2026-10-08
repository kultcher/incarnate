# Golgothon the Restless: Encounter Reference

Sources:
- **Booklet** (Sept 2013, flat-damage era): `references/BFTA (flat damage era_)/Booklets/Golgothon/Golgothon1-8.pdf`, also in `Final Form/`. It's the complete encounter script: setup, traits, timeline, notes. Page 8 (rewards and scaling) says "NOT YET IMPLEMENTED".
- **2014 cards** (Jan–Feb 2014, card-damage era): `Cards/SVG/Golgothon/` (B1 Grave Smash, B2 Carrion Spew, S1 Death's Grasp, S2 Death's Caress, S3 Unquenched, S4 Welcoming Dead). These carry the newer numbers in card notation and a step order (Roman numerals).
- **Targeting deck** (2014): `Cards/PNG/Target/` holds one card per Incarnate. The cards print a target icon where the booklet prints a targeting rule, so in 2014 the boss's targets were drawn at random.
- **Daze**, from the 2013 "Buffs Debuffs" doc on Drive: "Prevents a recharge. Recharge clears 1 stack."

Where the two disagree, the numbers come from the cards and the rules come from the booklet (the cards leave them out). Each such pick is flagged **Pick**.

**Health scale (2026-10-08):** the 2014 cards' numbers assume Incarnates with about 40 health, like the booklets; the 2014 sheet still writes "+1 Power per 50 health the foe has". So the encounter keeps the card damage as printed, and the Incarnates moved from 12 to **40 health** (see the design log). The translated column below uses that scale.

## 1. Setup

- **Board:** 10×10, open (25 shuffled 2×2 map tiles on the table).
- **Golgothon** starts top centre: his 2×2 body on columns 4–5, rows 1–2 (the "flex" squares around it are for when terrain blocks that).
- **Incarnates** start in the bottom three rows, columns 3–6.

## 2. Golgothon's stats and traits

| | Booklet (players at 40 health) | Translated (players at 40) |
|---|---|---|
| Health | 450 (tuned for 4 players) | **300**. **Pick:** first pass from autoplay: at 450 the AI never won; at 300 it wins about 1 in 4, in about 7 rounds, often losing with him under 50. People playing well should do better. |
| **Resolve 2** | Debuffs don't apply until he has 2 of the same type; he clears 2 at a time. | **Pick:** the first application of each debuff is absorbed; the second one applies, and the count resets. |
| **Sturdy 1** | Forced movement against him is 1 square shorter (minimum 1). | Same. |
| **Large** | Takes up a 2×2 space. | Same. Range and adjacency count from his nearest square. |
| **Trample** | He can enter occupied squares; units there are forced into the nearest open square. | Same. |

## 3. Turn timeline

The booklet's "turn" is a full round. Each round:

1. **Script start:** flavour text on turn 1, and on turns 3, 6, 9... (a Death's Caress warning).
2. **Player phase:** no encounter actions.
3. **Encounter phase**, in this order:
   - **I. Death's Grasp:** turns 2, 5, 8, 11...
   - **II. Death's Caress:** turns 3, 6, 9...
   - **III. Unquenched:** turns 4, 7, 10...
   - **IV. Grave Smash:** every turn.
   - **V. Carrion Spew:** every turn.
   - **VI. Welcoming Dead (summon):** every turn.
   - **VII. Minions act:** every turn, starting with the minion nearest the north-west corner.
4. **End phase:** no encounter actions.

The 2014 cards agree: the three scripted skills recharge 3 and share step I; Grave Smash is II, Carrion Spew III and Welcoming Dead IV.

## 4. Golgothon's actions

| Action | Booklet (2013) | 2014 card | Translated |
|---|---|---|---|
| **Death's Grasp** (burst 6) | Strike each foe in the burst for 5 (±1). Then, starting with the foe closest to him, force each 5 squares toward him. No line of sight needed. | Strike for **(Br)**; same pull. Rec 3. | Strike (Br), then pull 5, closest first. |
| **Death's Caress** (burst 6) | Each foe in the burst loses 28 health, minus 4 per square between him and it. Adjacent counts as 1 square. | Each foe loses **7**, minus 1 per square. Rec 3. | Health loss of **7 − distance** (6 when adjacent, 1 at 6 squares). |
| **Unquenched** (self) | Gain 1 Unquenched stack (each scales the encounter up 1 step). Replace each Restless Dead token with a Welcoming Dead. Lose 4 health per token replaced. | Gain a stack; **+1 Power per stack**. Replace tokens; lose **1** health per token. Rec 3. | Card version. Stacks also speed up the minions (§5). |
| **Grave Smash** (melee, move) | Target: the foe that dealt the most total damage to him this turn (minion damage doesn't count). Move 4 toward it, trampling. If in melee: strike for 10 (±2) and inflict Daze 1. Otherwise use Carrion Spew on that foe (so he Spews twice that turn). | Strike **(Si)(Si)(Br)** + Daze 1. Rec 1. | Card numbers, booklet rules. **Pick:** with no damage taken this turn, he targets the nearest foe. |
| **Carrion Spew** (range 6) | Target: the foe with the highest health in range. Strike for 6 (±2) and force it 1 square in a random direction (nothing happens if that's blocked). | Strike **(Si)(Br)**. Rec 1. | Card numbers, booklet rules. |
| **Welcoming Dead** (summon, unlimited) | Target: the foe furthest from him. Summon 3 Welcoming Dead minions in the nearest unoccupied squares to that foe, preferring squares further from him. They may appear past walls. | Same. Rec 1. | Same. |

**Pick (targeting):** the booklet's rules, not the 2014 random targeting deck. The rules make the fight a readable puzzle and can be shown in advance (§7). The deck is an easy swap if you want randomness back.

**Death's Grasp notes (booklet):** the pull stops at walls. Units can be pulled through friendly units; one that ends in an occupied square moves to the nearest open one. Units take the damage even if they aren't moved. **Pick:** the first build uses our normal forced movement, which stops at any unit; pulling closest-first keeps that close to the booklet.

## 5. Welcoming Dead (minion)

| | Booklet | Translated |
|---|---|---|
| Health | 8 | **5**. **Pick:** card-era strikes are smaller than the booklet's, so 8 would take two hits; 5 keeps them one-hit kills for most attacks. |
| **Welcoming Arms** (melee) | Move 0 (±1) squares toward the nearest foe, then strike a random adjacent foe for 2 (±1). | Move **1 per Unquenched stack**, then strike a random adjacent foe for **2**, +1 Power per Unquenched stack. |
| **Restless** (triggered) | When slain, leave a Restless Dead marker on its square. | Same. Markers don't block and can be walked through. |
| **Drag You Down** (innate) | While 2+ Welcoming Dead are adjacent to a player, that player can't take move actions or use move, shift or fly effects. Teleports and swaps still work, as do other effects of a skill that also moves. | Same. |

## 6. Statuses

- **Daze N:** the unit's next N cooldown ticks (start of its turn) don't happen; each skipped tick clears a stack.
- **Unquenched:** a stack count on Golgothon, shown on his icon strip.

## 7. Showing his turn (the intent display)

During the player phase the board shows what he will do. The shapes and targets update as you act.
- **Death's Grasp turn:** the burst-6 area, with "pull" marks.
- **Death's Caress turn:** the burst-6 area with each square's health loss (6 down to 1).
- **Grave Smash:** the current target, whoever has dealt him the most damage this turn.
- **Carrion Spew:** the current target, the highest-health foe in range.
- **Welcoming Dead:** the current target, the foe furthest from him.

## 8. Scaling (booklet p. 8, marked not yet implemented)

- **Per player above 4:** +220 health, +4 minion health, damage up 1 step.
- **Per player below 4:** the reverse.
- **Training mode:** scale down as if there were 1 fewer player, and summon only 2 minions at a time.

Not in the first build: our squad is always 4.

## 9. Text to show

- **Turn 1:** "Before you stands a creature that can only be described as a 'walking graveyard.' Twenty feet of mossy rock and upturned earth..." (booklet p. 4).
- **Turns 3, 6, 9:** "The necrotic mist surrounding Golgothon thickens... escape the epicenter before Death's Caress lulls you to a final rest."
- **On first use of each skill:** the booklet's read-aloud lines (pp. 5–7) work as one-line floating text or a log entry.
