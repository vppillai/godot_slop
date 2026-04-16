# Roomba hazard — relentlessly chases the player. Speed 120.
# Rotates to face movement direction. Spawned at 45s/50s/55s.
# Never despawns on its own (unlike other hazards) — stopped only by game end.
#
# All visuals drawn in _draw() — shadow -> body circle -> power dot -> spinning brush.
# The brush line rotates using real time (Time.get_ticks_msec) for visual flair.

extends Area2D

const SPEED: float = 120.0

var player_ref: CharacterBody2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

## Called by main.gd. Stores reference to the player for chase targeting.
func setup(player: CharacterBody2D) -> void:
	player_ref = player

func _physics_process(delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var dir := (player_ref.position - position).normalized()
	position += dir * SPEED * delta
	rotation = dir.angle()
	queue_redraw()  # Needed every frame for spinning brush animation

func _draw() -> void:
	# Shadow (y=26 peeks below body circle radius 22)
	_draw_ellipse(Vector2(2, 26), 20.0, 8.0, Color(0, 0, 0, 0.15))

	# Body circle (16-sided polygon approximating radius 22)
	var body_pts := PackedVector2Array([
		Vector2(22, 0), Vector2(20, 8), Vector2(15, 15), Vector2(8, 20),
		Vector2(0, 22), Vector2(-8, 20), Vector2(-15, 15), Vector2(-20, 8),
		Vector2(-22, 0), Vector2(-20, -8), Vector2(-15, -15), Vector2(-8, -20),
		Vector2(0, -22), Vector2(8, -20), Vector2(15, -15), Vector2(20, -8)
	])
	draw_colored_polygon(body_pts, Color(0.2, 0.2, 0.22))

	# Green power indicator dot
	var power_pts := PackedVector2Array([
		Vector2(4, -8), Vector2(6, -6), Vector2(4, -4), Vector2(2, -6)
	])
	draw_colored_polygon(power_pts, Color(0.2, 0.9, 0.2))

	# Spinning brush (line across body center, rotates over time)
	var t := Time.get_ticks_msec() / 1000.0
	var spin_angle := fmod(t * 8.0, TAU)
	var brush_start := Vector2(cos(spin_angle) * 14.0, sin(spin_angle) * 14.0)
	var brush_end := Vector2(cos(spin_angle + PI) * 14.0, sin(spin_angle + PI) * 14.0)
	draw_line(brush_start, brush_end, Color(0.6, 0.6, 0.65, 0.6), 2.0)

func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, col)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
