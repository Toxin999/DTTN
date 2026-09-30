class_name InputGuard
extends Control

## Sits inside an overlay Window (taskbar/desktop) and forwards mouse presses
## to a callback. Node._input only fires for nodes inside the viewport that
## receives the event, so root-level nodes cannot observe clicks on overlays.

var on_press: Callable


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and on_press.is_valid():
		on_press.call()
