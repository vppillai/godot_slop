# Puddle — speed boost pickup. Grants 2s of 550 speed (vs normal 300).
# Despawns after 15s with fade. Spawns blue collection particles on pickup.
#
# Visual: translucent blue ellipse with inner highlight + 3 animated shimmer dots.
# Collision layer 4, mask 1 — interacts with player (layer 1).

extends Area2D

var lifetime: float = 15.0
var shimmer_time: float = 0.0  # Drives shimmer highlight animation

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	shimmer_time = randf() * TAU  # Randomize phase

func _process(delta: float) -> void:
	shimmer_time += delta
	lifetime -= delta
	if lifetime < 3.0:
		modulate.a = lifetime / 3.0
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()  # Shimmer animation needs per-frame redraw

func _draw() -> void:
	# Outer ellipse (translucent blue)
	var points := PackedVector2Array()
	for i in range(20):
		var angle := i * TAU / 20.0
		points.append(Vector2(cos(angle) * 28.0, sin(angle) * 16.0))
	draw_colored_polygon(points, Color(0.4, 0.65, 1.0, 0.25))
	# Inner highlight ellipse (smaller, offset)
	var inner := PackedVector2Array()
	for i in range(12):
		var angle := i * TAU / 12.0
		inner.append(Vector2(cos(angle) * 16.0 - 4.0, sin(angle) * 8.0 - 2.0))
	draw_colored_polygon(inner, Color(0.6, 0.8, 1.0, 0.2))
	# Shimmer highlights (3 dots that drift via sin/cos)
	for i in range(3):
		var offset_x := sin(shimmer_time * 1.5 + i * 2.0) * 8.0
		var offset_y := cos(shimmer_time * 1.2 + i * 1.5) * 4.0
		var alpha := 0.15 + sin(shimmer_time * 2.0 + i) * 0.1
		draw_circle(Vector2(offset_x, offset_y), 4.0, Color(0.8, 0.95, 1.0, alpha))

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("apply_speed_boost"):
		_spawn_collection_particles()
		body.apply_speed_boost()
		queue_free()

## Blue burst particles at pickup location (parented to Main so they survive queue_free).
func _spawn_collection_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.position = position
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.4
	particles.speed_scale = 2.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	particles.color = Color(0.4, 0.65, 1.0, 0.8)
	get_parent().add_child(particles)
	particles.emitting = true
	var tween := particles.create_tween()
	tween.tween_callback(particles.queue_free).set_delay(1.0)
