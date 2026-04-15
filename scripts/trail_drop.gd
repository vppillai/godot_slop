extends Node2D

# Bug 6 fix: store random radius once so _draw doesn't flicker
var radius: float = 3.0

func _ready() -> void:
	radius = randf_range(2.0, 5.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.7, 1.0, 0.35))
