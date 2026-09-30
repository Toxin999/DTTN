extends Control

## Phase 0 spike: WEXP (XP-inspired) desktop shell — wallpaper, taskbar,
## borderless embedded windows with custom chrome, drag / resize / z-order.

const LUNA := "res://assets/ui/luna/"
const FONT_REG := "res://assets/fonts/PT_Sans-Web-Regular.ttf"
const FONT_BOLD := "res://assets/fonts/PT_Sans-Web-Bold.ttf"
const FONT_BOLD_ITALIC := "res://assets/fonts/PT_Sans-Web-BoldItalic.ttf"
const FONT_THAI := "res://assets/fonts/Sarabun-Regular.ttf"
const FONT_THAI_BOLD := "res://assets/fonts/Sarabun-Bold.ttf"
const TASKBAR_H := 34

var _tex: Dictionary = {}
var _font: FontFile
var _font_bold: FontFile
var _windows: Array[Window] = []
var _taskbar: Window
var _task_hbox: HBoxContainer
var _clock: Label


func _ready() -> void:
	_load_fonts()
	_load_tex()
	_build_wallpaper()
	_build_taskbar()
	_spawn_window("TrailTalk — WEXP Browser", Vector2(64, 36), Vector2(740, 470), _content_browser)
	_spawn_window("Inbox — WEXP Mail", Vector2(300, 150), Vector2(600, 420), _content_mail)
	_spawn_window("Untitled — Notepad", Vector2(620, 300), Vector2(500, 300), _content_notepad)
	_update_clock()
	_restack_taskbar()
	# self-test: pull the middle window to the front after a beat (z-order check)
	get_tree().create_timer(0.6).timeout.connect(func(): _windows[1].grab_focus())
	# self-test: slide the notepad over the z-test bands + taskbar
	get_tree().create_timer(2.4).timeout.connect(func(): _windows[2].position = Vector2i(360, 560))
	# self-test: synthetic mouse drag + resize on window 0
	get_tree().create_timer(2.8).timeout.connect(_run_input_selftest)


func _inject_button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	Input.parse_input_event(e)


func _inject_motion(pos: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.relative = rel
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)


func _run_input_selftest() -> void:
	var w: Window = _windows[0]
	# drag by the titlebar
	var start: Vector2 = Vector2(w.position) + Vector2(140, 15)
	_inject_button(start, true)
	await get_tree().process_frame
	for i in 4:
		_inject_motion(start + Vector2(30 * (i + 1), 18 * (i + 1)), Vector2(30, 18))
		await get_tree().process_frame
	_inject_button(start + Vector2(120, 72), false)
	await get_tree().process_frame
	print("SELFTEST drag -> position ", w.position, " (expect 184,108)")
	# resize by the grip
	var grip_pos: Vector2 = Vector2(w.position) + Vector2(w.size) - Vector2(8, 8)
	_inject_button(grip_pos, true)
	await get_tree().process_frame
	for i in 4:
		_inject_motion(grip_pos + Vector2(20 * (i + 1), 14 * (i + 1)), Vector2(20, 14))
		await get_tree().process_frame
	_inject_button(grip_pos + Vector2(80, 56), false)
	await get_tree().process_frame
	print("SELFTEST resize -> size ", w.size, " (expect 820,526)")


# ---------------------------------------------------------------- assets

func _load_fonts() -> void:
	var thai: FontFile = load(FONT_THAI)
	var thai_bold: FontFile = load(FONT_THAI_BOLD)
	_font = load(FONT_REG)
	_font.fallbacks = [thai]
	_font_bold = load(FONT_BOLD)
	_font_bold.fallbacks = [thai_bold]


func _load_tex() -> void:
	for n in [
		"wallpaper_hills.png", "taskbar_tile.png",
		"titlebar_active_left.png", "titlebar_active_center.png", "titlebar_active_right.png",
		"titlebar_inactive_left.png", "titlebar_inactive_center.png", "titlebar_inactive_right.png",
		"start_normal.png", "start_hover.png", "start_pressed.png",
		"win_min_normal.png", "win_min_hover.png", "win_min_pressed.png",
		"win_max_normal.png", "win_max_hover.png", "win_max_pressed.png",
		"win_close_normal.png", "win_close_hover.png", "win_close_pressed.png",
	]:
		_tex[n] = load(LUNA + n)


# ---------------------------------------------------------------- chrome

func _build_wallpaper() -> void:
	var bg := TextureRect.new()
	bg.texture = _tex["wallpaper_hills.png"]
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _build_taskbar() -> void:
	_taskbar = Window.new()
	_taskbar.borderless = true
	_taskbar.unfocusable = true
	_taskbar.wrap_controls = false
	_taskbar.name = "Taskbar"
	add_child(_taskbar)

	var vs := get_viewport().get_visible_rect().size
	_taskbar.size = Vector2i(int(vs.x), TASKBAR_H)
	_taskbar.position = Vector2i(0, int(vs.y) - TASKBAR_H)

	var bg := TextureRect.new()
	bg.texture = _tex["taskbar_tile.png"]
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_taskbar.add_child(bg)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left", 2)
	mc.add_theme_constant_override("margin_top", 2)
	mc.add_theme_constant_override("margin_right", 6)
	mc.add_theme_constant_override("margin_bottom", 2)
	_taskbar.add_child(mc)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	mc.add_child(hb)

	var start := TextureButton.new()
	start.texture_normal = _tex["start_normal.png"]
	start.texture_hover = _tex["start_hover.png"]
	start.texture_pressed = _tex["start_pressed.png"]
	start.ignore_texture_size = true
	start.custom_minimum_size = Vector2(100, 30)
	start.focus_mode = Control.FOCUS_NONE
	start.tooltip_text = "WEXP start menu (Phase 1)"
	hb.add_child(start)
	var sl := Label.new()
	sl.text = "start"
	sl.add_theme_font_override("font", load(FONT_BOLD_ITALIC))
	sl.add_theme_font_size_override("font_size", 17)
	sl.add_theme_color_override("font_color", Color(1, 1, 1))
	sl.add_theme_color_override("font_shadow_color", Color(0.05, 0.25, 0.02, 0.9))
	sl.add_theme_constant_override("shadow_offset_x", 1)
	sl.add_theme_constant_override("shadow_offset_y", 1)
	sl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start.add_child(sl)

	_task_hbox = HBoxContainer.new()
	_task_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_task_hbox.add_theme_constant_override("separation", 4)
	hb.add_child(_task_hbox)

	_clock = Label.new()
	_clock.add_theme_font_override("font", _font)
	_clock.add_theme_font_size_override("font_size", 13)
	_clock.add_theme_color_override("font_color", Color(0.92, 0.96, 1))
	_clock.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	_clock.add_theme_constant_override("shadow_offset_x", 1)
	_clock.add_theme_constant_override("shadow_offset_y", 1)
	_clock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(_clock)

	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_update_clock)
	add_child(t)


func _update_clock() -> void:
	var d := Time.get_datetime_dict_from_system()
	var hour := int(d["hour"])
	var ampm := "AM" if hour < 12 else "PM"
	hour = hour % 12
	if hour == 0:
		hour = 12
	_clock.text = "%d:%02d %s" % [hour, d["minute"], ampm]


func _spawn_window(title: String, pos: Vector2, size: Vector2, content: Callable) -> Window:
	var w := Window.new()
	w.name = title.get_slice(" ", 0)
	w.borderless = true
	w.unresizable = false
	w.wrap_controls = false
	w.min_size = Vector2(320, 200)
	w.size = Vector2i(size)
	w.position = Vector2i(pos)
	w.add_theme_stylebox_override("embedded_border", StyleBoxEmpty.new())
	add_child(w)
	_windows.append(w)
	w.set_meta("win_title", title)
	_build_chrome(w)
	content.call(w.get_meta("client"))
	_add_task_button(w)
	w.focus_entered.connect(func():
		_apply_active(w, true)
		_restack_taskbar()
		_refresh_task(w))
	w.focus_exited.connect(func():
		w.set_meta("dragging", false)
		_apply_active(w, false)
		_refresh_task(w))
	return w


func _build_chrome(w: Window) -> void:
	var frame := VBoxContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("separation", 0)
	w.add_child(frame)

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 30)
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	frame.add_child(bar)

	var center := TextureRect.new()
	center.texture = _tex["titlebar_active_center.png"]
	center.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	center.stretch_mode = TextureRect.STRETCH_SCALE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 29
	center.offset_right = -29
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(center)

	var cap_l := TextureRect.new()
	cap_l.texture = _tex["titlebar_active_left.png"]
	cap_l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cap_l.stretch_mode = TextureRect.STRETCH_SCALE
	cap_l.size = Vector2(30, 30)
	cap_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(cap_l)

	var cap_r := TextureRect.new()
	cap_r.texture = _tex["titlebar_active_right.png"]
	cap_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cap_r.stretch_mode = TextureRect.STRETCH_SCALE
	cap_r.anchor_left = 1.0
	cap_r.anchor_right = 1.0
	cap_r.offset_left = -30.0
	cap_r.offset_bottom = 30.0
	cap_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(cap_r)

	var lbl := Label.new()
	lbl.text = w.get_meta("win_title")
	lbl.add_theme_font_override("font", _font_bold)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.anchor_bottom = 1.0
	lbl.anchor_right = 1.0
	lbl.offset_left = 34.0
	lbl.offset_right = -74.0
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(lbl)

	var btn_mc := MarginContainer.new()
	btn_mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_mc.add_theme_constant_override("margin_top", 5)
	btn_mc.add_theme_constant_override("margin_right", 4)
	btn_mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(btn_mc)
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

	b_min.pressed.connect(func():
		w.visible = false
		w.set_meta("dragging", false)
		_refresh_task(w)
		_focus_top_visible())
	b_max.pressed.connect(func(): _toggle_max(w))
	b_close.pressed.connect(func(): _close_window(w))

	bar.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				w.set_meta("dragging", true)
				w.grab_focus()
			else:
				w.set_meta("dragging", false)
		elif e is InputEventMouseMotion and w.get_meta("dragging", false):
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				w.set_meta("dragging", false)
				return
			if w.get_meta("maximized", false):
				return
			var vis := get_viewport().get_visible_rect().size
			var np: Vector2 = Vector2(w.position) + e.relative
			np.x = clampf(np.x, -w.size.x + 90.0, vis.x - 60.0)
			np.y = clampf(np.y, 0.0, vis.y - TASKBAR_H - 30.0)
			w.position = Vector2i(np))

	var client := PanelContainer.new()
	client.name = "Client"
	client.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.925, 0.91, 0.847)
	sb.border_color = Color(0.13, 0.32, 0.69)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	client.add_theme_stylebox_override("panel", sb)
	frame.add_child(client)

	var grip := Control.new()
	grip.set_script(load("res://spikes/_shared/resize_grip.gd"))
	grip.target = w
	grip.anchor_left = 1.0
	grip.anchor_top = 1.0
	grip.anchor_right = 1.0
	grip.anchor_bottom = 1.0
	grip.offset_left = -16.0
	grip.offset_top = -16.0
	w.add_child(grip)

	w.set_meta("bar_center", center)
	w.set_meta("bar_left", cap_l)
	w.set_meta("bar_right", cap_r)
	w.set_meta("bar_label", lbl)
	w.set_meta("client", client)


func _win_button(glyph: String) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = _tex["win_%s_normal.png" % glyph]
	b.texture_hover = _tex["win_%s_hover.png" % glyph]
	b.texture_pressed = _tex["win_%s_pressed.png" % glyph]
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP
	b.custom_minimum_size = Vector2(21, 21)
	b.focus_mode = Control.FOCUS_NONE
	return b


func _apply_active(w: Window, active: bool) -> void:
	var state := "active" if active else "inactive"
	w.get_meta("bar_center").texture = _tex["titlebar_%s_center.png" % state]
	w.get_meta("bar_left").texture = _tex["titlebar_%s_left.png" % state]
	w.get_meta("bar_right").texture = _tex["titlebar_%s_right.png" % state]
	var lbl: Label = w.get_meta("bar_label")
	lbl.add_theme_color_override("font_color", Color(1, 1, 1) if active else Color(0.88, 0.91, 0.98))


func _restack_taskbar() -> void:
	if _taskbar and _taskbar.get_index() != get_child_count() - 1:
		move_child(_taskbar, -1)


func _toggle_max(w: Window) -> void:
	var vis := get_viewport().get_visible_rect().size
	if w.get_meta("maximized", false):
		w.position = w.get_meta("saved_pos")
		w.size = w.get_meta("saved_size")
		w.set_meta("maximized", false)
	else:
		w.set_meta("saved_pos", w.position)
		w.set_meta("saved_size", w.size)
		w.position = Vector2i.ZERO
		w.size = Vector2i(int(vis.x), int(vis.y) - TASKBAR_H)
		w.set_meta("maximized", true)


func _close_window(w: Window) -> void:
	var tb: Button = w.get_meta("task_button", null)
	if tb:
		tb.queue_free()
	_windows.erase(w)
	w.queue_free()
	_focus_top_visible()


func _focus_top_visible() -> void:
	for i in range(_windows.size() - 1, -1, -1):
		var w: Window = _windows[i]
		if is_instance_valid(w) and w.visible:
			w.grab_focus()
			return


# ---------------------------------------------------------------- taskbar

func _add_task_button(w: Window) -> void:
	var tb := Button.new()
	tb.text = w.get_meta("win_title")
	tb.toggle_mode = true
	tb.focus_mode = Control.FOCUS_NONE
	tb.clip_text = true
	tb.custom_minimum_size = Vector2(150, 28)
	tb.add_theme_font_override("font", _font)
	tb.add_theme_font_size_override("font_size", 12)
	tb.add_theme_color_override("font_color", Color(1, 1, 1))
	tb.add_theme_color_override("font_disabled_color", Color(0.8, 0.85, 0.95))
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.24, 0.42, 0.78)
	sb_normal.corner_radius_top_left = 3
	sb_normal.corner_radius_top_right = 3
	sb_normal.corner_radius_bottom_left = 3
	sb_normal.corner_radius_bottom_right = 3
	sb_normal.content_margin_left = 8
	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = Color(0.3, 0.5, 0.86)
	var sb_pressed := sb_normal.duplicate()
	sb_pressed.bg_color = Color(0.12, 0.24, 0.52)
	tb.add_theme_stylebox_override("normal", sb_normal)
	tb.add_theme_stylebox_override("hover", sb_hover)
	tb.add_theme_stylebox_override("pressed", sb_pressed)
	tb.add_theme_stylebox_override("focus", sb_pressed)
	tb.pressed.connect(func():
		if w.visible:
			w.grab_focus()
		else:
			w.visible = true
			w.grab_focus()
		_restack_taskbar())
	w.set_meta("task_button", tb)
	_task_hbox.add_child(tb)


func _refresh_task(w: Window) -> void:
	var tb: Button = w.get_meta("task_button", null)
	if tb:
		tb.button_pressed = w.visible and w.has_focus()


# ---------------------------------------------------------------- content

func _fill_content(client: Control, node: Control) -> void:
	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 6)
	client.add_child(mc)
	mc.add_child(node)


func _content_browser(client: Control) -> void:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.add_theme_font_override("normal_font", _font)
	rt.add_theme_font_override("bold_font", _font_bold)
	rt.add_theme_font_size_override("normal_font_size", 13)
	rt.add_theme_font_size_override("bold_font_size", 13)
	rt.add_theme_color_override("default_color", Color(0.1, 0.1, 0.1))
	rt.text = "[b]TrailTalk › Trip Reports › Cascade Ridge day hike — Sat 9/14[/b]\n[color=#666666]posted by river_kat on 09-02-2002 3:41 PM[/color]\n\nAnyone up for Cascade Ridge next Saturday? Meet at the trailhead lot at 7 AM, I'll bring the map and extra water. Post here if you're coming — we can carpool from the Safeway on 3rd.\n\n[b]Re: Cascade Ridge day hike — Sat 9/14[/b]\n[color=#666666]sundance_77 on 09-05-2002 11:02 PM[/color]\nI'm in. Bringing my new digicam so we better get some good light up there.\n\n[b]Re: Cascade Ridge day hike — Sat 9/14[/b]\n[color=#666666]river_kat on 09-13-2002 6:20 PM[/color]\nWeather looks clear. See everyone at the lot, 7 sharp. Don't wait up!"
	_fill_content(client, rt)


func _content_mail(client: Control) -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_fill_content(client, vb)
	for row in [
		["From: mark_holt@...", "Subject: RE: have you heard from kat?", "Sep 30"],
		["From: trailtalk-mod@...", "Subject: Thread locked — missing person", "Sep 28"],
		["From: mom@...", "Subject: dinner sunday?", "Sep 27"],
	]:
		var l := Label.new()
		l.text = "%s\n%s          %s" % [row[0], row[1], row[2]]
		l.add_theme_font_override("font", _font)
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
		vb.add_child(l)


func _content_notepad(client: Control) -> void:
	var l := Label.new()
	l.text = "Cascade Ridge notes\n\n- 9/14 meet 7:00 AM, trailhead lot\n- kat drives a blue Civic\n- sundance_77 brought digicam\n\nหมายเหตุ: นัดเจอกันที่ล็อตจอดรถ 7 โมงเช้า อย่าลืมแผนที่\nโพสต์ล่าสุดของนกคือวันที่ 13 กันยา เวลา 18:20 น."
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fill_content(client, l)
