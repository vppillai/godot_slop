extends Node2D

var text: String = ""
var color: Color = Color.YELLOW

func _ready() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 60.0, 1.2)
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 1.2)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, Vector2(-60, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 120, 22, 4, Color.BLACK)
	draw_string(font, Vector2(-60, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 120, 22, color)
