# Cat hazard — wanders the play area and lunges at the player when close.
#
# State machine: WANDER -> WARNING (0.35s) -> LUNGE -> WANDER
#   WANDER:  Moves at 150 speed, picks random direction every 2s.
#   WARNING: Freezes in place, draws red circle + "!" above head (0.35s).
#   LUNGE:   Dashes toward player's last-known position at 400 speed (0.3s).
#
# Spawned from edge of screen by main.gd, initial direction points toward center.
# Self-destructs after 15s lifetime or when offscreen.
#
# All visuals drawn in _draw() (no child polygon nodes) to control layer order:
# shadow -> warning circle -> body -> eyes -> exclamation mark.

extends Area2D

const SPEED: float = 150.0
const LUNGE_SPEED: float = 400.0
const LUNGE_RANGE: float = 120.0       # Distance to trigger lunge
const DIRECTION_CHANGE_TIME: float = 2.0
const WARNING_DURATION: float = 0.35   # Freeze time before lunging
const MAX_LIFETIME: float = 15.0

enum State { WANDER, WARNING, LUNGE }

var state: State = State.WANDER
var direction: Vector2 = Vector2.RIGHT
var dir_timer: float = 0.0
var lunge_dir: Vector2 = Vector2.ZERO
var lunge_timer: float = 0.0
var warning_timer: float = 0.0
var warning_target: Vector2 = Vector2.ZERO  # Player position when warning started
var player_ref: CharacterBody2D = null
var lifetime: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	dir_timer = DIRECTION_CHANGE_TIME

## Called by main.gd after instantiation. Sets initial direction toward play area center.
func setup(player: CharacterBody2D) -> void:
	player_ref = player
	var center := Vector2(640, 360)
	direction = (center - position).normalized()
	direction = direction.rotated(randf_range(-0.5, 0.5))

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= MAX_LIFETIME:
		queue_free()
		return
	match state:
		State.WANDER:
			_process_wander(delta)
			_check_lunge()
		State.WARNING:
			_process_warning(delta)
		State.LUNGE:
			_process_lunge(delta)
	_cleanup_if_offscreen()

func _process_wander(delta: float) -> void:
	dir_timer -= delta
	if dir_timer <= 0.0:
		direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		dir_timer = DIRECTION_CHANGE_TIME
	position += direction * SPEED * delta

func _check_lunge() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var dist := position.distance_to(player_ref.position)
	if dist < LUNGE_RANGE:
		state = State.WARNING
		warning_timer = WARNING_DURATION
		warning_target = player_ref.position
		queue_redraw()

func _process_warning(delta: float) -> void:
	warning_timer -= delta
	queue_redraw()  # Animate warning circle alpha
	if warning_timer <= 0.0:
		state = State.LUNGE
		lunge_dir = (warning_target - position).normalized()
		lunge_timer = 0.3
		queue_redraw()

func _process_lunge(delta: float) -> void:
	position += lunge_dir * LUNGE_SPEED * delta
	lunge_timer -= delta
	if lunge_timer <= 0.0:
		state = State.WANDER
		dir_timer = DIRECTION_CHANGE_TIME
		queue_redraw()

func _draw() -> void:
	# Shadow (peeks below body at y=28; body bottom is y=24)
	_draw_ellipse(Vector2(2, 28), 22.0, 8.0, Color(0, 0, 0, 0.15))

	# Warning indicator
	if state == State.WARNING:
		var alpha := 0.12 + sin(warning_timer * 20.0) * 0.06
		draw_circle(Vector2.ZERO, LUNGE_RANGE, Color(1, 0, 0, alpha))

	# Body
	var body_pts := PackedVector2Array([
		Vector2(-24, -10), Vector2(-18, -26), Vector2(-10, -16),
		Vector2(10, -16), Vector2(18, -26), Vector2(24, -10),
		Vector2(24, 16), Vector2(0, 24), Vector2(-24, 16)
	])
	draw_colored_polygon(body_pts, Color(0.3, 0.3, 0.35))

	# Eyes (yellow squares)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -6), Vector2(-6, -6), Vector2(-6, -2), Vector2(-10, -2)]), Color(1, 1, 0))
	draw_colored_polygon(PackedVector2Array([Vector2(6, -6), Vector2(10, -6), Vector2(10, -2), Vector2(6, -2)]), Color(1, 1, 0))

	# Exclamation mark above head during warning
	if state == State.WARNING:
		var font := ThemeDB.fallback_font
		if font:
			draw_string(font, Vector2(-6, -34), "!", HORIZONTAL_ALIGNMENT_CENTER, 12, 20, Color(1, 0.2, 0.2))

func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, col)

func _cleanup_if_offscreen() -> void:
	if position.x < -100 or position.x > 1380 or position.y < -100 or position.y > 820:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
