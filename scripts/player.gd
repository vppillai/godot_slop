# Player — the fish. Handles movement (keyboard + touch joystick), health,
# invincibility frames, speed boost, trail particles, and visual feedback.
#
# Signals: died, took_damage, healed, boosted
# Set active=false to freeze the player (used during title/end screens).

extends CharacterBody2D

signal died
signal took_damage
signal healed
signal boosted

const SPEED: float = 300.0
const BOOST_SPEED: float = 550.0
const MAX_HP: int = 3
const INVINCIBILITY_DURATION: float = 1.0  # Seconds of invincibility after a hit
const DESIGN_WIDTH: float = 1280.0         # Clamp bounds (design resolution)
const DESIGN_HEIGHT: float = 720.0

var hp: int = MAX_HP
var invincible: bool = false
var invincible_timer: float = 0.0
var flash_timer: float = 0.0
var trail_timer: float = 0.0
var speed_boost_timer: float = 0.0  # Remaining seconds of boost (from puddle pickup)
var active: bool = true             # False during title screen and after death/win
var facing_right: bool = true
var autoplay: bool = false          # When true, main.gd drives movement (Konami cheat)

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
	if autoplay:
		# Movement handled by main.gd _update_autoplay() during cheat mode
		if speed_boost_timer > 0.0:
			speed_boost_timer -= delta
		return
	var input_dir := Vector2.ZERO
	# Prefer virtual joystick input on touch devices; fall back to keyboard
	var joystick = get_node_or_null("/root/Main/HUD/VirtualJoystick")
	if joystick and joystick.visible and joystick.get_direction().length() > 0.1:
		input_dir = joystick.get_direction()
	else:
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.y = Input.get_axis("move_up", "move_down")
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	velocity = input_dir * _get_current_speed()
	move_and_slide()
	# Flip fish body to face movement direction
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
	# Flash body visibility on/off every 0.1s
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
		trail_timer = 0.06  # ~16 drops/sec
		var drop := Node2D.new()
		drop.set_script(_trail_drop_script)
		drop.position = position
		if speed_boost_timer > 0.0:
			drop.set_meta("boost_color", true)  # Trail turns yellow when boosted
		get_parent().add_child(drop)

func _clamp_to_screen() -> void:
	position.x = clampf(position.x, 20.0, DESIGN_WIDTH - 20.0)
	position.y = clampf(position.y, 20.0, DESIGN_HEIGHT - 20.0)


# =============================================================================
# Damage / healing / boost
# =============================================================================

func take_hit() -> void:
	if invincible or not active:
		return
	hp -= 1
	_update_appearance()
	_spawn_hit_particles()
	_spawn_floating_text(hit_messages[randi() % hit_messages.size()], Color(1, 0.3, 0.3))
	took_damage.emit()  # Emitted before death check so main.gd can trigger hit freeze
	if hp <= 0:
		died.emit()
		active = false
		set_physics_process(false)
		$Body.visible = false
		return
	invincible = true
	invincible_timer = INVINCIBILITY_DURATION
	flash_timer = 0.1
	# Brief body shake for hit feedback
	var tween := create_tween()
	for i in range(6):
		var offset := Vector2(randf_range(-5, 5), randf_range(-5, 5))
		tween.tween_property($Body, "position", offset, 0.03)
	tween.tween_property($Body, "position", Vector2.ZERO, 0.03)

func heal() -> void:
	if not active or hp >= MAX_HP:
		return
	hp += 1
	_update_appearance()
	_spawn_floating_text("PHEW!", Color(0.3, 1.0, 0.5))
	healed.emit()

func apply_speed_boost() -> void:
	if not active:
		return
	speed_boost_timer = 2.0
	_spawn_floating_text("ZOOM!", Color(0.3, 0.8, 1.0))
	boosted.emit()

## Celebratory spin + scale animation on win.
func victory_dance() -> void:
	active = false
	velocity = Vector2.ZERO
	$Body.wiggle_enabled = false
	var x_sign := signf($Body.scale.x) if $Body.scale.x != 0.0 else 1.0
	$Body.scale = Vector2(x_sign, 1.0)
	$Body.position = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property($Body, "rotation", TAU * 3, 1.5).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property($Body, "scale", Vector2(x_sign * 1.4, 1.4), 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property($Body, "scale", Vector2(x_sign, 1.0), 0.7).set_ease(Tween.EASE_IN)


# =============================================================================
# Visual helpers
# =============================================================================

## Tints the fish body based on remaining HP (white -> yellowish -> dull).
func _update_appearance() -> void:
	match hp:
		3: $Body.modulate = Color(1.0, 1.0, 1.0)
		2: $Body.modulate = Color(0.85, 0.85, 0.7)
		1: $Body.modulate = Color(0.65, 0.65, 0.55)
		_: $Body.modulate = Color(0.5, 0.5, 0.5)

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
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color(0.4, 0.6, 1.0, 0.8)
	get_parent().add_child(particles)
	particles.emitting = true
	var tween := particles.create_tween()
	tween.tween_callback(particles.queue_free).set_delay(1.5)

func _spawn_floating_text(msg: String, col: Color) -> void:
	var ft := Node2D.new()
	ft.set_script(_floating_text_script)
	ft.text = msg
	ft.color = col
	ft.position = position + Vector2(0, -30)
	get_parent().add_child(ft)
