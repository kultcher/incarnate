class_name WellOfSoulsEffect
extends EffectDef
## Well of Souls: the caster and each Tethered ally may each take a card
## from the shared row into their hand. (The 2014 card says "attune"; the
## Attunement grid is out of scope, so a claimed card goes to the hand.)


func apply(ctx: ActionContext) -> void:
	var r := ctx.resolver
	var row := r.soulstream(ctx.caster.team).row
	for unit in Tethers.with_allies(ctx.caster, ctx.board):
		if row.is_empty():
			return
		if not unit.is_alive():
			continue
		var request := DecisionRequest.new()
		request.team = ctx.caster.team
		request.title = ctx.skill.display_name
		request.icon = ctx.skill.icon
		request.text = "Which card from the shared row should %s take into their hand?" \
				% unit.def.display_name
		for i in row.size():
			request.add_option(str(row[i]), "")
			if row[i].value > row[request.ai_choice].value:
				request.ai_choice = i
		request.decline_label = "None"
		var pick := await r.decide(request)
		if pick >= 0 and pick < row.size():
			r.claim_row_card(unit, row[pick])
