extends Area2D

const SPEED: float = 80.0

var direction: Vector2 = Vector2.RIGHT
var wobble_offset: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	wobble_offset = randf() * TAU

func setup(dir: Vector2) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	rotation = sin(Time.get_ticks_msec() * 0.004 + wobble_offset) * 0.06
	if position.x < -200 or position.x > 1480 or position.y < -200 or position.y > 920:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
