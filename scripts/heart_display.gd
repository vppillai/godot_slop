# HeartDisplay — draws 3 procedural heart shapes to show player HP.
# Red filled hearts = active HP, dark transparent hearts = lost HP.
# Replaces the old ASCII "<3 <3 <3" HPLabel approach.
#
# Usage: call update_hp(hp) whenever HP changes — triggers queue_redraw().
# Positioned at (30, 32) in hud.tscn as a child of the HUD CanvasLayer.
#
# Each heart is drawn as two overlapping circles (top lobes) + triangle (bottom).
# Hearts are spaced 36px apart horizontally.

extends Node2D

var current_hp: int = 3
var max_hp: int = 3

func update_hp(hp: int) -> void:
	current_hp = hp
	queue_redraw()

func _draw() -> void:
	for i in range(max_hp):
		var x_offset: float = i * 36.0
		var is_active: bool = i < current_hp
		_draw_heart(Vector2(x_offset, 0.0), is_active)

func _draw_heart(center: Vector2, is_active: bool) -> void:
	var col := Color(1.0, 0.2, 0.2) if is_active else Color(0.3, 0.1, 0.1, 0.4)
	# Top lobes
	_draw_filled_circle(center + Vector2(-6, -4), 7.0, col)
	_draw_filled_circle(center + Vector2(6, -4), 7.0, col)
	# Bottom point
	var tri := PackedVector2Array([
		center + Vector2(-13, -2),
		center + Vector2(13, -2),
		center + Vector2(0, 14),
	])
	draw_colored_polygon(tri, col)

func _draw_filled_circle(center: Vector2, radius: float, col: Color) -> void:
	var points := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))
	draw_colored_polygon(points, col)
