class_name PlayerDecisions
extends DecisionProvider
## Answers the player's decisions by asking them in the PromptDialog.

var dialog: PromptDialog


func choose(request: DecisionRequest) -> int:
	var answer: int = await dialog.ask(request)
	return answer
