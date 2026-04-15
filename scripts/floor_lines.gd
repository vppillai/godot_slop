extends Node2D

# Bug 20 fix: draw lines over a larger area to cover camera zoom/rotation/expand
func _draw() -> void:
	var line_color := Color(0.75, 0.64, 0.48, 0.4)
	for y in range(-200, 920, 60):
		draw_line(Vector2(-200, y), Vector2(1480, y), line_color, 1.0)
	for row in range(-4, 16):
		var y_start: float = row * 60.0
		var offset: float = 0.0 if row % 2 == 0 else 160.0
		for x in range(int(offset) - 320, 1600, 320):
			draw_line(Vector2(x, y_start), Vector2(x, y_start + 60), line_color, 1.0)
