extends Area2D

const SPEED: float = 150.0
const LUNGE_SPEED: float = 400.0
const LUNGE_RANGE: float = 120.0
const DIRECTION_CHANGE_TIME: float = 2.0
const WARNING_DURATION: float = 0.35
const MAX_LIFETIME: float = 15.0  # Bug 33 fix: cats don't linger forever

enum State { WANDER, WARNING, LUNGE }

var state: State = State.WANDER
var direction: Vector2 = Vector2.RIGHT
var dir_timer: float = 0.0
var lunge_dir: Vector2 = Vector2.ZERO
var lunge_timer: float = 0.0
var warning_timer: float = 0.0
var warning_target: Vector2 = Vector2.ZERO
var player_ref: CharacterBody2D = null
var lifetime: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	dir_timer = DIRECTION_CHANGE_TIME

# Bug 9 fix: initial direction points toward center of play area
func setup(player: CharacterBody2D) -> void:
	player_ref = player
	var center := Vector2(640, 360)
	direction = (center - position).normalized()
	# Add some randomness
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
	queue_redraw()
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
	if state == State.WARNING:
		var alpha := 0.12 + sin(warning_timer * 20.0) * 0.06
		draw_circle(Vector2.ZERO, LUNGE_RANGE, Color(1, 0, 0, alpha))

func _cleanup_if_offscreen() -> void:
	if position.x < -100 or position.x > 1380 or position.y < -100 or position.y > 820:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
