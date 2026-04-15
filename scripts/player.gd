extends CharacterBody2D

signal died

const SPEED: float = 300.0
const MAX_HP: int = 3
const INVINCIBILITY_DURATION: float = 1.5

var hp: int = MAX_HP
var invincible: bool = false
var invincible_timer: float = 0.0
var flash_timer: float = 0.0

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_invincibility(delta)
	_clamp_to_screen()

func _handle_movement() -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	velocity = input_dir * SPEED
	move_and_slide()
	if input_dir.x < 0:
		$Body.scale.x = -1
	elif input_dir.x > 0:
		$Body.scale.x = 1

func _handle_invincibility(delta: float) -> void:
	if not invincible:
		return
	invincible_timer -= delta
	flash_timer -= delta
	if flash_timer <= 0.0:
		$Body.visible = not $Body.visible
		flash_timer = 0.1
	if invincible_timer <= 0.0:
		invincible = false
		$Body.visible = true

func _clamp_to_screen() -> void:
	var vp_size := get_viewport_rect().size
	position.x = clampf(position.x, 20.0, vp_size.x - 20.0)
	position.y = clampf(position.y, 20.0, vp_size.y - 20.0)

func take_hit() -> void:
	if invincible:
		return
	hp -= 1
	_update_appearance()
	if hp <= 0:
		died.emit()
		set_physics_process(false)
		$Body.visible = false
		return
	invincible = true
	invincible_timer = INVINCIBILITY_DURATION
	flash_timer = 0.1
	var tween := get_tree().create_tween()
	var original_pos := position
	for i in range(6):
		var offset := Vector2(randf_range(-5, 5), randf_range(-5, 5))
		tween.tween_property(self, "position", original_pos + offset, 0.03)
	tween.tween_property(self, "position", original_pos, 0.03)

func _update_appearance() -> void:
	match hp:
		3:
			$Body.modulate = Color(1.0, 0.6, 0.1)
		2:
			$Body.modulate = Color(0.9, 0.7, 0.4)
		1:
			$Body.modulate = Color(0.7, 0.7, 0.5)
		_:
			$Body.modulate = Color(0.5, 0.5, 0.5)
