class_name TestEvents
extends EventSink
## Records every event the resolver emits, standing in for the Presenter.

var events: Array[GameEvent] = []
var types: Array[StringName] = []


func enqueue(event: GameEvent) -> void:
	events.append(event)
	types.append(event.type)


func texts() -> Array[String]:
	var out: Array[String] = []
	for e in events:
		if e.type == GameEvent.FLOATING_TEXT:
			out.append(e.text)
	return out
