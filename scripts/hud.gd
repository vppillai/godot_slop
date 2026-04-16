# HUD — manages all UI overlays: title screen, timer with pulse effects,
# heart display, wave announcements, damage flash, end panels, fade
# transitions, portrait-mode warning, and joystick hand-swap button.
# All elements live on a CanvasLayer for screen-space rendering.

extends CanvasLayer

signal restart_pressed

@onready var timer_label: Label = $TimerLabel
@onready var flavor_label: Label = $FlavorLabel
@onready var end_panel: Panel = $EndPanel
@onready var end_title: Label = $EndPanel/Title
@onready var end_subtitle: Label = $EndPanel/Subtitle
@onready var restart_button: Button = $EndPanel/RestartButton
@onready var heart_display: Node2D = $HeartDisplay
@onready var title_overlay: ColorRect = $TitleOverlay
@onready var game_title: Label = $TitleOverlay/GameTitle
@onready var start_prompt: Label = $TitleOverlay/StartPrompt
@onready var instructions_label: Label = $TitleOverlay/Instructions
@onready var wave_label: Label = $WaveLabel
@onready var damage_flash: ColorRect = $DamageFlash
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var portrait_warning: ColorRect = $PortraitWarning
@onready var swap_hand_button: Button = $SwapHandButton
@onready var virtual_joystick: Control = $VirtualJoystick

var _timer_base_size: int = 36
var _prompt_time: float = 0.0  # Drives start prompt alpha pulse
var _is_touch_device: bool = false

func _ready() -> void:
	_is_touch_device = DisplayServer.is_touchscreen_available()
	end_panel.visible = false
	end_panel.scale = Vector2(0.5, 0.5)
	flavor_label.text = ""
	restart_button.pressed.connect(_on_restart_pressed)
	wave_label.text = ""
	wave_label.modulate.a = 0.0
	damage_flash.color = Color(1, 0, 0, 0)
	# Scene always fades in from black on load
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_from_black()
	# Portrait warning starts hidden (checked every frame)
	portrait_warning.visible = false
	# Swap hand button — only visible on touch devices, starts hidden
	swap_hand_button.visible = false
	swap_hand_button.pressed.connect(_on_swap_hand_pressed)
	# Adapt UI for input method
	if _is_touch_device:
		start_prompt.text = "Tap to start"
		instructions_label.text = "Use joystick to move | Survive 60 seconds"
	else:
		start_prompt.text = "Press any key to start"
		instructions_label.text = "WASD / Arrow keys to move | Survive 60 seconds"

func _process(delta: float) -> void:
	# Pulse start prompt alpha on title screen
	if title_overlay.visible:
		_prompt_time += delta
		start_prompt.modulate.a = 0.5 + sin(_prompt_time * 3.0) * 0.5
	# Portrait orientation detection — use window size since it reflects
	# the actual device orientation (viewport may be letterboxed)
	if _is_touch_device:
		var win_size := DisplayServer.window_get_size()
		var is_portrait := win_size.x < win_size.y
		portrait_warning.visible = is_portrait


# =============================================================================
# Timer display
# =============================================================================

func update_timer(time_remaining: float) -> void:
	var seconds := maxi(ceili(time_remaining), 0)
	timer_label.text = str(seconds)

	if seconds <= 5:
		# Urgent: oscillate size (30-42pt), color (white<->red), and jitter position
		flavor_label.text = "THE BUS IS HERE!"
		flavor_label.modulate = Color(1, 0.2, 0.2)
		var t := Time.get_ticks_msec() / 1000.0
		var pulse_size := int(36.0 + sin(t * 8.0) * 6.0)
		timer_label.add_theme_font_size_override("font_size", pulse_size)
		timer_label.add_theme_color_override("font_color", Color(1, 1, 1).lerp(Color(1, 0.2, 0.2), (sin(t * 8.0) + 1.0) / 2.0))
		# Jitter uses offset_* (not position) because TimerLabel has anchor_left=0.5
		var jx := randf_range(-2, 2)
		var jy := randf_range(-2, 2)
		timer_label.offset_left = -60 + jx
		timer_label.offset_right = 60 + jx
		timer_label.offset_top = 8 + jy
		timer_label.offset_bottom = 58 + jy
	elif seconds <= 10:
		# Tense: oscillate size (32-40pt) and color, no jitter
		flavor_label.text = "THE BUS IS HERE!"
		flavor_label.modulate = Color(1, 0.2, 0.2)
		var t := Time.get_ticks_msec() / 1000.0
		var pulse_size := int(36.0 + sin(t * 6.0) * 4.0)
		timer_label.add_theme_font_size_override("font_size", pulse_size)
		timer_label.add_theme_color_override("font_color", Color(1, 1, 1).lerp(Color(1, 0.2, 0.2), (sin(t * 6.0) + 1.0) / 2.0))
		_reset_timer_offsets()
	elif seconds <= 15:
		flavor_label.text = "ALMOST!"
		flavor_label.modulate = Color(1, 0.5, 0.1)
		_reset_timer_style()
	elif seconds <= 45:
		flavor_label.text = "HANG IN THERE!"
		flavor_label.modulate = Color(1, 0.8, 0.2)
		_reset_timer_style()
	else:
		flavor_label.text = ""
		_reset_timer_style()

func _reset_timer_style() -> void:
	timer_label.add_theme_font_size_override("font_size", 36)
	timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_reset_timer_offsets()

## Restores TimerLabel offsets to match the values in hud.tscn.
func _reset_timer_offsets() -> void:
	timer_label.offset_left = -60
	timer_label.offset_right = 60
	timer_label.offset_top = 8
	timer_label.offset_bottom = 58


# =============================================================================
# Health
# =============================================================================

func update_hp(hp: int) -> void:
	heart_display.update_hp(hp)


# =============================================================================
# Title screen
# =============================================================================

func show_title() -> void:
	title_overlay.visible = true

func hide_title() -> void:
	var tween := create_tween()
	tween.tween_property(title_overlay, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): title_overlay.visible = false)


# =============================================================================
# Joystick hand swap — moves joystick + button between left and right sides
# =============================================================================

## Shows the swap button (called from main.gd when gameplay starts on touch).
func show_swap_button() -> void:
	if _is_touch_device:
		swap_hand_button.visible = true
		_update_swap_button_position()

func _on_swap_hand_pressed() -> void:
	virtual_joystick.swap_side()
	_update_swap_button_position()

## Keeps the swap button positioned above the joystick on whichever side it's on.
func _update_swap_button_position() -> void:
	if virtual_joystick._on_right_side:
		# Right side: button above joystick, right-aligned
		swap_hand_button.anchor_left = 1.0
		swap_hand_button.anchor_right = 1.0
		swap_hand_button.anchor_top = 1.0
		swap_hand_button.anchor_bottom = 1.0
		swap_hand_button.offset_left = -170.0
		swap_hand_button.offset_right = -50.0
		swap_hand_button.offset_top = -230.0
		swap_hand_button.offset_bottom = -205.0
	else:
		# Left side: button above joystick, left-aligned
		swap_hand_button.anchor_left = 0.0
		swap_hand_button.anchor_right = 0.0
		swap_hand_button.anchor_top = 1.0
		swap_hand_button.anchor_bottom = 1.0
		swap_hand_button.offset_left = 50.0
		swap_hand_button.offset_right = 170.0
		swap_hand_button.offset_top = -230.0
		swap_hand_button.offset_bottom = -205.0


# =============================================================================
# Wave announcements — centered text that fades in, holds, fades out
# =============================================================================

func show_wave_announcement(text: String, color: Color) -> void:
	wave_label.text = text
	wave_label.add_theme_color_override("font_color", color)
	var tween := create_tween()
	tween.tween_property(wave_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.5)
	tween.tween_property(wave_label, "modulate:a", 0.0, 0.5)


# =============================================================================
# Damage flash — full-screen red overlay that fades quickly
# =============================================================================

func flash_damage() -> void:
	damage_flash.color = Color(1, 0, 0, 0.35)
	var tween := create_tween()
	tween.tween_property(damage_flash, "color:a", 0.0, 0.25)


# =============================================================================
# End screens
# =============================================================================

func show_win(survival_time: float) -> void:
	end_panel.visible = true
	end_title.text = "YOU SURVIVED!"
	end_subtitle.text = "The kid scooped you back into the bowl!"
	end_panel.modulate = Color(0.5, 1.0, 0.5)
	_animate_end_panel()

func show_lose(survival_time: float) -> void:
	end_panel.visible = true
	end_title.text = "GAME OVER"
	end_subtitle.text = "Survived %.1f seconds\nYou became a cat snack." % survival_time
	end_panel.modulate = Color(1.0, 0.5, 0.5)
	_animate_end_panel()

## Pop-in animation: scales from 0.5 to 1.0 with overshoot bounce.
func _animate_end_panel() -> void:
	end_panel.scale = Vector2(0.5, 0.5)
	end_panel.pivot_offset = end_panel.size / 2.0
	var tween := create_tween()
	tween.tween_property(end_panel, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


# =============================================================================
# Fade transitions
# =============================================================================

## Fades screen to black, then calls the optional callback (e.g. scene reload).
func fade_to_black(callback: Callable = Callable()) -> void:
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
	if callback.is_valid():
		tween.tween_callback(callback)

func fade_from_black() -> void:
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.5)

func _on_restart_pressed() -> void:
	restart_pressed.emit()
