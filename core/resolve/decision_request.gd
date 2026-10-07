class_name DecisionRequest
extends RefCounted
## A choice the rules need from a unit's owner, e.g. "Bind which Pact?" or
## "Use Chimeric Cloak?". The player answers through the PromptDialog; the AI
## answers at once with [member ai_choice].

## The answer when the player declines (the "No" / "Don't bind" button).
const DECLINED := -1

## Whose decision it is.
var team: Enums.Team = Enums.Team.PLAYER
var title: String = ""
var text: String = ""
var icon: Texture2D
var options: Array[DecisionOption] = []
## Label of the decline button. Empty = no way to decline.
var decline_label: String = ""
## Shows "Always choose this" and reports whether it was ticked.
var offer_remember: bool = false
## What the AI picks (an option index, or DECLINED).
var ai_choice: int = 0
## Set by the provider: whether the player ticked "Always choose this".
var remember: bool = false


func add_option(label: String, description: String = "", option_icon: Texture2D = null) -> void:
	var o := DecisionOption.new()
	o.label = label
	o.description = description
	o.icon = option_icon
	options.append(o)


class DecisionOption:
	var label: String
	var description: String
	var icon: Texture2D
