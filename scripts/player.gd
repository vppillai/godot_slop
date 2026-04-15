extends CharacterBody2D

signal died
signal took_damage
signal healed
signal boosted

const SPEED: float = 300.0
const BOOST_SPEED: float = 550.0
const MAX_HP: int = 3
const INVINCIBILITY_DURATION: float = 1.5

var hp: int = MAX_HP
var invincible: bool = false
var invincible_timer: float = 0.0
var flash_timer: float = 0.0
var trail_timer: float = 0.0
var speed_boost_timer: float = 0.0
var active: bool = true
var facing_right: bool = true

var _trail_drop_script = preload("res://scripts/trail_drop.gd")
var _floating_text_script = preload("res://scripts/floating_text.gd")

var hit_messages: Array[String] = ["YIKES!", "OH NO!", "OUCH!", "EEK!", "SPLAT!", "ACK!"]

func _physics_process(delta: float) -> void:
	if not active:
		return
	_handle_movement(delta)
	_handle_invincibility(delta)
	_handle_trail(delta)
	_clamp_to_screen()

func _get_current_speed() -> float:
	if speed_boost_timer > 0.0:
		return BOOST_SPEED
	return SPEED

func _handle_movement(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	velocity = input_dir * _get_current_speed()
	move_and_slide()
	# Flip fish direction — set scale.x directly (fish_body only touches scale.y)
	if input_dir.x < 0 and facing_right:
		facing_right = false
		$Body.scale.x = -abs($Body.scale.x)
	elif input_dir.x > 0 and not facing_right:
		facing_right = true
		$Body.scale.x = abs($Body.scale.x)
	if speed_boost_timer > 0.0:
		speed_boost_timer -= delta

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

func _handle_trail(delta: float) -> void:
	if velocity.length() < 10.0:
		return
	trail_timer -= delta
	if trail_timer <= 0.0:
		trail_timer = 0.06
		var drop := Node2D.new()
		drop.set_script(_trail_drop_script)
		drop.position = position
		get_parent().add_child(drop)

func _clamp_to_screen() -> void:
	var vp_size := get_viewport_rect().size
	position.x = clampf(position.x, 20.0, vp_size.x - 20.0)
	position.y = clampf(position.y, 20.0, vp_size.y - 20.0)

func take_hit() -> void:
	if invincible:
		return
	hp -= 1
	_update_appearance()
	_spawn_hit_particles()
	_spawn_floating_text(hit_messages[randi() % hit_messages.size()], Color(1, 0.3, 0.3))
	took_damage.emit()
	if hp <= 0:
		died.emit()
		active = false
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

func heal() -> void:
	if hp >= MAX_HP:
		return
	hp += 1
	_update_appearance()
	_spawn_floating_text("PHEW!", Color(0.3, 1.0, 0.5))
	healed.emit()

func apply_speed_boost() -> void:
	speed_boost_timer = 2.0
	_spawn_floating_text("ZOOM!", Color(0.3, 0.8, 1.0))
	boosted.emit()

func victory_dance() -> void:
	active = false
	velocity = Vector2.ZERO
	# Stop fish_body wiggle so tween has full control
	$Body.wiggle_enabled = false
	$Body.scale = Vector2(1.0, 1.0)
	var tween := create_tween()
	tween.tween_property($Body, "rotation", TAU * 3, 1.5).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property($Body, "scale", Vector2(1.4, 1.4), 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property($Body, "scale", Vector2(1.0, 1.0), 0.7).set_ease(Tween.EASE_IN)

func _update_appearance() -> void:
	match hp:
		3:
			$Body.modulate = Color(1.0, 1.0, 1.0)
		2:
			$Body.modulate = Color(0.85, 0.85, 0.7)
		1:
			$Body.modulate = Color(0.65, 0.65, 0.55)
		_:
			$Body.modulate = Color(0.5, 0.5, 0.5)

func _spawn_hit_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.position = position
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12
	particles.lifetime = 0.5
	particles.speed_scale = 2.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 180.0
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color(0.4, 0.6, 1.0, 0.8)
	get_parent().add_child(particles)
	# Start emitting AFTER added to tree
	particles.emitting = true
	get_tree().create_tween().tween_callback(particles.queue_free).set_delay(1.5)

func _spawn_floating_text(msg: String, col: Color) -> void:
	var ft := Node2D.new()
	ft.set_script(_floating_text_script)
	ft.text = msg
	ft.color = col
	ft.position = position + Vector2(0, -30)
	get_parent().add_child(ft)
