class_name EventSink
extends Node
## Whatever receives the resolver's events. The Presenter is one; tests
## and AI simulation run with none. Keeps core/ free of view/ references.


func enqueue(_event: GameEvent) -> void:
	pass


func wait_idle() -> void:
	pass
