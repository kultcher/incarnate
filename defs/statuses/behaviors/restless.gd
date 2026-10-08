class_name RestlessBehavior
extends StatusBehavior
## Welcoming Dead: when it dies, a mark is left on its square (Restless
## Dead), which Golgothon's Unquenched raises again.

@export var mark_id: StringName = &"restless_dead"
@export var mark_icon: Texture2D


func on_owner_died(_inst: StatusInstance, cell: Vector2i, r: ActionResolver) -> void:
	r.add_mark(mark_id, cell, mark_icon)
