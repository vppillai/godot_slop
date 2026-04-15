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
