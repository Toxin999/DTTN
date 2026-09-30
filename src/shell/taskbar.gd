class_name Taskbar
extends Window

## Always-on-top overlay window. Must be an embedded Window: subwindows draw
## above every CanvasLayer, so a plain Control cannot cover app windows.

signal start_pressed
signal window_button_pressed(win: WexpWindow)

const BAR_H := 34

var _task_hbox: HBoxContainer
var _clock: Label
var _start: TextureButton
var _buttons: Dictionary = {}
var _start_active := false


func setup(win_theme: Theme) -> void:
	theme = win_theme
	borderless = true
	unfocusable = true
	wrap_controls = false
	name = "Taskbar"
	_build()


func reposition(view_size: Vector2) -> void:
	size = Vector2i(int(view_size.x), BAR_H)
	position = Vector2i(0, int(view_size.y) - BAR_H)


func set_clock(text: String) -> void:
	_clock.text = text


func set_start_active(active: bool) -> void:
	_start_active = active
	_start.texture_normal = _tex("start_%s.png" % ("pressed" if active else "normal"))


func start_is_active() -> bool:
	return _start_active


## Called for mouse presses on the bar (see InputGuard) — used by the manager
## to pull focus back to an exclusive dialog.
func set_press_hook(callback: Callable) -> void:
	var guard := InputGuard.new()
	guard.on_press = callback
	add_child(guard)


func add_window_button(win: WexpWindow) -> void:
	var tb := Button.new()
	tb.text = win.display_title
	tb.toggle_mode = true
	tb.focus_mode = Control.FOCUS_NONE
	tb.clip_text = true
	tb.custom_minimum_size = Vector2(160, 28)
	tb.add_theme_font_size_override("font_size", 12)
	tb.add_theme_color_override("font_color", Color(1, 1, 1))
	tb.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	tb.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	var sb_normal := _task_style(Color(0.24, 0.42, 0.78))
	var sb_hover := _task_style(Color(0.30, 0.50, 0.86))
	var sb_pressed := _task_style(Color(0.12, 0.24, 0.52))
	tb.add_theme_stylebox_override("normal", sb_normal)
	tb.add_theme_stylebox_override("hover", sb_hover)
	tb.add_theme_stylebox_override("pressed", sb_pressed)
	tb.add_theme_stylebox_override("focus", sb_hover)
	tb.pressed.connect(func(): window_button_pressed.emit(win))
	_buttons[win] = tb
	_task_hbox.add_child(tb)


func remove_window_button(win: WexpWindow) -> void:
	var tb: Button = _buttons.get(win)
	if tb:
		tb.queue_free()
	_buttons.erase(win)


func sync_button(win: WexpWindow) -> void:
	var tb: Button = _buttons.get(win)
	if tb:
		tb.text = win.display_title
		tb.button_pressed = win.visible and win.is_active()


func button_center(win: WexpWindow) -> Vector2:
	var tb: Button = _buttons.get(win)
	if not tb:
		return Vector2.ZERO
	return Vector2(position) + tb.get_global_rect().get_center()


func start_center() -> Vector2:
	return Vector2(position) + _start.get_global_rect().get_center()


static func _tex(tex_name: String) -> Texture2D:
	return load("res://assets/ui/luna/" + tex_name)


func _task_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	return sb


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = _tex("taskbar_tile.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left", 2)
	mc.add_theme_constant_override("margin_top", 2)
	mc.add_theme_constant_override("margin_right", 6)
	mc.add_theme_constant_override("margin_bottom", 2)
	add_child(mc)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	mc.add_child(hb)

	_start = TextureButton.new()
	_start.texture_normal = _tex("start_normal.png")
	_start.texture_hover = _tex("start_hover.png")
	_start.texture_pressed = _tex("start_pressed.png")
	_start.ignore_texture_size = true
	_start.custom_minimum_size = Vector2(100, 30)
	_start.focus_mode = Control.FOCUS_NONE
	_start.pressed.connect(func(): start_pressed.emit())
	hb.add_child(_start)

	var sl := Label.new()
	sl.text = "start"
	sl.add_theme_font_override("font", load("res://assets/fonts/PT_Sans-Web-BoldItalic.ttf"))
	sl.add_theme_font_size_override("font_size", 17)
	sl.add_theme_color_override("font_color", Color(1, 1, 1))
	sl.add_theme_color_override("font_shadow_color", Color(0.05, 0.25, 0.02, 0.9))
	sl.add_theme_constant_override("shadow_offset_x", 1)
	sl.add_theme_constant_override("shadow_offset_y", 1)
	sl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_start.add_child(sl)

	_task_hbox = HBoxContainer.new()
	_task_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_task_hbox.add_theme_constant_override("separation", 4)
	hb.add_child(_task_hbox)

	_clock = Label.new()
	_clock.add_theme_font_size_override("font_size", 13)
	_clock.add_theme_color_override("font_color", Color(0.92, 0.96, 1))
	_clock.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	_clock.add_theme_constant_override("shadow_offset_x", 1)
	_clock.add_theme_constant_override("shadow_offset_y", 1)
	_clock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(_clock)
