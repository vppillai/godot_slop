# Shoe hazard — a thrown shoe that flies in a straight line and spins.
# Spawned from a random screen edge, aimed at a random point in the play area.
# Speed 350, tumbles at 10 rad/s. Self-destructs when offscreen.
#
# All visuals drawn in _draw() — shadow -> body -> sole -> lace holes.

extends Area2D

const SPEED: float = 350.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

## Called by main.gd. Sets the flight direction (normalized).
func setup(dir: Vector2) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	rotation += 10.0 * delta  # Tumble spin
	if position.x < -80 or position.x > 1360 or position.y < -80 or position.y > 800:
		queue_free()

func _draw() -> void:
	# Shadow
	_draw_ellipse(Vector2(2, 16), 22.0, 7.0, Color(0, 0, 0, 0.15))
	# Sole (dark, wider than upper — extends forward for toe shape)
	var sole_pts := PackedVector2Array([
		Vector2(-18, 4), Vector2(22, 4), Vector2(26, 8),
		Vector2(24, 12), Vector2(-18, 12)
	])
	draw_colored_polygon(sole_pts, Color(0.25, 0.15, 0.08))
	# Shoe upper (brown leather, with curved toe bump)
	var upper_pts := PackedVector2Array([
		Vector2(-16, -12), Vector2(8, -12), Vector2(18, -8),
		Vector2(24, -2), Vector2(24, 6), Vector2(-16, 6)
	])
	draw_colored_polygon(upper_pts, Color(0.55, 0.35, 0.2))
	# Tongue (lighter flap sticking up from opening)
	var tongue_pts := PackedVector2Array([
		Vector2(-14, -12), Vector2(-6, -12),
		Vector2(-4, -18), Vector2(-16, -18)
	])
	draw_colored_polygon(tongue_pts, Color(0.65, 0.45, 0.3))
	# Opening (dark hole where foot goes)
	var opening_pts := PackedVector2Array([
		Vector2(-16, -10), Vector2(-4, -10), Vector2(-4, -4), Vector2(-16, -4)
	])
	draw_colored_polygon(opening_pts, Color(0.15, 0.08, 0.04))
	# Lace holes (visible white dots on upper)
	var lace_col := Color(0.9, 0.85, 0.8)
	draw_circle(Vector2(2, -6), 1.5, lace_col)
	draw_circle(Vector2(8, -4), 1.5, lace_col)
	draw_circle(Vector2(14, -2), 1.5, lace_col)
	# Laces (thin lines connecting holes)
	draw_line(Vector2(2, -6), Vector2(8, -4), Color(0.9, 0.85, 0.8, 0.6), 1.0)
	draw_line(Vector2(8, -4), Vector2(14, -2), Color(0.9, 0.85, 0.8, 0.6), 1.0)

func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, col)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
