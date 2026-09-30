extends Node

## Dev-only helper: waits, saves a screenshot of the root viewport, quits.

@export var shot_name := "shot"
@export var wait_seconds := 0.8
@export var quit_after := true


func _ready() -> void:
	# low processor mode skips redraws when idle — screenshots would hang.
	OS.low_processor_usage_mode = false
	await get_tree().create_timer(wait_seconds).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "res://spikes/out/%s.png" % shot_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://spikes/out"))
	var err := img.save_png(path)
	if err != OK:
		push_error("capture failed: %s" % err)
	else:
		print("CAPTURED ", ProjectSettings.globalize_path(path))
	if quit_after:
		get_tree().quit()
