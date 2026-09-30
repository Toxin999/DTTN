class_name StartMenu
extends Window

## Overlay window (subwindows draw above app windows; the manager stacks it
## above the taskbar while open).
## Close intents use Window's built-in close_requested signal.

signal item_chosen(action: String)

const MENU_W := 340
const MENU_H := 396

var _items: Dictionary = {}  # action -> Button


func setup(win_theme: Theme) -> void:
	theme = win_theme
	borderless = true
	wrap_controls = false
	unfocusable = false
	name = "StartMenu"
	size = Vector2i(MENU_W, MENU_H)
	visible = false
	_build()


func open_menu(view_size: Vector2, user_name: String) -> void:
	position = Vector2i(0, int(view_size.y) - Taskbar.BAR_H - MENU_H)
	visible = true
	grab_focus()
	var panel: Control = get_meta("panel")
	if panel:
		panel.grab_focus()
	_set_user_name(user_name)


func close_menu() -> void:
	visible = false


func is_open() -> bool:
	return visible


func item_center(action: String) -> Vector2:
	var b: Button = _items.get(action)
	if not b:
		return Vector2.ZERO
	return Vector2(position) + b.get_global_rect().get_center()


func _on_panel_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _set_user_name(user_name: String) -> void:
	var lbl: Label = get_meta("user_label")
	if lbl:
		lbl.text = user_name


func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.focus_mode = Control.FOCUS_ALL
	panel.gui_input.connect(_on_panel_input)
	set_meta("panel", panel)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1)
	sb.border_color = Color(0.09, 0.24, 0.59)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	panel.add_child(vb)

	var header := PanelContainer.new()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0.11, 0.33, 0.71)
	hsb.corner_radius_top_left = 8
	hsb.corner_radius_top_right = 8
	hsb.content_margin_left = 10
	hsb.content_margin_top = 8
	hsb.content_margin_bottom = 8
	header.add_theme_stylebox_override("panel", hsb)
	vb.add_child(header)
	var user_label := Label.new()
	user_label.text = "WEXP User"
	user_label.add_theme_font_override("font", UiTheme.bold())
	user_label.add_theme_font_size_override("font_size", 15)
	user_label.add_theme_color_override("font_color", Color(1, 1, 1))
	user_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	user_label.add_theme_constant_override("shadow_offset_x", 1)
	user_label.add_theme_constant_override("shadow_offset_y", 1)
	header.add_child(user_label)
	set_meta("user_label", user_label)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 0)
	vb.add_child(cols)

	var left_wrap := MarginContainer.new()
	left_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_wrap.add_theme_constant_override("margin_left", 4)
	left_wrap.add_theme_constant_override("margin_top", 6)
	left_wrap.add_theme_constant_override("margin_bottom", 6)
	cols.add_child(left_wrap)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left_wrap.add_child(left)
	_item(left, "app:browser", "TrailTalk Browser")
	_item(left, "app:mail", "WEXP Mail")
	_item(left, "app:terminal", "Command Prompt")
	_item(left, "app:caseboard", "CaseBoard")
	_item(left, "app:settings", "Control Panel")

	var right_wrap := PanelContainer.new()
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = Color(0.84, 0.88, 0.96)
	rsb.content_margin_left = 4
	rsb.content_margin_right = 4
	rsb.content_margin_top = 6
	rsb.content_margin_bottom = 6
	right_wrap.add_theme_stylebox_override("panel", rsb)
	cols.add_child(right_wrap)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(150, 0)
	right.add_theme_constant_override("separation", 2)
	right_wrap.add_child(right)
	_item(right, "places:documents", "My Documents", false)
	_item(right, "app:settings_short", "Settings")
	_item(right, "places:help", "Help and Support", false)

	var bottom := PanelContainer.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.84, 0.88, 0.96)
	bsb.content_margin_left = 8
	bsb.content_margin_right = 8
	bsb.content_margin_top = 6
	bsb.content_margin_bottom = 6
	bottom.add_theme_stylebox_override("panel", bsb)
	vb.add_child(bottom)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_child(brow)
	_item(brow, "quit", "Turn Off Computer")


func _item(parent: Control, action: String, text: String, enabled := true) -> void:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not enabled
	b.custom_minimum_size = Vector2(0, 30)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.55))
	var empty := StyleBoxFlat.new()
	empty.bg_color = Color(0, 0, 0, 0)
	empty.content_margin_left = 10
	empty.content_margin_right = 10
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.20, 0.44, 0.86)
	hover.set_corner_radius_all(2)
	hover.content_margin_left = 10
	hover.content_margin_right = 10
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("disabled", empty)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", empty)
	if enabled:
		b.pressed.connect(func(): item_chosen.emit(action))
	_items[action] = b
	parent.add_child(b)
