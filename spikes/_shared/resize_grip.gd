extends Control

## Dev-only resize grip for spike windows.

@export var target: Window


func _ready() -> void:
	custom_minimum_size = Vector2(16, 16)
	mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and target and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		var ns: Vector2 = (Vector2(target.size) + event.relative).clamp(Vector2(320, 200), Vector2(2400, 2000))
		target.size = Vector2i(ns)
		accept_event()


func _draw() -> void:
	var c := Color(0.32, 0.32, 0.3, 0.9)
	for i in 3:
		var o := 4.0 + i * 4.0
		draw_line(Vector2(size.x - o, size.y - 2), Vector2(size.x - 2, size.y - o), c, 1.0)
