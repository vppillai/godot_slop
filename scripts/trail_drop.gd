# Trail drop — small circle spawned behind the player every 0.06s while moving.
# Fades out over 0.8s then self-destructs. Radius randomized on spawn (2-5px).
#
# Color: blue normally, yellow when speed boosted.
# Boost detection: player.gd sets meta "boost_color" = true when spawning during boost.

extends Node2D

var radius: float = 3.0

func _ready() -> void:
	radius = randf_range(2.0, 5.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var col: Color
	if has_meta("boost_color") and get_meta("boost_color"):
		col = Color(1.0, 0.85, 0.2, 0.45)  # Yellow for speed boost
	else:
		col = Color(0.5, 0.7, 1.0, 0.35)   # Blue for normal
	draw_circle(Vector2.ZERO, radius, col)
