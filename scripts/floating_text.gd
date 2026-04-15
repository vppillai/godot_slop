extends Node2D

var text: String = ""
var color: Color = Color.YELLOW

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 60.0, 1.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.2)
	tween.parallel().tween_property(self, "scale", Vector2(1.3, 1.3), 1.2)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	# Bug 24 fix: wider text box so "NOT THE ROOMBA!" isn't clipped
	draw_string_outline(font, Vector2(-150, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 300, 22, 4, Color.BLACK)
	draw_string(font, Vector2(-150, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 300, 22, color)
