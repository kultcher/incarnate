class_name AshAugurEffect
extends EffectDef
## Ash Augur: each Heat card below Gold is swapped for the top card of the
## next tier's deck. Gold cards stay.


func apply(ctx: ActionContext) -> void:
	var unit := ctx.caster
	var stream := ctx.resolver.soulstream(unit.team)
	for i in unit.heat.size():
		var old := unit.heat[i]
		if old.tier == Enums.Tier.GOLD:
			continue
		unit.heat[i] = stream.take((int(old.tier) + 1) as Enums.Tier)
		if stream.deck(old.tier) != null:
			stream.deck(old.tier).discard(old)
	unit.heat.sort_custom(func(a: Card, b: Card) -> bool: return a.value > b.value)
	ctx.resolver.cards_changed(unit.team)
