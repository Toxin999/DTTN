extends Control

## Phase 1 selftest: boot screen visuals (mid-progress + completed).

func _ready() -> void:
	add_child(BootScreen.new())
