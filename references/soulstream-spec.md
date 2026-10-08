# The Soulstream: suit cards (spec, 2026-10-08)

This replaces the card-damage Soulstream (tier decks, card values, readying cards in place of draws). Locked calls are Michael's; **Provisional** marks Claude's calls, made to keep the game running until the skill update pass.

## 1. Numbers are flat

- **Locked.** Damage, healing, shields and health loss are flat numbers. Nothing is drawn when a skill resolves.
- Skills keep the 2014 tier notation for now, read as fixed values: **Bronze 2, Silver 3, Gold 4** (the old medians). So "(Si)(Si)" is 6, Grave Smash's (Si)(Si)(Br) is 8. **Provisional:** the skill update pass will write plain numbers.
- **Provisional:** a strike still has parts (one per tier), and a dodge still cancels the smallest part (a one-part strike is grazed to 1). This keeps Evasion working as before.

## 2. Tiers of a skill

- **Tier 1:** the base skill.
- **Tier 2 (boon):** the base skill plus a boon, usually a straightforward boost. Paid by priming one card of the skill's boon suit.
- **Tier 3 (Heroic):** a transformation of the skill. Paid by priming two of the skill's boon suit.
- **Deferred:** the boons and Heroics themselves (the skill update pass). The engine already has the hook: a skill lists its boon suits, and primed cards that match are spent when it's used (one match = boon, two = Heroic).

## 3. The deck

One Soulstream per side: 60 cards.

| Cards | Count |
| --- | --- |
| Base: 9 of each suit (Blade, Ward, Orb, Portal) | 36 |
| Wild (any suit) | 4 |
| Two-suit cards, 2 of each combination including doubles: BB, BW, BO, BP, WW, WO, WP, OO, OP, PP | 20 |

- A two-suit card counts as both suits; a double (BB) counts as two of that suit, so one double pays a Heroic.
- A Wild counts as any one suit, chosen when it's used.
- When the draw pile runs out, the discards are shuffled back in.

## 4. Where cards are

- **Hands (locked):** each Incarnate draws 1 card at the start of the player phase. Hands hold **2**. If a draw would make 3, the oldest (leftmost) card is **activated** first (its base effects, below).
- **The shared row (provisional, kept from before):** up to 3 face-up cards; 1 is added each round. Any Incarnate can use a row card.
- **Flips (locked):** cards are only flipped by specific effects. The first one is Fates Intertwined (Soulweaver, §7).

## 5. Using a card

- **Double-click: activate.** The card's base effect for each of its suits, then it's discarded. Free (no action).
- **Single click: prime** it for the selected Incarnate's next skill (click again to unprime). If the skill has a boon suit the primed cards match, they're spent for its boon or Heroic; otherwise they stay in the hand.

### Base effects (locked)

| Suit | Effect |
| --- | --- |
| Blade | +1 damage on your next attack |
| Ward | +2 Shield until end of turn |
| Portal | +1 move until end of turn |
| Orb | Recharge one skill |

- **Provisional:**
  - "End of turn" means the round, as everywhere else: a Ward shield lasts through the enemy phase.
  - Blade's +1 applies to every strike of the next skill tagged attack, then ends; it stacks.
  - Orb ticks one recharge off a skill: the only one recharging, or the one you pick (Wild works the same way for the suit).
  - With nothing recharging, Orb does nothing (it can still be activated, or be cycled).
  - A double does its effect twice (BB: +2 on the next attack).

## 6. Kindleborne Heat (provisional rework)

- The card-store version of Rising Heat depended on unveiling cards, which no longer happens.
- **Heat** is now a counter, 0 to 5.
  - Each Kindleborne skill that costs an action (so not an Ignited skill, a Burnout replay or a free skill) adds 1 Heat.
  - **Ignite** costs 2 Heat (+1 for each Ignite this turn): the next skill is free.
  - **Dissipate** costs 2 Heat: heal 3, +1 Feint.
- This is the "less snowbally" direction from the 2014 designer note, and also your first knob: Ignited skills don't make Heat. A normal turn (2 skills) earns one Ignite.
- **Wracking Flame** gets +1 Power per Heat (was: your best Heat card's value). **Ash Augur** gains 2 Heat (was: upgrade every Heat card).

## 7. Soulweaver Infusions (provisional rework)

- Fates Intertwined triggered on unveiled cards, which no longer happens. It now uses a flip, which makes it the first flip effect.
- At the start of the Soulweaver's turn, **flip the top card**. Its suit picks the Infusion, with no prompt:
  - Blade → Potent;
  - Ward → Stalwart;
  - Orb → Sage;
  - Portal → Elusive.
- The Infusion goes to her and her Tethered ally right away. If she Tethers a new ally that turn, the new ally gets it as well.
- Two-suit cards give both Infusions. A Wild asks her to pick.
- **Soul Echo** counts suits in the row, as before. Two-suit cards count each suit, and a Wild counts for every suit.
- **Well of Souls** takes row cards into hands, as before.

## 8. Future work (noted)

- Boons and Heroics for every skill; Golgothon's suit riders.
- **Highlights:** when a skill could use a boon or a Heroic, highlight the cards that would pay for it, with different colours for boon and Heroic.
- Bond points for the Bloodthane (Blades are a natural source).
