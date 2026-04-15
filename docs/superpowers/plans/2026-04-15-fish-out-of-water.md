# Fish Out of Water — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a top-down 2D dodge/survive game where a goldfish on a living room floor dodges cats, shoes, furniture, and a Roomba for 60 seconds.

**Architecture:** Single Godot scene with spawner logic in the main script. Player is a CharacterBody2D, hazards are Area2D nodes spawned dynamically. HUD is a CanvasLayer with Labels and Control nodes. All visuals are Godot primitives (Polygon2D, ColorRect, circles) — no external assets.

**Tech Stack:** Godot 4.6.2, GDScript, .tscn scene files

---

## File Map

```
project.godot                  — project config (1280x720, canvas_items stretch)
scenes/
  main.tscn                    — root scene: floor background, player instance, HUD
  player.tscn                  — goldfish CharacterBody2D + CollisionShape2D + Polygon2D body
  hazards/
    cat.tscn                   — cat Area2D + shape + visual
    shoe.tscn                  — shoe Area2D + shape + visual
    furniture.tscn             — furniture Area2D + shape + visual
    roomba.tscn                — roomba Area2D + shape + visual
  hud.tscn                     — CanvasLayer with timer, HP, flavor text, win/lose panels
scripts/
  main.gd                      — game state, timer, hazard spawning logic
  player.gd                    — movement, HP, invincibility, hit feedback
  hazards/
    cat.gd                     — wander + lunge AI
    shoe.gd                    — straight-line movement, auto-free off-screen
    furniture.gd               — slow slide across screen, auto-free off-screen
    roomba.gd                  — track toward player
  hud.gd                       — update timer, HP display, flavor text, show win/lose
```

---

### Task 1: Project Setup and Floor Background

**Files:**
- Create: `project.godot`
- Create: `scenes/main.tscn`
- Create: `scripts/main.gd`

- [ ] **Step 1: Create project.godot**

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; but it can also be manually edited if needed.

config_version=5

[application]

config/name="Fish Out of Water"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.6")

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"

[input]

move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":119,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194320,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

- [ ] **Step 2: Create scripts/main.gd (skeleton)**

```gdscript
extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var player: CharacterBody2D = $Player

var time_remaining: float = 60.0
var game_active: bool = true

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not game_active:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_win()

func _win() -> void:
	game_active = false
	hud.show_win()

func _on_player_died() -> void:
	game_active = false
	hud.show_lose()

func restart() -> void:
	get_tree().reload_current_scene()
```

- [ ] **Step 3: Create scenes/main.tscn (floor background + script)**

Build the main scene with a tan ColorRect as the floor background. The scene references `main.gd`. Player and HUD nodes will be added in later tasks.

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1_main"]

[node name="Main" type="Node2D"]
script = ExtResource("1_main")

[node name="Floor" type="ColorRect" parent="."]
offset_right = 1280.0
offset_bottom = 720.0
color = Color(0.82, 0.71, 0.55, 1)

[node name="FloorLines" type="Node2D" parent="."]
```

- [ ] **Step 4: Verify — open the project in Godot**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path /Users/vpillai/godot --headless --quit 2>&1`

Expected: Project loads without errors. (We'll run the actual game visually in later tasks.)

- [ ] **Step 5: Initialize git repo and commit**

```bash
cd /Users/vpillai/godot
git init
echo ".godot/" > .gitignore
git add .gitignore project.godot scenes/main.tscn scripts/main.gd docs/
git commit -m "feat: project setup with floor background and main game loop skeleton"
```

---

### Task 2: Player (Goldfish) Scene and Movement

**Files:**
- Create: `scenes/player.tscn`
- Create: `scripts/player.gd`
- Modify: `scenes/main.tscn` — add Player instance

- [ ] **Step 1: Create scripts/player.gd**

```gdscript
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
	# Flip fish to face movement direction
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
	# Screen shake
	var tween := get_tree().create_tween()
	var original_pos := position
	for i in range(6):
		var offset := Vector2(randf_range(-5, 5), randf_range(-5, 5))
		tween.tween_property(self, "position", original_pos + offset, 0.03)
	tween.tween_property(self, "position", original_pos, 0.03)

func _update_appearance() -> void:
	match hp:
		3:
			$Body.modulate = Color(1.0, 0.6, 0.1)  # Bright orange
		2:
			$Body.modulate = Color(0.9, 0.7, 0.4)  # Pale
		1:
			$Body.modulate = Color(0.7, 0.7, 0.5)  # Distressed
		_:
			$Body.modulate = Color(0.5, 0.5, 0.5)
```

- [ ] **Step 2: Create scenes/player.tscn**

The goldfish is a CharacterBody2D with a circle collision shape and a Polygon2D body (orange ellipse with tail).

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1_player"]

[sub_resource type="CircleShape2D" id="CircleShape2D_fish"]
radius = 16.0

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1_player")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_fish")

[node name="Body" type="Polygon2D" parent="."]
color = Color(1, 0.6, 0.1, 1)
polygon = PackedVector2Array(-20, -10, -10, -16, 10, -14, 20, -6, 22, 0, 20, 6, 10, 14, -10, 16, -20, 10, -30, -12, -36, 0, -30, 12, -20, 10)
```

The polygon draws an oval fish body with a triangular tail on the left side.

- [ ] **Step 3: Add Player instance to main.tscn**

Update `scenes/main.tscn` to instance the player scene and connect the `died` signal:

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1_main"]
[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="2_player"]

[node name="Main" type="Node2D"]
script = ExtResource("1_main")

[node name="Floor" type="ColorRect" parent="."]
offset_right = 1280.0
offset_bottom = 720.0
color = Color(0.82, 0.71, 0.55, 1)

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(640, 360)

[connection signal="died" from="Player" to="." method="_on_player_died"]
```

- [ ] **Step 4: Verify — run the game**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path /Users/vpillai/godot 2>&1`

Expected: Window opens, tan floor visible, orange fish shape at center, fish moves with WASD/arrows, stays within screen bounds.

- [ ] **Step 5: Commit**

```bash
git add scenes/player.tscn scripts/player.gd scenes/main.tscn
git commit -m "feat: add goldfish player with movement, HP, and invincibility"
```

---

### Task 3: HUD (Timer, HP, Flavor Text, Win/Lose Screens)

**Files:**
- Create: `scenes/hud.tscn`
- Create: `scripts/hud.gd`
- Modify: `scenes/main.tscn` — add HUD instance
- Modify: `scripts/main.gd` — connect HUD updates

- [ ] **Step 1: Create scripts/hud.gd**

```gdscript
extends CanvasLayer

signal restart_pressed

@onready var timer_label: Label = $TimerLabel
@onready var hp_label: Label = $HPLabel
@onready var flavor_label: Label = $FlavorLabel
@onready var end_panel: Panel = $EndPanel
@onready var end_title: Label = $EndPanel/Title
@onready var end_subtitle: Label = $EndPanel/Subtitle
@onready var restart_button: Button = $EndPanel/RestartButton

func _ready() -> void:
	end_panel.visible = false
	flavor_label.text = ""
	restart_button.pressed.connect(_on_restart_pressed)

func update_timer(time_remaining: float) -> void:
	var seconds := ceili(time_remaining)
	timer_label.text = str(seconds)

	# Flavor text at milestones
	if seconds <= 5:
		flavor_label.text = "THE BUS IS HERE!"
		flavor_label.modulate = Color(1, 0.2, 0.2)
	elif seconds <= 15:
		flavor_label.text = "ALMOST!"
		flavor_label.modulate = Color(1, 0.5, 0.1)
	elif seconds <= 45:
		flavor_label.text = "HANG IN THERE!"
		flavor_label.modulate = Color(1, 0.8, 0.2)
	else:
		flavor_label.text = ""

func update_hp(hp: int) -> void:
	var hearts := ""
	for i in range(hp):
		hearts += "<3 "
	hp_label.text = hearts.strip_edges()

func show_win() -> void:
	end_panel.visible = true
	end_title.text = "YOU SURVIVED!"
	end_subtitle.text = "The kid scooped you back into the bowl!"
	end_panel.modulate = Color(0.5, 1.0, 0.5)

func show_lose() -> void:
	end_panel.visible = true
	end_title.text = "GAME OVER"
	end_subtitle.text = "You became a cat snack."
	end_panel.modulate = Color(1.0, 0.5, 0.5)

func _on_restart_pressed() -> void:
	restart_pressed.emit()
```

- [ ] **Step 2: Create scenes/hud.tscn**

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/hud.gd" id="1_hud"]

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1_hud")

[node name="HPLabel" type="Label" parent="."]
offset_left = 20.0
offset_top = 10.0
offset_right = 300.0
offset_bottom = 50.0
theme_override_font_sizes/font_size = 28
theme_override_colors/font_color = Color(1, 0.3, 0.3, 1)
text = "<3 <3 <3"

[node name="TimerLabel" type="Label" parent="."]
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -60.0
offset_top = 10.0
offset_right = 60.0
offset_bottom = 60.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 36
theme_override_colors/font_color = Color(1, 1, 1, 1)
horizontal_alignment = 1
text = "60"

[node name="FlavorLabel" type="Label" parent="."]
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -200.0
offset_top = 60.0
offset_right = 200.0
offset_bottom = 100.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 24
horizontal_alignment = 1
text = ""

[node name="EndPanel" type="Panel" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -120.0
offset_right = 200.0
offset_bottom = 120.0
grow_horizontal = 2
grow_vertical = 2

[node name="Title" type="Label" parent="EndPanel"]
layout_mode = 1
offset_left = 20.0
offset_top = 20.0
offset_right = 380.0
offset_bottom = 80.0
theme_override_font_sizes/font_size = 36
horizontal_alignment = 1
text = "YOU SURVIVED!"

[node name="Subtitle" type="Label" parent="EndPanel"]
layout_mode = 1
offset_left = 20.0
offset_top = 80.0
offset_right = 380.0
offset_bottom = 130.0
theme_override_font_sizes/font_size = 18
horizontal_alignment = 1
autowrap_mode = 2
text = "The kid scooped you back!"

[node name="RestartButton" type="Button" parent="EndPanel"]
layout_mode = 1
offset_left = 120.0
offset_top = 150.0
offset_right = 280.0
offset_bottom = 200.0
text = "Play Again"
```

- [ ] **Step 3: Update main.tscn to add HUD instance and connect signals**

```ini
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1_main"]
[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="2_player"]
[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="3_hud"]

[node name="Main" type="Node2D"]
script = ExtResource("1_main")

[node name="Floor" type="ColorRect" parent="."]
offset_right = 1280.0
offset_bottom = 720.0
color = Color(0.82, 0.71, 0.55, 1)

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(640, 360)

[node name="HUD" parent="." instance=ExtResource("3_hud")]

[connection signal="died" from="Player" to="." method="_on_player_died"]
[connection signal="restart_pressed" from="HUD" to="." method="restart"]
```

- [ ] **Step 4: Update scripts/main.gd to drive HUD**

```gdscript
extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var player: CharacterBody2D = $Player

var time_remaining: float = 60.0
var game_active: bool = true

func _ready() -> void:
	hud.update_hp(player.hp)
	hud.update_timer(time_remaining)

func _process(delta: float) -> void:
	if not game_active:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_win()
	hud.update_timer(time_remaining)
	hud.update_hp(player.hp)

func _win() -> void:
	game_active = false
	hud.show_win()

func _on_player_died() -> void:
	game_active = false
	hud.show_lose()

func restart() -> void:
	get_tree().reload_current_scene()
```

- [ ] **Step 5: Verify — run the game**

Expected: Timer counts down from 60, HP hearts shown top-left. At 45s "HANG IN THERE!" appears. At 0s the win panel shows. Restart button reloads the scene.

- [ ] **Step 6: Commit**

```bash
git add scenes/hud.tscn scripts/hud.gd scenes/main.tscn scripts/main.gd
git commit -m "feat: add HUD with timer, HP, flavor text, and win/lose screens"
```

---

### Task 4: Cat Hazard

**Files:**
- Create: `scenes/hazards/cat.tscn`
- Create: `scripts/hazards/cat.gd`
- Modify: `scripts/main.gd` — add cat spawning logic

- [ ] **Step 1: Create scripts/hazards/cat.gd**

```gdscript
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
	# Pick a random starting direction
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
```

- [ ] **Step 2: Create scenes/hazards/cat.tscn**

A dark gray rounded shape with triangle ears.

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/hazards/cat.gd" id="1_cat"]

[sub_resource type="CircleShape2D" id="CircleShape2D_cat"]
radius = 24.0

[node name="Cat" type="Area2D"]
collision_layer = 2
collision_mask = 1
script = ExtResource("1_cat")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_cat")

[node name="Body" type="Polygon2D" parent="."]
color = Color(0.3, 0.3, 0.35, 1)
polygon = PackedVector2Array(-24, -10, -18, -26, -10, -16, 10, -16, 18, -26, 24, -10, 24, 16, 0, 24, -24, 16)

[node name="Eyes" type="Polygon2D" parent="."]
color = Color(1, 1, 0, 1)
polygon = PackedVector2Array(-10, -6, -6, -6, -6, -2, -10, -2)

[node name="Eyes2" type="Polygon2D" parent="."]
color = Color(1, 1, 0, 1)
polygon = PackedVector2Array(6, -6, 10, -6, 10, -2, 6, -2)
```

- [ ] **Step 3: Update scripts/main.gd — add cat spawning**

```gdscript
extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var player: CharacterBody2D = $Player

var time_remaining: float = 60.0
var game_active: bool = true

var cat_scene: PackedScene = preload("res://scenes/hazards/cat.tscn")

var cat_spawn_interval: float = 3.0
var cat_spawn_timer: float = 2.0

func _ready() -> void:
	hud.update_hp(player.hp)
	hud.update_timer(time_remaining)

func _process(delta: float) -> void:
	if not game_active:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_win()
	hud.update_timer(time_remaining)
	hud.update_hp(player.hp)
	_spawn_hazards(delta)

func _spawn_hazards(delta: float) -> void:
	cat_spawn_timer -= delta
	if cat_spawn_timer <= 0.0:
		_spawn_cat()
		cat_spawn_timer = cat_spawn_interval

func _spawn_cat() -> void:
	var cat: Area2D = cat_scene.instantiate()
	cat.position = _random_edge_position()
	cat.setup(player)
	add_child(cat)

func _random_edge_position() -> Vector2:
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf_range(0, 1280), -40)   # top
		1: return Vector2(randf_range(0, 1280), 760)    # bottom
		2: return Vector2(-40, randf_range(0, 720))     # left
		3: return Vector2(1320, randf_range(0, 720))    # right
	return Vector2(-40, 360)

func _win() -> void:
	game_active = false
	hud.show_win()

func _on_player_died() -> void:
	game_active = false
	hud.show_lose()

func restart() -> void:
	get_tree().reload_current_scene()
```

- [ ] **Step 4: Set player collision layer**

Update `scenes/player.tscn` to set the player's collision layer to 1 and mask to 0 (player doesn't need to detect areas, areas detect the player):

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1_player"]

[sub_resource type="CircleShape2D" id="CircleShape2D_fish"]
radius = 16.0

[node name="Player" type="CharacterBody2D"]
collision_layer = 1
collision_mask = 0
script = ExtResource("1_player")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_fish")

[node name="Body" type="Polygon2D" parent="."]
color = Color(1, 0.6, 0.1, 1)
polygon = PackedVector2Array(-20, -10, -10, -16, 10, -14, 20, -6, 22, 0, 20, 6, 10, 14, -10, 16, -20, 10, -30, -12, -36, 0, -30, 12, -20, 10)
```

- [ ] **Step 5: Verify — run the game**

Expected: Cats (dark gray shapes with yellow eyes) spawn from edges every 3 seconds. They wander across the floor and lunge at the goldfish when close. Getting hit flashes the fish and reduces HP.

- [ ] **Step 6: Commit**

```bash
mkdir -p scripts/hazards scenes/hazards
git add scenes/hazards/cat.tscn scripts/hazards/cat.gd scenes/player.tscn scripts/main.gd
git commit -m "feat: add cat hazard with wander and lunge AI"
```

---

### Task 5: Shoe Hazard

**Files:**
- Create: `scenes/hazards/shoe.tscn`
- Create: `scripts/hazards/shoe.gd`
- Modify: `scripts/main.gd` — add shoe spawning (starts at 15s elapsed)

- [ ] **Step 1: Create scripts/hazards/shoe.gd**

```gdscript
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
```

- [ ] **Step 2: Create scenes/hazards/shoe.tscn**

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/hazards/shoe.gd" id="1_shoe"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_shoe"]
size = Vector2(40, 20)

[node name="Shoe" type="Area2D"]
collision_layer = 2
collision_mask = 1
script = ExtResource("1_shoe")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_shoe")

[node name="Body" type="Polygon2D" parent="."]
color = Color(0.55, 0.35, 0.2, 1)
polygon = PackedVector2Array(-20, -10, 16, -10, 20, -6, 20, 10, -20, 10)

[node name="Sole" type="Polygon2D" parent="."]
color = Color(0.3, 0.2, 0.1, 1)
polygon = PackedVector2Array(-20, 6, 20, 6, 20, 10, -20, 10)
```

- [ ] **Step 3: Update scripts/main.gd — add shoe spawning**

Replace the full `scripts/main.gd`:

```gdscript
extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var player: CharacterBody2D = $Player

var time_remaining: float = 60.0
var game_active: bool = true

var cat_scene: PackedScene = preload("res://scenes/hazards/cat.tscn")
var shoe_scene: PackedScene = preload("res://scenes/hazards/shoe.tscn")

var cat_spawn_interval: float = 3.0
var cat_spawn_timer: float = 2.0
var shoe_spawn_interval: float = 1.5
var shoe_spawn_timer: float = 0.0

func _ready() -> void:
	hud.update_hp(player.hp)
	hud.update_timer(time_remaining)

func _process(delta: float) -> void:
	if not game_active:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_win()
	hud.update_timer(time_remaining)
	hud.update_hp(player.hp)
	_spawn_hazards(delta)

func _spawn_hazards(delta: float) -> void:
	var elapsed := 60.0 - time_remaining

	# Cats: from the start
	cat_spawn_timer -= delta
	if cat_spawn_timer <= 0.0:
		_spawn_cat()
		cat_spawn_timer = cat_spawn_interval

	# Shoes: after 15s
	if elapsed >= 15.0:
		shoe_spawn_timer -= delta
		if shoe_spawn_timer <= 0.0:
			_spawn_shoe()
			shoe_spawn_timer = shoe_spawn_interval

func _spawn_cat() -> void:
	var cat: Area2D = cat_scene.instantiate()
	cat.position = _random_edge_position()
	cat.setup(player)
	add_child(cat)

func _spawn_shoe() -> void:
	var shoe: Area2D = shoe_scene.instantiate()
	var spawn_pos := _random_edge_position()
	shoe.position = spawn_pos
	# Aim toward the center area with some randomness
	var target := Vector2(randf_range(200, 1080), randf_range(100, 620))
	shoe.setup((target - spawn_pos).normalized())
	add_child(shoe)

func _random_edge_position() -> Vector2:
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf_range(0, 1280), -40)
		1: return Vector2(randf_range(0, 1280), 760)
		2: return Vector2(-40, randf_range(0, 720))
		3: return Vector2(1320, randf_range(0, 720))
	return Vector2(-40, 360)

func _win() -> void:
	game_active = false
	hud.show_win()

func _on_player_died() -> void:
	game_active = false
	hud.show_lose()

func restart() -> void:
	get_tree().reload_current_scene()
```

- [ ] **Step 4: Verify — run the game**

Expected: After 15 seconds, brown shoes start flying in from edges every 1.5 seconds aimed roughly at center. They damage the fish on contact.

- [ ] **Step 5: Commit**

```bash
git add scenes/hazards/shoe.tscn scripts/hazards/shoe.gd scripts/main.gd
git commit -m "feat: add shoe hazard — straight-line projectiles after 15s"
```

---

### Task 6: Furniture Hazard

**Files:**
- Create: `scenes/hazards/furniture.tscn`
- Create: `scripts/hazards/furniture.gd`
- Modify: `scripts/main.gd` — add furniture spawning (starts at 30s elapsed)

- [ ] **Step 1: Create scripts/hazards/furniture.gd**

```gdscript
extends Area2D

const SPEED: float = 80.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	if position.x < -200 or position.x > 1480 or position.y < -200 or position.y > 920:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
```

- [ ] **Step 2: Create scenes/hazards/furniture.tscn**

A large dark rectangle representing a chair or ottoman.

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/hazards/furniture.gd" id="1_furn"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_furn"]
size = Vector2(100, 80)

[node name="Furniture" type="Area2D"]
collision_layer = 2
collision_mask = 1
script = ExtResource("1_furn")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_furn")

[node name="Body" type="ColorRect" parent="."]
offset_left = -50.0
offset_top = -40.0
offset_right = 50.0
offset_bottom = 40.0
color = Color(0.25, 0.18, 0.12, 1)

[node name="Cushion" type="ColorRect" parent="."]
offset_left = -40.0
offset_top = -30.0
offset_right = 40.0
offset_bottom = 30.0
color = Color(0.4, 0.25, 0.15, 1)
```

- [ ] **Step 3: Update scripts/main.gd — add furniture spawning**

Add to the preloads and spawn logic. Full replacement of `scripts/main.gd`:

```gdscript
extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var player: CharacterBody2D = $Player

var time_remaining: float = 60.0
var game_active: bool = true

var cat_scene: PackedScene = preload("res://scenes/hazards/cat.tscn")
var shoe_scene: PackedScene = preload("res://scenes/hazards/shoe.tscn")
var furniture_scene: PackedScene = preload("res://scenes/hazards/furniture.tscn")

var cat_spawn_interval: float = 3.0
var cat_spawn_timer: float = 2.0
var shoe_spawn_interval: float = 1.5
var shoe_spawn_timer: float = 0.0
var furniture_spawn_interval: float = 4.0
var furniture_spawn_timer: float = 0.0

func _ready() -> void:
	hud.update_hp(player.hp)
	hud.update_timer(time_remaining)

func _process(delta: float) -> void:
	if not game_active:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_win()
	hud.update_timer(time_remaining)
	hud.update_hp(player.hp)
	_spawn_hazards(delta)

func _spawn_hazards(delta: float) -> void:
	var elapsed := 60.0 - time_remaining

	cat_spawn_timer -= delta
	if cat_spawn_timer <= 0.0:
		_spawn_cat()
		cat_spawn_timer = cat_spawn_interval

	if elapsed >= 15.0:
		shoe_spawn_timer -= delta
		if shoe_spawn_timer <= 0.0:
			_spawn_shoe()
			shoe_spawn_timer = shoe_spawn_interval

	if elapsed >= 30.0:
		furniture_spawn_timer -= delta
		if furniture_spawn_timer <= 0.0:
			_spawn_furniture()
			furniture_spawn_timer = furniture_spawn_interval

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
	# Furniture slides from one edge to the opposite
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

func _random_edge_position() -> Vector2:
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf_range(0, 1280), -40)
		1: return Vector2(randf_range(0, 1280), 760)
		2: return Vector2(-40, randf_range(0, 720))
		3: return Vector2(1320, randf_range(0, 720))
	return Vector2(-40, 360)

func _win() -> void:
	game_active = false
	hud.show_win()

func _on_player_died() -> void:
	game_active = false
	hud.show_lose()

func restart() -> void:
	get_tree().reload_current_scene()
```

- [ ] **Step 4: Verify — run the game**

Expected: After 30 seconds, large dark furniture pieces slide across the screen every 4 seconds. They're slow but big — hard to dodge.

- [ ] **Step 5: Commit**

```bash
git add scenes/hazards/furniture.tscn scripts/hazards/furniture.gd scripts/main.gd
git commit -m "feat: add furniture hazard — large slow obstacles after 30s"
```

---

### Task 7: Roomba Hazard

**Files:**
- Create: `scenes/hazards/roomba.tscn`
- Create: `scripts/hazards/roomba.gd`
- Modify: `scripts/main.gd` — spawn one Roomba at 45s elapsed

- [ ] **Step 1: Create scripts/hazards/roomba.gd**

```gdscript
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
```

- [ ] **Step 2: Create scenes/hazards/roomba.tscn**

A dark circle with a small green power dot.

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/hazards/roomba.gd" id="1_roomba"]

[sub_resource type="CircleShape2D" id="CircleShape2D_roomba"]
radius = 22.0

[node name="Roomba" type="Area2D"]
collision_layer = 2
collision_mask = 1
script = ExtResource("1_roomba")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_roomba")

[node name="BodyCircle" type="Polygon2D" parent="."]
color = Color(0.2, 0.2, 0.22, 1)
polygon = PackedVector2Array(22, 0, 20, 8, 15, 15, 8, 20, 0, 22, -8, 20, -15, 15, -20, 8, -22, 0, -20, -8, -15, -15, -8, -20, 0, -22, 8, -20, 15, -15, 20, -8)

[node name="PowerDot" type="Polygon2D" parent="."]
color = Color(0.2, 0.9, 0.2, 1)
polygon = PackedVector2Array(4, -8, 6, -6, 4, -4, 2, -6)
```

- [ ] **Step 3: Update scripts/main.gd — add Roomba spawn at 45s**

Full replacement of `scripts/main.gd`:

```gdscript
extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var player: CharacterBody2D = $Player

var time_remaining: float = 60.0
var game_active: bool = true

var cat_scene: PackedScene = preload("res://scenes/hazards/cat.tscn")
var shoe_scene: PackedScene = preload("res://scenes/hazards/shoe.tscn")
var furniture_scene: PackedScene = preload("res://scenes/hazards/furniture.tscn")
var roomba_scene: PackedScene = preload("res://scenes/hazards/roomba.tscn")

var cat_spawn_interval: float = 3.0
var cat_spawn_timer: float = 2.0
var shoe_spawn_interval: float = 1.5
var shoe_spawn_timer: float = 0.0
var furniture_spawn_interval: float = 4.0
var furniture_spawn_timer: float = 0.0
var roomba_spawned: bool = false

func _ready() -> void:
	hud.update_hp(player.hp)
	hud.update_timer(time_remaining)

func _process(delta: float) -> void:
	if not game_active:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_win()
	hud.update_timer(time_remaining)
	hud.update_hp(player.hp)
	_spawn_hazards(delta)

func _spawn_hazards(delta: float) -> void:
	var elapsed := 60.0 - time_remaining

	cat_spawn_timer -= delta
	if cat_spawn_timer <= 0.0:
		_spawn_cat()
		cat_spawn_timer = cat_spawn_interval

	if elapsed >= 15.0:
		shoe_spawn_timer -= delta
		if shoe_spawn_timer <= 0.0:
			_spawn_shoe()
			shoe_spawn_timer = shoe_spawn_interval

	if elapsed >= 30.0:
		furniture_spawn_timer -= delta
		if furniture_spawn_timer <= 0.0:
			_spawn_furniture()
			furniture_spawn_timer = furniture_spawn_interval

	if elapsed >= 45.0 and not roomba_spawned:
		_spawn_roomba()
		roomba_spawned = true

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

func _random_edge_position() -> Vector2:
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf_range(0, 1280), -40)
		1: return Vector2(randf_range(0, 1280), 760)
		2: return Vector2(-40, randf_range(0, 720))
		3: return Vector2(1320, randf_range(0, 720))
	return Vector2(-40, 360)

func _win() -> void:
	game_active = false
	hud.show_win()

func _on_player_died() -> void:
	game_active = false
	hud.show_lose()

func restart() -> void:
	get_tree().reload_current_scene()
```

- [ ] **Step 4: Verify — run the game**

Expected: At 45 seconds elapsed, a dark circle with a green dot appears and relentlessly tracks the goldfish. It never despawns.

- [ ] **Step 5: Commit**

```bash
git add scenes/hazards/roomba.tscn scripts/hazards/roomba.gd scripts/main.gd
git commit -m "feat: add Roomba hazard — player-tracking enemy at 45s"
```

---

### Task 8: Final Polish and Playtest

**Files:**
- Modify: `scripts/main.gd` — increase difficulty over time
- Modify: `scripts/hud.gd` — add floor detail lines

- [ ] **Step 1: Add floor wood-grain lines to main scene**

Add a simple `_draw()` override to a custom node, or add lines in `_ready()`. Simplest approach: update `scripts/main.gd` to draw some lines on the floor.

Add a `FloorLines` script. Create `scripts/floor_lines.gd`:

```gdscript
extends Node2D

func _draw() -> void:
	var line_color := Color(0.75, 0.64, 0.48, 0.4)
	# Horizontal wood plank lines
	for y in range(0, 720, 60):
		draw_line(Vector2(0, y), Vector2(1280, y), line_color, 1.0)
	# Vertical plank offsets (staggered)
	for row in range(0, 12):
		var y_start: float = row * 60.0
		var offset: float = 0.0 if row % 2 == 0 else 160.0
		for x in range(int(offset), 1280, 320):
			draw_line(Vector2(x, y_start), Vector2(x, y_start + 60), line_color, 1.0)
```

- [ ] **Step 2: Update main.tscn to use FloorLines script**

Replace the main.tscn with the FloorLines node scripted:

```ini
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1_main"]
[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="2_player"]
[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="3_hud"]
[ext_resource type="Script" path="res://scripts/floor_lines.gd" id="4_floor"]

[node name="Main" type="Node2D"]
script = ExtResource("1_main")

[node name="Floor" type="ColorRect" parent="."]
offset_right = 1280.0
offset_bottom = 720.0
color = Color(0.82, 0.71, 0.55, 1)

[node name="FloorLines" type="Node2D" parent="."]
script = ExtResource("4_floor")

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(640, 360)

[node name="HUD" parent="." instance=ExtResource("3_hud")]

[connection signal="died" from="Player" to="." method="_on_player_died"]
[connection signal="restart_pressed" from="HUD" to="." method="restart"]
```

- [ ] **Step 3: Ramp up difficulty over time**

Update spawn intervals in `_spawn_hazards` to decrease over time. Edit `scripts/main.gd` — replace the `_spawn_hazards` function:

```gdscript
func _spawn_hazards(delta: float) -> void:
	var elapsed := 60.0 - time_remaining
	# Difficulty ramp: spawn faster as time progresses
	var difficulty: float = 1.0 + elapsed / 30.0  # 1.0 at start, 3.0 at 60s

	cat_spawn_timer -= delta
	if cat_spawn_timer <= 0.0:
		_spawn_cat()
		cat_spawn_timer = cat_spawn_interval / difficulty

	if elapsed >= 15.0:
		shoe_spawn_timer -= delta
		if shoe_spawn_timer <= 0.0:
			_spawn_shoe()
			shoe_spawn_timer = shoe_spawn_interval / difficulty

	if elapsed >= 30.0:
		furniture_spawn_timer -= delta
		if furniture_spawn_timer <= 0.0:
			_spawn_furniture()
			furniture_spawn_timer = furniture_spawn_interval / difficulty

	if elapsed >= 45.0 and not roomba_spawned:
		_spawn_roomba()
		roomba_spawned = true
```

- [ ] **Step 4: Full playtest**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path /Users/vpillai/godot 2>&1`

Verify checklist:
- Fish moves smoothly with WASD/arrows
- Fish stays on screen
- Cats spawn, wander, lunge
- Shoes fly in after 15s
- Furniture slides after 30s
- Roomba tracks at 45s
- Spawn rates increase over time
- Getting hit flashes + screen shakes + reduces HP
- At 0 HP: game over screen with restart
- Surviving 60s: win screen with restart
- Flavor text appears at 45s, 15s, 5s remaining
- Floor has wood-grain lines

- [ ] **Step 5: Commit**

```bash
git add scripts/floor_lines.gd scenes/main.tscn scripts/main.gd
git commit -m "feat: add floor detail, difficulty ramp — game complete"
```
