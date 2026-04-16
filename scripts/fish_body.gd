# Fish body — procedural drawing of the fish sprite with wiggle animation.
# All visuals are drawn in _draw() so layering is controlled:
# shadow (behind) -> body -> tail -> eye -> mouth -> fin -> speed glow (on top).
#
# Wiggle: scale.y oscillates while the fish is moving (velocity > 10).
# Speed glow: pulsing yellow dots orbit the fish during puddle speed boost.

extends Node2D

var time: float = 0.0
var wiggle_enabled: bool = true

func _process(delta: float) -> void:
	if not wiggle_enabled:
		return
	time += delta
	var parent := get_parent() as CharacterBody2D
	if parent and parent.velocity.length() > 10.0:
		# Only wiggle scale.y — scale.x is controlled by player.gd for flipping
		scale.y = 1.0 + sin(time * 15.0) * 0.15
	else:
		scale.y = lerpf(scale.y, 1.0, delta * 5.0)
	queue_redraw()  # Needed every frame for speed glow animation

func _draw() -> void:
	# Drop shadow (offset below body so it peeks out underneath)
	_draw_ellipse(Vector2(2, 18), 18.0, 6.0, Color(0, 0, 0, 0.15))

	# Body — orange ellipse
	var points := PackedVector2Array()
	for i in range(24):
		var angle := i * TAU / 24.0
		points.append(Vector2(cos(angle) * 22.0, sin(angle) * 14.0))
	draw_colored_polygon(points, Color(1.0, 0.5, 0.0))

	# Tail
	var tail := PackedVector2Array([
		Vector2(-18, -6), Vector2(-36, -14),
		Vector2(-36, 14), Vector2(-18, 6),
	])
	draw_colored_polygon(tail, Color(1.0, 0.4, 0.0))

	# Eye
	draw_circle(Vector2(10, -4), 5.0, Color.WHITE)
	draw_circle(Vector2(11, -4), 2.5, Color.BLACK)

	# Mouth
	draw_line(Vector2(18, 2), Vector2(12, 4), Color(0.7, 0.3, 0.0), 1.5)

	# Dorsal fin
	var fin := PackedVector2Array([
		Vector2(-4, -13), Vector2(4, -22), Vector2(10, -12),
	])
	draw_colored_polygon(fin, Color(1.0, 0.35, 0.0))

	# Speed boost glow — pulsing yellow dots orbiting the fish
	var parent := get_parent() as CharacterBody2D
	if parent and parent.speed_boost_timer > 0.0:
		var glow_time := Time.get_ticks_msec() / 1000.0
		for i in range(8):
			var angle := i * TAU / 8.0 + glow_time * 3.0
			var dist := 28.0 + sin(glow_time * 5.0 + i) * 4.0
			var dot_pos := Vector2(cos(angle) * dist, sin(angle) * dist * 0.7)
			var alpha := 0.5 + sin(glow_time * 4.0 + i * 0.8) * 0.3
			draw_circle(dot_pos, 2.5, Color(1, 0.9, 0.2, alpha))

func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, col)
