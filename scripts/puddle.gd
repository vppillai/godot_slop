extends Area2D

var lifetime: float = 15.0  # Bug 11 fix: despawn after 15 seconds

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime < 3.0:
		modulate.a = lifetime / 3.0
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	var points := PackedVector2Array()
	for i in range(20):
		var angle := i * TAU / 20.0
		points.append(Vector2(cos(angle) * 28.0, sin(angle) * 16.0))
	draw_colored_polygon(points, Color(0.4, 0.65, 1.0, 0.25))
	var inner := PackedVector2Array()
	for i in range(12):
		var angle := i * TAU / 12.0
		inner.append(Vector2(cos(angle) * 16.0 - 4.0, sin(angle) * 8.0 - 2.0))
	draw_colored_polygon(inner, Color(0.6, 0.8, 1.0, 0.2))

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("apply_speed_boost"):
		body.apply_speed_boost()
		queue_free()
