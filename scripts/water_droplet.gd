extends Area2D

var bob_time: float = 0.0
var lifetime: float = 12.0  # Bug 11 fix: despawn after 12 seconds

# Bug 8 fix: bob only the visual, not the collision shape
@onready var visual_offset: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	bob_time = randf() * TAU

func _process(delta: float) -> void:
	bob_time += delta * 4.0
	visual_offset = sin(bob_time) * 4.0
	queue_redraw()
	# Lifetime countdown with fade
	lifetime -= delta
	if lifetime < 3.0:
		modulate.a = lifetime / 3.0
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	# Blue teardrop shape drawn at visual offset (collision stays fixed)
	var points := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		var r := 8.0
		if angle > PI * 0.8 and angle < PI * 1.2:
			r = 4.0
		points.append(Vector2(cos(angle) * r * 0.7, sin(angle) * r + visual_offset))
	draw_colored_polygon(points, Color(0.3, 0.6, 1.0, 0.9))
	draw_circle(Vector2(-2, -3 + visual_offset), 2.5, Color(0.7, 0.9, 1.0, 0.7))

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("heal"):
		body.heal()
		queue_free()
