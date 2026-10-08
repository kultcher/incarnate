class_name Enums
## Every shared enum lives here. Never redeclare these in other scripts.

enum Team { PLAYER, ENEMY }

## How a battle ended. DRAW only happens when the round limit runs out.
enum Outcome { NONE, VICTORY, DEFEAT, DRAW }

## What happens when a status is applied to a unit that already has it.
enum Stacking {
	REFRESH,      ## Keep one copy; reset its duration.
	ADD,          ## Keep one copy; add a stack (up to max_stacks) and reset its duration.
	INDEPENDENT,  ## Every application is its own copy (e.g. one Pact per foe).
}

## What an action point is spent on. FREE costs nothing.
enum Cost { MOVE, SKILL, FREE }

## Highlight tiles, in the same order as art/tiles/highlights.png.
enum Highlight { GRID, MOVE, ATTACK, AID, SPECIAL, PATH, HOVER }

## How a movement treats other units on the way.
enum PassThrough {
	NONE,    ## Blocked by every unit.
	ALLIES,  ## Normal move: allies can be passed, enemies block.
	ALL,     ## Shift: passes through any unit.
}

## Skill slots, as in the 2013 rules (one standard skill of each type).
enum Slot { BASIC, ATTACK, AREA, DEFENSE, MOBILITY, UTILITY, ULTIMATE, RECOVERY }

## Which cells a targeting step considers before filtering.
enum TargetShape {
	SELF,      ## Only the caster's own cell.
	ADJACENT,  ## The four orthogonal neighbours of the origin.
	WITHIN,    ## Every cell from range_min to range_max squares away.
}

## Where a targeting step measures from.
enum TargetOrigin {
	CASTER,    ## The caster's cell.
	PREVIOUS,  ## The cell picked in the previous step (or the caster for step 0).
}

## What must be in a cell for it to be a legal pick.
enum TargetFilter {
	ANY,           ## Any cell on the board that isn't blocked terrain.
	EMPTY,         ## No unit and no blocking terrain.
	UNIT,          ## Any unit.
	ENEMY,         ## A unit on the other team.
	ALLY,          ## A unit on the caster's team, not the caster.
	ALLY_OR_SELF,  ## A unit on the caster's team, the caster included.
	OWN_SHADOW,    ## One of the caster's Shadows, with no unit standing on it.
}

## Soulstream card tiers. Ranges: Bronze 1-3, Silver 2-4, Gold 3-5, so one
## tier step is exactly +/-1 to a card's value.
enum Tier { BRONZE, SILVER, GOLD }

## Soulstream card suits, from the 2014 cards. Nothing reads them yet; suit
## bonuses (a Blade for Bound in Blood, Heroic versions) come later.
enum Suit { BLADE, ORB, PORTAL, WARD }

## What counts down a status's duration.
enum StatusClock {
	OWNER_TURN,  ## The start of each of its owner's turns.
	ROUND,       ## The start of each round. "Until end of turn" effects use
	             ## this: a turn covers both phases, so they last until the
	             ## next round starts, whichever side applied them.
}

## How a unit got from one cell to another. Statuses react differently: only
## shifts leave Shadows; Cripple ends after a walk.
enum MoveKind { WALK, SHIFT, TELEPORT, FORCED }
