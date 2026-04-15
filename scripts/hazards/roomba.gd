extends Area2D

const SPEED: float = 100.0

var player_ref: CharacterBody2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(player: CharacterBody2D) -> void:
	player_ref = player

func _physics_process(delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var dir := (player_ref.position - position).normalized()
	position += dir * SPEED * delta
	rotation = dir.angle()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
