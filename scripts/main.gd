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
	var difficulty: float = 1.0 + elapsed / 30.0

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
