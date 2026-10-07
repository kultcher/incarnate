class_name HitFx
extends Sprite2D
## Plays a flipbook sheet once, then frees itself.

const SECONDS := 0.4
const DISPLAY_SIZE := 96.0


static func spawn(parent: Node, at: Vector2, sheet: Texture2D, grid: Vector2i) -> HitFx:
	var fx := HitFx.new()
	fx.texture = sheet
	fx.hframes = grid.x
	fx.vframes = grid.y
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var frame_size := float(sheet.get_width()) / grid.x
	fx.scale = Vector2.ONE * (DISPLAY_SIZE / frame_size)
	fx.position = at
	fx.z_index = 20
	parent.add_child(fx)
	fx._play()
	return fx


func _play() -> void:
	var tween := create_tween()
	tween.tween_property(self, "frame", hframes * vframes - 1, SECONDS).from(0)
	tween.tween_callback(queue_free)
