# Floor lines + decor — draws the hardwood floor plank grid and random
# decorative items (rug corners, toy blocks, dust bunnies, crumb trails).
#
# Grid extends beyond viewport bounds (-200 to 1480/920) to cover camera
# zoom and rotation without visible gaps.
#
# Decor items are generated once in _ready() at random positions that avoid
# a 200px radius around the center (where the player starts). All decor is
# very subtle (alpha 0.12-0.18) — background detail, not gameplay elements.

extends Node2D

var _decor_items: Array = []  # Array of {pos: Vector2, type: int, color: Color}

func _ready() -> void:
	_generate_decor()

func _generate_decor() -> void:
	var center := Vector2(640, 360)
	for i in range(8):
		var pos := Vector2.ZERO
		# Try up to 20 times to find a position outside the center zone
		for _attempt in range(20):
			pos = Vector2(randf_range(40, 1240), randf_range(40, 680))
			if pos.distance_to(center) > 200.0:
				break
		var decor_type := randi() % 4
		var decor_color := Color(
			randf_range(0.5, 0.8), randf_range(0.3, 0.6),
			randf_range(0.2, 0.5), randf_range(0.12, 0.18))
		_decor_items.append({"pos": pos, "type": decor_type, "color": decor_color})

func _draw() -> void:
	_draw_floor_grid()
	_draw_decor_items()

func _draw_floor_grid() -> void:
	var line_color := Color(0.75, 0.64, 0.48, 0.4)
	# Horizontal plank lines (60px spacing)
	for y in range(-200, 920, 60):
		draw_line(Vector2(-200, y), Vector2(1480, y), line_color, 1.0)
	# Vertical plank joints (staggered every other row)
	for row in range(-4, 16):
		var y_start: float = row * 60.0
		var offset: float = 0.0 if row % 2 == 0 else 160.0
		for x in range(int(offset) - 320, 1600, 320):
			draw_line(Vector2(x, y_start), Vector2(x, y_start + 60), line_color, 1.0)

func _draw_decor_items() -> void:
	for item in _decor_items:
		var pos: Vector2 = item["pos"]
		var col: Color = item["color"]
		match item["type"]:
			0:  # Rug corner — small colored triangle
				var tri := PackedVector2Array([pos, pos + Vector2(18, 0), pos + Vector2(0, 14)])
				draw_colored_polygon(tri, col)
			1:  # Toy block — tiny colored square
				draw_rect(Rect2(pos.x, pos.y, 10, 10), col)
			2:  # Dust bunny — 3 overlapping gray circles
				var gray := Color(0.5, 0.5, 0.5, col.a)
				draw_circle(pos, 5.0, gray)
				draw_circle(pos + Vector2(4, -2), 4.0, gray)
				draw_circle(pos + Vector2(-3, 3), 3.5, gray)
			3:  # Crumb trail — 3 small dots
				var crumb := Color(0.6, 0.5, 0.35, col.a)
				draw_circle(pos, 2.0, crumb)
				draw_circle(pos + Vector2(6, 2), 1.5, crumb)
				draw_circle(pos + Vector2(12, -1), 1.8, crumb)
