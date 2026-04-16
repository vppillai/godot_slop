# Furniture hazard — a sliding couch/chair that moves in a fixed direction.
# Spawned from screen edges at 30s+. Speed 100, gentle wobble rotation.
# Self-destructs when offscreen (generous bounds due to large size).
#
# All visuals drawn in _draw() — shadow -> body -> cushion -> legs.
# Legs are drawn ON TOP of the body so they're visible as dark corner stubs.

extends Area2D

const SPEED: float = 100.0

var direction: Vector2 = Vector2.RIGHT
var wobble_offset: float = 0.0  # Random phase for wobble animation

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	wobble_offset = randf() * TAU

## Called by main.gd. Sets the movement direction (typically UP/DOWN/LEFT/RIGHT).
func setup(dir: Vector2) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	rotation = sin(Time.get_ticks_msec() * 0.004 + wobble_offset) * 0.06
	if position.x < -200 or position.x > 1480 or position.y < -200 or position.y > 920:
		queue_free()

func _draw() -> void:
	# Shadow (flat ellipse below body; y=44 peeks past body bottom at y=40)
	_draw_ellipse(Vector2(4, 44), 48.0, 10.0, Color(0, 0, 0, 0.15))
	# Body (100x80 dark brown rect)
	draw_rect(Rect2(-50, -40, 100, 80), Color(0.25, 0.18, 0.12))
	# Cushion (80x60 lighter rect centered on body)
	draw_rect(Rect2(-40, -30, 80, 60), Color(0.4, 0.25, 0.15))
	# Legs (drawn after body so they appear as dark stubs at corners)
	var leg_color := Color(0.15, 0.1, 0.06)
	draw_rect(Rect2(-48, -38, 8, 10), leg_color)   # Top-left
	draw_rect(Rect2(40, -38, 8, 10), leg_color)     # Top-right
	draw_rect(Rect2(-48, 28, 8, 10), leg_color)     # Bottom-left
	draw_rect(Rect2(40, 28, 8, 10), leg_color)      # Bottom-right

func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, col)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
