extends Node2D

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)

func _draw() -> void:
	draw_circle(Vector2.ZERO, randf_range(2.0, 5.0), Color(0.5, 0.7, 1.0, 0.35))
