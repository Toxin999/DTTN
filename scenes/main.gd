extends Control

## Entry point: play the WEXP boot sequence, then load the desktop shell.

const DESKTOP := "res://src/shell/desktop.tscn"


func _ready() -> void:
	var boot := BootScreen.new()
	add_child(boot)
	boot.finished.connect(func(): get_tree().change_scene_to_file(DESKTOP))
