extends AppBase

## Control Panel: gameplay settings, persisted via the Settings autoload.

func build() -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)

	var timer_check := CheckBox.new()
	timer_check.text = "Minigame timer"
	timer_check.button_pressed = Settings.timer_enabled
	timer_check.toggled.connect(func(on: bool): Settings.set_value("timer_enabled", on))
	vb.add_child(timer_check)

	var hint_opt := OptionButton.new()
	hint_opt.add_item("Low")
	hint_opt.add_item("Normal")
	hint_opt.add_item("High")
	hint_opt.add_item("Max")
	hint_opt.selected = clampi(Settings.hint_level, 0, 3)
	hint_opt.item_selected.connect(func(i: int): Settings.set_value("hint_level", i))
	vb.add_child(_row("Hint level", hint_opt))

	var speed := HSlider.new()
	speed.min_value = 0.5
	speed.max_value = 2.0
	speed.step = 0.1
	speed.custom_minimum_size = Vector2(160, 0)
	speed.value = Settings.text_speed
	speed.value_changed.connect(func(v: float): Settings.set_value("text_speed", v))
	vb.add_child(_row("Text speed", speed))

	var note := Label.new()
	note.text = "Saved automatically to user://settings.cfg"
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color(0.42, 0.42, 0.42))
	vb.add_child(note)

	var mc := margin_container(14)
	mc.add_child(vb)


func _row(label_text: String, field: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(110, 0)
	row.add_child(l)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(field)
	return row
