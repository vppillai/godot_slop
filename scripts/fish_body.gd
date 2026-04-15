extends Node2D

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	var parent := get_parent() as CharacterBody2D
	if parent and parent.velocity.length() > 10.0:
		# Wiggle while moving
		scale.y = 1.0 + sin(time * 15.0) * 0.15
		scale.x = 1.0 - sin(time * 15.0) * 0.05
	else:
		scale.y = lerpf(scale.y, 1.0, delta * 5.0)
		scale.x = lerpf(scale.x, 1.0, delta * 5.0)

func _draw() -> void:
	# Fish body (orange ellipse)
	var points := PackedVector2Array()
	for i in range(24):
		var angle := i * TAU / 24.0
		points.append(Vector2(cos(angle) * 22.0, sin(angle) * 14.0))
	draw_colored_polygon(points, Color(1.0, 0.5, 0.0))

	# Tail (triangle, left side)
	var tail := PackedVector2Array([
		Vector2(-18, -6),
		Vector2(-36, -14),
		Vector2(-36, 14),
		Vector2(-18, 6),
	])
	draw_colored_polygon(tail, Color(1.0, 0.4, 0.0))

	# Eye (white circle with black pupil)
	draw_circle(Vector2(10, -4), 5.0, Color.WHITE)
	draw_circle(Vector2(11, -4), 2.5, Color.BLACK)

	# Mouth
	draw_line(Vector2(18, 2), Vector2(12, 4), Color(0.7, 0.3, 0.0), 1.5)

	# Dorsal fin
	var fin := PackedVector2Array([
		Vector2(-4, -13),
		Vector2(4, -22),
		Vector2(10, -12),
	])
	draw_colored_polygon(fin, Color(1.0, 0.35, 0.0))
