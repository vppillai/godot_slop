extends Area2D

const SPEED: float = 150.0
const LUNGE_SPEED: float = 400.0
const LUNGE_RANGE: float = 120.0
const DIRECTION_CHANGE_TIME: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var dir_timer: float = 0.0
var lunging: bool = false
var lunge_dir: Vector2 = Vector2.ZERO
var lunge_timer: float = 0.0
var player_ref: CharacterBody2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	dir_timer = DIRECTION_CHANGE_TIME

func setup(player: CharacterBody2D) -> void:
	player_ref = player

func _physics_process(delta: float) -> void:
	if lunging:
		_process_lunge(delta)
		return
	_process_wander(delta)
	_check_lunge()
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
		lunging = true
		lunge_dir = (player_ref.position - position).normalized()
		lunge_timer = 0.3

func _process_lunge(delta: float) -> void:
	position += lunge_dir * LUNGE_SPEED * delta
	lunge_timer -= delta
	if lunge_timer <= 0.0:
		lunging = false
		dir_timer = DIRECTION_CHANGE_TIME

func _cleanup_if_offscreen() -> void:
	if position.x < -100 or position.x > 1380 or position.y < -100 or position.y > 820:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
