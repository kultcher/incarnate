class_name DecisionProvider
extends Node
## Answers DecisionRequests. This base answers instantly with the request's
## ai_choice: it is what the AI, tests and autoplay use. The player's version
## (ui/player_decisions.gd) shows the PromptDialog and waits.


## Returns an option index, or DecisionRequest.DECLINED.
func choose(request: DecisionRequest) -> int:
	return request.ai_choice
