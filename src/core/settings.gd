extends Node

## Persistent user settings (user://settings.cfg). Autoload: Settings.

signal changed(key: String, value: Variant)

const PATH := "user://settings.cfg"

var timer_enabled := true
var hint_level := 1
var text_speed := 1.0
var user_name := "WEXP User"


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	timer_enabled = cf.get_value("gameplay", "timer_enabled", timer_enabled)
	hint_level = cf.get_value("gameplay", "hint_level", hint_level)
	text_speed = cf.get_value("gameplay", "text_speed", text_speed)
	user_name = cf.get_value("player", "user_name", user_name)


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("gameplay", "timer_enabled", timer_enabled)
	cf.set_value("gameplay", "hint_level", hint_level)
	cf.set_value("gameplay", "text_speed", text_speed)
	cf.set_value("player", "user_name", user_name)
	cf.save(PATH)


func set_value(key: String, value: Variant) -> void:
	set(key, value)
	changed.emit(key, value)
	save_settings()
