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
	_draw_ellipse(Vector2(2, 14), 18.0, 7.0, Color(0, 0, 0, 0.15))
	# Shoe body
	var body_pts := PackedVector2Array([
		Vector2(-20, -10), Vector2(16, -10), Vector2(20, -6),
		Vector2(20, 10), Vector2(-20, 10)
	])
	draw_colored_polygon(body_pts, Color(0.55, 0.35, 0.2))
	# Sole (darker strip at bottom)
	var sole_pts := PackedVector2Array([
		Vector2(-20, 6), Vector2(20, 6), Vector2(20, 10), Vector2(-20, 10)
	])
	draw_colored_polygon(sole_pts, Color(0.3, 0.2, 0.1))
	# Lace holes (3 dark circles on upper body)
	var lace_col := Color(0.3, 0.18, 0.08)
	draw_circle(Vector2(-8, -4), 2.0, lace_col)
	draw_circle(Vector2(0, -4), 2.0, lace_col)
	draw_circle(Vector2(8, -4), 2.0, lace_col)

func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, col)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
