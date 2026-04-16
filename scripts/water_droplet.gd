# Water droplet — healing pickup. Restores 1 HP on collection.
# Bobs up/down visually (collision stays fixed). Despawns after 12s with fade.
# Spawns blue collection particles on pickup.
#
# Visual: blue teardrop + 4 orbiting sparkle dots. All animated via queue_redraw().
# Collision layer 4, mask 1 — interacts with player (layer 1).

extends Area2D

var bob_time: float = 0.0
var lifetime: float = 12.0

# Visual-only vertical offset (collision shape doesn't move)
@onready var visual_offset: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	bob_time = randf() * TAU  # Randomize initial phase so droplets don't sync

func _process(delta: float) -> void:
	bob_time += delta * 4.0
	visual_offset = sin(bob_time) * 4.0
	queue_redraw()
	# Fade out during last 3 seconds of lifetime
	lifetime -= delta
	if lifetime < 3.0:
		modulate.a = lifetime / 3.0
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	# Blue teardrop shape (pinched at bottom via radius modulation)
	var points := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		var r := 8.0
		if angle > PI * 0.8 and angle < PI * 1.2:
			r = 4.0  # Pinch the bottom
		points.append(Vector2(cos(angle) * r * 0.7, sin(angle) * r + visual_offset))
	draw_colored_polygon(points, Color(0.3, 0.6, 1.0, 0.9))
	# Highlight
	draw_circle(Vector2(-2, -3 + visual_offset), 2.5, Color(0.7, 0.9, 1.0, 0.7))

	# Orbiting sparkle dots (4 white dots, pulsing alpha)
	var t := Time.get_ticks_msec() / 1000.0
	for i in range(4):
		var angle := i * TAU / 4.0 + t * 2.5
		var sparkle_pos := Vector2(cos(angle) * 14.0, sin(angle) * 10.0 + visual_offset)
		var alpha := 0.4 + sin(t * 3.0 + i * 1.5) * 0.3
		draw_circle(sparkle_pos, 1.5, Color(1, 1, 1, alpha))

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("heal"):
		_spawn_collection_particles()
		body.heal()
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
	particles.color = Color(0.3, 0.6, 1.0, 0.8)
	get_parent().add_child(particles)
	particles.emitting = true
	var tween := particles.create_tween()
	tween.tween_callback(particles.queue_free).set_delay(1.0)
