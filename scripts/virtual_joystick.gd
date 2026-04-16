# VirtualJoystick — on-screen touch joystick for mobile input.
#
# Starts hidden. main.gd shows it on game start if touchscreen is available.
# Can be swapped between left and right sides for left/right-hand players
# via swap_side(). Positioned via anchors so it adapts to any screen size.
#
# Input flow:
#   _gui_input receives InputEventScreenTouch/Drag -> updates _knob_pos
#   player.gd polls get_direction() every physics frame

extends Control

const OUTER_RADIUS: float = 80.0
const INNER_RADIUS: float = 30.0
const JOYSTICK_SIZE: float = 180.0  # Width/height of the control
const MARGIN: float = 20.0         # Distance from screen edges

var _touching: bool = false
var _touch_index: int = -1
var _knob_pos: Vector2 = Vector2.ZERO  # Normalized direction (-1..1 per axis)
var _on_right_side: bool = false       # false = left side (default)

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(JOYSTICK_SIZE, JOYSTICK_SIZE)
	_apply_side()

## Returns the normalized direction the player is pushing, or Vector2.ZERO if idle.
func get_direction() -> Vector2:
	if not _touching:
		return Vector2.ZERO
	if _knob_pos.length() > 0.1:
		return _knob_pos.normalized()
	return Vector2.ZERO

## Toggles the joystick between left and right sides of the screen.
func swap_side() -> void:
	_on_right_side = not _on_right_side
	_apply_side()

func _apply_side() -> void:
	if _on_right_side:
		# Bottom-right: anchor to bottom-right corner
		anchor_left = 1.0
		anchor_right = 1.0
		anchor_top = 1.0
		anchor_bottom = 1.0
		offset_left = -JOYSTICK_SIZE - MARGIN
		offset_top = -JOYSTICK_SIZE - MARGIN
		offset_right = -MARGIN
		offset_bottom = -MARGIN
	else:
		# Bottom-left: anchor to bottom-left corner
		anchor_left = 0.0
		anchor_right = 0.0
		anchor_top = 1.0
		anchor_bottom = 1.0
		offset_left = MARGIN
		offset_top = -JOYSTICK_SIZE - MARGIN
		offset_right = JOYSTICK_SIZE + MARGIN
		offset_bottom = -MARGIN

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touching = true
			_touch_index = event.index
			_update_knob(event.position)
		elif event.index == _touch_index:
			_touching = false
			_touch_index = -1
			_knob_pos = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_knob(event.position)

func _update_knob(touch_pos: Vector2) -> void:
	var center := size / 2.0
	var offset := touch_pos - center
	if offset.length() > OUTER_RADIUS:
		offset = offset.normalized() * OUTER_RADIUS
	_knob_pos = offset / OUTER_RADIUS
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var center := size / 2.0
	# Outer ring
	_draw_ring(center, OUTER_RADIUS, Color(1, 1, 1, 0.15))
	# Inner knob (follows touch)
	var knob_draw_pos := center + _knob_pos * OUTER_RADIUS
	_draw_filled_circle(knob_draw_pos, INNER_RADIUS, Color(1, 1, 1, 0.3))

func _draw_ring(center: Vector2, radius: float, col: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := i * TAU / 32.0
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))
	for i in range(32):
		draw_line(points[i], points[(i + 1) % 32], col, 2.0)

func _draw_filled_circle(center: Vector2, radius: float, col: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := i * TAU / 24.0
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))
	draw_colored_polygon(points, col)
