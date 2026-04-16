# Floating text — rises, fades, and scales up over 1.2s then self-destructs.
# Used for hit reactions ("YIKES!"), pickups ("PHEW!", "ZOOM!"), near-miss ("CLOSE!"),
# and hazard announcements ("NOT THE ROOMBA!").
#
# Usage: create a Node2D, set_script to this, set .text and .color, add to tree.
# The tween starts automatically in _ready().

extends Node2D

var text: String = ""
var color: Color = Color.YELLOW

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 60.0, 1.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.2)
	tween.parallel().tween_property(self, "scale", Vector2(1.3, 1.3), 1.2)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	# 300px wide centered text box to fit long messages like "NOT THE ROOMBA!"
	draw_string_outline(font, Vector2(-150, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 300, 22, 4, Color.BLACK)
	draw_string(font, Vector2(-150, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 300, 22, color)
