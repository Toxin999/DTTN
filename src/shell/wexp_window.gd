class_name WexpWindow
extends Window

## Borderless embedded window with hand-drawn WEXP (XP-style) chrome.
## Policy (focus stack, taskbar, maximize geometry) lives in WindowManager;
## this class emits intents and owns only its own chrome interactions.
## Close uses Window's built-in close_requested signal.

signal minimize_requested
signal maximize_requested
## Title changes use Window's built-in title_changed signal.

const TITLE_H := 30
const CAP_W := 30

static var _cache: Dictionary = {}

var app_id := ""
var display_title := ""
## The AppBase instance shown inside this window (null for plain windows).
var app: AppBase

var _bar: Control
var _cap_c: TextureRect
var _cap_l: TextureRect
var _cap_r: TextureRect
var _label: Label
var _client: PanelContainer
var _blocker: ColorRect
var _active := true


static func _tex(tex_name: String) -> Texture2D:
	if not _cache.has(tex_name):
		_cache[tex_name] = load("res://assets/ui/luna/" + tex_name)
	return _cache[tex_name]


func setup(p_app_id: String, title: String, win_size: Vector2i, win_pos: Vector2i) -> void:
	app_id = p_app_id
	display_title = title
	name = "Win_" + p_app_id
	borderless = true
	unresizable = false
	wrap_controls = false
	min_size = Vector2i(320, 200)
	size = win_size
	position = win_pos
	add_theme_stylebox_override("embedded_border", StyleBoxEmpty.new())


func content_parent() -> Control:
	return _client


func is_active() -> bool:
	return _active


## Modal input guard: dims the window and swallows mouse input while a
## dialog is open (Window.exclusive does not block embedded subwindows).
func set_input_blocked(blocked: bool) -> void:
	if not _blocker:
		return
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP if blocked else Control.MOUSE_FILTER_IGNORE
	_blocker.color = Color(0, 0, 0, 0.18) if blocked else Color(0, 0, 0, 0)


func button_center(glyph: String) -> Vector2:
	var btn: TextureButton = get_meta("btn_" + glyph, null)
	if btn == null:
		return Vector2.ZERO
	return Vector2(position) + btn.get_global_rect().get_center()


func set_active(active: bool) -> void:
	_active = active
	var state := "active" if active else "inactive"
	_cap_c.texture = _tex("titlebar_%s_center.png" % state)
	_cap_l.texture = _tex("titlebar_%s_left.png" % state)
	_cap_r.texture = _tex("titlebar_%s_right.png" % state)
	_label.add_theme_color_override("font_color",
		Color(1, 1, 1) if active else Color(0.88, 0.91, 0.98))


func update_title(title: String) -> void:
	display_title = title
	if _label:
		_label.text = title
	title_changed.emit()


func _ready() -> void:
	_build_chrome()


func _host_size() -> Vector2:
	var p := get_parent()
	if p:
		var vp := p.get_viewport()
		if vp:
			return vp.get_visible_rect().size
	return get_tree().root.get_visible_rect().size


func _build_chrome() -> void:
	var frame := VBoxContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("separation", 0)
	add_child(frame)

	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(0, TITLE_H)
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	frame.add_child(_bar)

	_cap_c = TextureRect.new()
	_cap_c.texture = _tex("titlebar_active_center.png")
	_cap_c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cap_c.stretch_mode = TextureRect.STRETCH_SCALE
	_cap_c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cap_c.offset_left = CAP_W - 1
	_cap_c.offset_right = -(CAP_W - 1)
	_cap_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_cap_c)

	_cap_l = TextureRect.new()
	_cap_l.texture = _tex("titlebar_active_left.png")
	_cap_l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cap_l.stretch_mode = TextureRect.STRETCH_SCALE
	_cap_l.size = Vector2(CAP_W, TITLE_H)
	_cap_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_cap_l)

	_cap_r = TextureRect.new()
	_cap_r.texture = _tex("titlebar_active_right.png")
	_cap_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cap_r.stretch_mode = TextureRect.STRETCH_SCALE
	_cap_r.anchor_left = 1.0
	_cap_r.anchor_right = 1.0
	_cap_r.offset_left = -CAP_W
	_cap_r.offset_bottom = TITLE_H
	_cap_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_cap_r)

	_label = Label.new()
	_label.text = display_title
	_label.add_theme_font_override("font", UiTheme.bold())
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.anchor_bottom = 1.0
	_label.anchor_right = 1.0
	_label.offset_left = CAP_W + 4
	_label.offset_right = -(CAP_W + 44)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_label)

	var btn_mc := MarginContainer.new()
	btn_mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_mc.add_theme_constant_override("margin_top", 5)
	btn_mc.add_theme_constant_override("margin_right", 4)
	btn_mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(btn_mc)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_END
	btns.add_theme_constant_override("separation", 2)
	btns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_mc.add_child(btns)

	var b_min := _win_button("min")
	var b_max := _win_button("max")
	var b_close := _win_button("close")
	btns.add_child(b_min)
	btns.add_child(b_max)
	btns.add_child(b_close)
	b_min.pressed.connect(func(): minimize_requested.emit())
	b_max.pressed.connect(func(): maximize_requested.emit())
	b_close.pressed.connect(func(): close_requested.emit())
	set_meta("btn_min", b_min)
	set_meta("btn_max", b_max)
	set_meta("btn_close", b_close)

	_bar.gui_input.connect(_on_bar_input)

	_client = PanelContainer.new()
	_client.name = "Client"
	_client.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_client.add_theme_stylebox_override("panel", UiTheme.client_style())
	frame.add_child(_client)

	var grip := Control.new()
	grip.set_script(load("res://src/shell/resize_grip.gd"))
	grip.target = self
	grip.anchor_left = 1.0
	grip.anchor_top = 1.0
	grip.anchor_right = 1.0
	grip.anchor_bottom = 1.0
	grip.offset_left = -16.0
	grip.offset_top = -16.0
	add_child(grip)

	_blocker = ColorRect.new()
	_blocker.color = Color(0, 0, 0, 0)
	_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_blocker)

	set_active(_active)


func _win_button(glyph: String) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = _tex("win_%s_normal.png" % glyph)
	b.texture_hover = _tex("win_%s_hover.png" % glyph)
	b.texture_pressed = _tex("win_%s_pressed.png" % glyph)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP
	b.custom_minimum_size = Vector2(21, 21)
	b.focus_mode = Control.FOCUS_NONE
	return b


func _on_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			set_meta("dragging", true)
			grab_focus()
		else:
			set_meta("dragging", false)
	elif event is InputEventMouseMotion and get_meta("dragging", false):
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			set_meta("dragging", false)
			return
		if get_meta("maximized", false):
			return
		var vis := _host_size()
		var np: Vector2 = Vector2(position) + event.relative
		np.x = clampf(np.x, -size.x + 90.0, vis.x - 60.0)
		np.y = clampf(np.y, 0.0, vis.y - Taskbar.BAR_H - TITLE_H)
		position = Vector2i(np)
