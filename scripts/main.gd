# Main game controller — manages game state, hazard/pickup spawning, difficulty
# scaling, and juice effects (hit freeze, screen shake, near-miss detection).
#
# Game flow: TITLE -> PLAYING -> WON or LOST -> restart (reload scene)
#
# Difficulty timeline (seconds elapsed):
#   0s  — Cats begin spawning
#  15s  — Shoes begin spawning
#  30s  — Furniture begins spawning
#  45s  — First roomba + wave announcement
#  50s  — Second roomba
#  55s  — Third roomba + cat frenzy (5 cats at once)
#
# Difficulty formula: 1.0 + elapsed/20.0 — spawn intervals shrink over time.

extends Node2D

enum GameState { TITLE, PLAYING, WON, LOST }

@onready var hud: CanvasLayer = $HUD
@onready var player: CharacterBody2D = $Player
@onready var floor_rect: ColorRect = $Floor
@onready var camera: Camera2D = $Camera

var state: GameState = GameState.TITLE
var time_remaining: float = 60.0

# --- Hazard scenes ---
var cat_scene: PackedScene = preload("res://scenes/hazards/cat.tscn")
var shoe_scene: PackedScene = preload("res://scenes/hazards/shoe.tscn")
var furniture_scene: PackedScene = preload("res://scenes/hazards/furniture.tscn")
var roomba_scene: PackedScene = preload("res://scenes/hazards/roomba.tscn")
var droplet_scene: PackedScene = preload("res://scenes/hazards/water_droplet.tscn")
var puddle_scene: PackedScene = preload("res://scenes/hazards/puddle.tscn")
var _floating_text_script = preload("res://scripts/floating_text.gd")

# --- Spawn timing (intervals in seconds, timers count down) ---
var cat_spawn_interval: float = 2.5
var cat_spawn_timer: float = 2.0       # First cat after 2s
var shoe_spawn_interval: float = 1.0
var shoe_spawn_timer: float = 1.5      # Grace period before first shoe
var furniture_spawn_interval: float = 4.0
var furniture_spawn_timer: float = 4.0  # Grace period before first furniture
var droplet_spawn_interval: float = 12.0
var droplet_spawn_timer: float = 5.0   # First droplet after 5s
var puddle_spawn_interval: float = 18.0
var puddle_spawn_timer: float = 10.0   # First puddle after 10s

# --- One-shot event flags ---
var roomba_spawned: bool = false         # 45s — first roomba
var third_roomba_spawned: bool = false   # 50s — "THEY HAVE FRIENDS!"
var second_roomba_spawned: bool = false  # 55s — "ANOTHER ONE?!"
var cat_frenzy_spawned: bool = false     # 55s — 5 cats at once
var _wave_15_announced: bool = false     # 15s — "SHOES INCOMING!"
var _wave_30_announced: bool = false     # 30s — "WATCH THE FURNITURE!"

# --- Atmosphere ---
var floor_start_color := Color(0.82, 0.71, 0.55, 1)
var floor_end_color := Color(0.85, 0.5, 0.4, 1)

# --- Game feel / juice ---
var _hit_freeze_timer: float = 0.0   # Counts down in real-time (not scaled)
var _shake_timer: float = 0.0        # Camera shake remaining duration
var _shake_intensity: float = 0.0    # Camera shake pixel offset magnitude
var _near_miss_cooldown: float = 0.0 # Prevents "CLOSE!" spam (2s between)
var _title_tween: Tween = null       # Fish flop animation on title screen

# --- Konami code cheat: Up Up Down Down Left Right Left Right B A ---
const KONAMI_SEQUENCE: Array[int] = [
	KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN,
	KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT,
	KEY_B, KEY_A,
]
var _konami_index: int = 0            # How far through the sequence the player is
var _autoplay: bool = false           # When true, fish auto-dodges and is invincible
var _autoplay_time: float = 0.0       # Drives the autopilot movement pattern


# =============================================================================
# Lifecycle
# =============================================================================

func _ready() -> void:
	hud.update_hp(player.hp)
	hud.update_timer(time_remaining)
	player.active = false  # Frozen during title screen
	player.took_damage.connect(_on_player_took_damage)
	hud.show_title()
	_start_title_animation()

func _process(delta: float) -> void:
	# Hit freeze runs outside the state gate — it must restore Engine.time_scale
	# even after the game ends. Uses real-time by dividing out the time scale.
	if _hit_freeze_timer > 0.0:
		_hit_freeze_timer -= delta * (1.0 / maxf(Engine.time_scale, 0.01))
		if _hit_freeze_timer <= 0.0:
			Engine.time_scale = 1.0

	if state != GameState.PLAYING:
		return

	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_win()
		return
	hud.update_timer(time_remaining)
	hud.update_hp(player.hp)
	_spawn_hazards(delta)
	_spawn_pickups(delta)
	_update_atmosphere()
	_update_screen_shake(delta)
	_check_near_miss(delta)
	if _autoplay:
		_update_autoplay(delta)


# =============================================================================
# Title screen
# =============================================================================

func _start_title_animation() -> void:
	# Fish flops back and forth while idle on title screen
	_title_tween = create_tween().set_loops()
	_title_tween.tween_property(player, "rotation", 0.15, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_title_tween.tween_property(player, "rotation", -0.15, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _unhandled_input(event: InputEvent) -> void:
	# Konami code detection during gameplay
	if state == GameState.PLAYING and event is InputEventKey and event.pressed and not _autoplay:
		if event.keycode == KONAMI_SEQUENCE[_konami_index]:
			_konami_index += 1
			if _konami_index >= KONAMI_SEQUENCE.size():
				_activate_autoplay()
		else:
			_konami_index = 0

	if state != GameState.TITLE:
		return
	var start := false
	if event is InputEventKey and event.pressed:
		start = true
	elif event is InputEventScreenTouch and event.pressed:
		start = true
	elif event is InputEventMouseButton and event.pressed:
		start = true
	if start:
		_start_game()

func _start_game() -> void:
	state = GameState.PLAYING
	# Stop title animation and reset fish rotation
	if _title_tween:
		_title_tween.kill()
		_title_tween = null
	player.rotation = 0.0
	player.active = true
	# 2s grace period — player flashes but can't be hurt
	player.invincible = true
	player.invincible_timer = 2.0
	player.flash_timer = 0.1
	hud.hide_title()
	hud.fade_from_black()
	# Show virtual joystick + swap button on touch devices
	var joystick = hud.get_node_or_null("VirtualJoystick")
	if joystick and DisplayServer.is_touchscreen_available():
		joystick.visible = true
		hud.show_swap_button()
	hud.show_wave_announcement("CATS!", Color(1.0, 0.8, 0.2))


# =============================================================================
# Hazard spawning
# =============================================================================

func _spawn_hazards(delta: float) -> void:
	var elapsed := 60.0 - time_remaining
	var difficulty: float = 1.0 + elapsed / 20.0  # 1.0x at start, 4.0x at 60s

	# Cats — continuous from start
	cat_spawn_timer -= delta
	if cat_spawn_timer <= 0.0:
		_spawn_cat()
		cat_spawn_timer = cat_spawn_interval / difficulty

	# Shoes — start at 15s
	if elapsed >= 15.0:
		shoe_spawn_timer -= delta
		if shoe_spawn_timer <= 0.0:
			_spawn_shoe()
			shoe_spawn_timer = shoe_spawn_interval / difficulty

	# Furniture — start at 30s
	if elapsed >= 30.0:
		furniture_spawn_timer -= delta
		if furniture_spawn_timer <= 0.0:
			_spawn_furniture()
			furniture_spawn_timer = furniture_spawn_interval / difficulty

	# Roombas — one-shot spawns at 45s, 50s, 55s
	if elapsed >= 45.0 and not roomba_spawned:
		_spawn_roomba()
		roomba_spawned = true
		hud.show_wave_announcement("ROOMBA ACTIVATED!", Color(1, 0.2, 0.2))
		_spawn_floating_text_at(player.position + Vector2(0, -50), "NOT THE ROOMBA!", Color(1, 0.2, 0.2))

	if elapsed >= 50.0 and not third_roomba_spawned:
		_spawn_roomba()
		third_roomba_spawned = true
		_spawn_floating_text_at(player.position + Vector2(0, -50), "THEY HAVE FRIENDS!", Color(1, 0.15, 0.15))

	if elapsed >= 55.0 and not second_roomba_spawned:
		_spawn_roomba()
		second_roomba_spawned = true
		_spawn_floating_text_at(player.position + Vector2(0, -50), "ANOTHER ONE?!", Color(1, 0.1, 0.1))

	# Cat frenzy — 5 cats at 55s for the final push
	if elapsed >= 55.0 and not cat_frenzy_spawned:
		cat_frenzy_spawned = true
		hud.show_wave_announcement("CAT FRENZY!", Color(1, 0.1, 0.1))
		for i in range(5):
			_spawn_cat()

func _spawn_pickups(delta: float) -> void:
	droplet_spawn_timer -= delta
	if droplet_spawn_timer <= 0.0:
		_spawn_droplet()
		droplet_spawn_timer = droplet_spawn_interval

	puddle_spawn_timer -= delta
	if puddle_spawn_timer <= 0.0:
		_spawn_puddle()
		puddle_spawn_timer = puddle_spawn_interval


# =============================================================================
# Atmosphere & announcements
# =============================================================================

func _update_atmosphere() -> void:
	var elapsed := 60.0 - time_remaining
	var t := elapsed / 60.0  # 0.0 to 1.0 progress

	# Floor darkens from warm tan to reddish
	floor_rect.color = floor_start_color.lerp(floor_end_color, t)

	# Gentle zoom-in over time (max 4% at 60s)
	camera.zoom = Vector2(1.0 + t * 0.04, 1.0 + t * 0.04)

	# Subtle camera tilt after 45s for added tension
	if elapsed > 45.0:
		camera.rotation = sin(Time.get_ticks_msec() * 0.003) * 0.01
	else:
		camera.rotation = 0.0

	_check_wave_announcements(elapsed)

func _check_wave_announcements(elapsed: float) -> void:
	if elapsed >= 15.0 and not _wave_15_announced:
		_wave_15_announced = true
		hud.show_wave_announcement("SHOES INCOMING!", Color(1, 0.6, 0.2))
	if elapsed >= 30.0 and not _wave_30_announced:
		_wave_30_announced = true
		hud.show_wave_announcement("WATCH THE FURNITURE!", Color(0.8, 0.4, 0.2))


# =============================================================================
# Game feel / juice
# =============================================================================

func _on_player_took_damage() -> void:
	# Brief time-scale freeze (50ms real-time) for impact
	Engine.time_scale = 0.05
	_hit_freeze_timer = 0.05
	# Camera shake
	_shake_timer = 0.2
	_shake_intensity = 6.0
	# Red flash overlay
	hud.flash_damage()

func _update_screen_shake(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		camera.offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity))
		if _shake_timer <= 0.0:
			camera.offset = Vector2.ZERO
	else:
		camera.offset = Vector2.ZERO

func _check_near_miss(delta: float) -> void:
	_near_miss_cooldown -= delta
	if _near_miss_cooldown > 0.0:
		return
	if not player.active or player.invincible:
		return
	# Check center-to-center distance to all hazards (collision_layer 2)
	for child in get_children():
		if child is Area2D and child.collision_layer == 2:
			var dist := player.position.distance_to(child.position)
			if dist > 30.0 and dist < 50.0:
				_near_miss_cooldown = 2.0
				_spawn_floating_text_at(player.position + Vector2(0, -40), "CLOSE!", Color(1, 1, 0))
				break



# =============================================================================
# Konami code autoplay — makes fish invincible and auto-dodges to win
# =============================================================================

func _activate_autoplay() -> void:
	_autoplay = true
	_konami_index = 0
	player.autoplay = true
	player.invincible = true
	player.invincible_timer = 999.0
	player.flash_timer = 0.1
	player.speed_boost_timer = 999.0
	_spawn_floating_text_at(player.position + Vector2(0, -50), "GOD FISH ACTIVATED", Color(1, 0.8, 0))
	hud.show_wave_announcement("GOD FISH MODE", Color(1, 0.8, 0))

## Auto-pilots the fish in a figure-8 dodge pattern, avoiding edges.
func _update_autoplay(delta: float) -> void:
	_autoplay_time += delta
	# Keep invincibility refreshed
	player.invincible = true
	player.invincible_timer = 2.0
	player.speed_boost_timer = 2.0
	# Figure-8 pattern centered on the play area
	var cx := 640.0
	var cy := 360.0
	var rx := 400.0
	var ry := 200.0
	var speed := 1.8
	var target_x := cx + cos(_autoplay_time * speed) * rx
	var target_y := cy + sin(_autoplay_time * speed * 2.0) * ry
	var target := Vector2(target_x, target_y)
	var dir := (target - player.position).normalized()
	player.velocity = dir * player.BOOST_SPEED
	player.move_and_slide()
	# Face movement direction
	if dir.x < 0 and player.facing_right:
		player.facing_right = false
		player.get_node("Body").scale.x = -abs(player.get_node("Body").scale.x)
	elif dir.x > 0 and not player.facing_right:
		player.facing_right = true
		player.get_node("Body").scale.x = abs(player.get_node("Body").scale.x)


# =============================================================================
# Spawn helpers
# =============================================================================

func _spawn_cat() -> void:
	var cat: Area2D = cat_scene.instantiate()
	cat.position = _random_edge_position()
	cat.setup(player)
	add_child(cat)

func _spawn_shoe() -> void:
	var shoe: Area2D = shoe_scene.instantiate()
	var spawn_pos := _random_edge_position()
	shoe.position = spawn_pos
	var target := Vector2(randf_range(200, 1080), randf_range(100, 620))
	shoe.setup((target - spawn_pos).normalized())
	add_child(shoe)

func _spawn_furniture() -> void:
	var furn: Area2D = furniture_scene.instantiate()
	var edge := randi() % 4
	match edge:
		0:
			furn.position = Vector2(randf_range(100, 1180), -80)
			furn.setup(Vector2.DOWN)
		1:
			furn.position = Vector2(randf_range(100, 1180), 800)
			furn.setup(Vector2.UP)
		2:
			furn.position = Vector2(-100, randf_range(100, 620))
			furn.setup(Vector2.RIGHT)
		3:
			furn.position = Vector2(1380, randf_range(100, 620))
			furn.setup(Vector2.LEFT)
	add_child(furn)

func _spawn_roomba() -> void:
	var roomba: Area2D = roomba_scene.instantiate()
	roomba.position = _random_edge_position()
	roomba.setup(player)
	add_child(roomba)

func _spawn_droplet() -> void:
	var drop: Area2D = droplet_scene.instantiate()
	drop.position = Vector2(randf_range(80, 1200), randf_range(80, 640))
	add_child(drop)

func _spawn_puddle() -> void:
	var puddle: Area2D = puddle_scene.instantiate()
	puddle.position = Vector2(randf_range(80, 1200), randf_range(80, 640))
	add_child(puddle)

func _spawn_floating_text_at(pos: Vector2, text: String, color: Color) -> void:
	var ft := Node2D.new()
	ft.set_script(_floating_text_script)
	ft.text = text
	ft.color = color
	ft.position = pos
	add_child(ft)

## Returns a random position just outside one of the 4 screen edges.
func _random_edge_position() -> Vector2:
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf_range(0, 1280), -40)   # Top
		1: return Vector2(randf_range(0, 1280), 760)    # Bottom
		2: return Vector2(-40, randf_range(0, 720))     # Left
		3: return Vector2(1320, randf_range(0, 720))    # Right
	return Vector2(-40, 360)


# =============================================================================
# Win / Lose / Restart
# =============================================================================

func _win() -> void:
	state = GameState.WON
	player.invincible = true  # Prevent death on the same frame as win
	player.active = false
	hud.update_timer(0.0)
	hud.reset_timer_style()  # Clear jitter/pulse so timer shows clean "0" on win screen
	hud.update_hp(player.hp)
	player.victory_dance()
	var survival_time := 60.0 - time_remaining
	hud.show_win(survival_time)
	_stop_all_hazards()

func _on_player_died() -> void:
	state = GameState.LOST
	hud.update_hp(player.hp)  # Show 0 hearts on death
	hud.reset_timer_style()   # Clear jitter/pulse so timer shows clean on end screen
	var survival_time := 60.0 - time_remaining
	hud.show_lose(survival_time)
	_stop_all_hazards()

func _stop_all_hazards() -> void:
	for child in get_children():
		if child is Area2D:
			child.set_physics_process(false)
			child.set_process(false)

func restart() -> void:
	Engine.time_scale = 1.0  # Ensure time_scale is normal before reload
	hud.fade_to_black(func(): get_tree().reload_current_scene())
