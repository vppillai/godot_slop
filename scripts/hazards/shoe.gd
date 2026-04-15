extends Area2D

const SPEED: float = 350.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	if position.x < -80 or position.x > 1360 or position.y < -80 or position.y > 800:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
