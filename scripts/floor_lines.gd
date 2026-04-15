extends Node2D

func _draw() -> void:
	var line_color := Color(0.75, 0.64, 0.48, 0.4)
	for y in range(0, 720, 60):
		draw_line(Vector2(0, y), Vector2(1280, y), line_color, 1.0)
	for row in range(0, 12):
		var y_start: float = row * 60.0
		var offset: float = 0.0 if row % 2 == 0 else 160.0
		for x in range(int(offset), 1280, 320):
			draw_line(Vector2(x, y_start), Vector2(x, y_start + 60), line_color, 1.0)
