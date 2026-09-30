class_name DialupModal
extends Window

## Dial-up connection modal. Auto-connects after DURATION; the player can
## cancel at any time (the browser then shows an offline error page).
## Like every embedded Window, borderless/size must be set BEFORE add_child.

signal finished(connected: bool)

const DURATION := 2.8

var _bar: ProgressBar
var _status: Label
var _elapsed := 0.0
var _done := false


func setup() -> void:
	borderless = true
	unresizable = true
	size = Vector2i(430, 158)


func _ready() -> void:
	_build()


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	_bar.value = clampf(_elapsed / DURATION, 0.0, 1.0) * 100.0
	var stage := int(_elapsed / (DURATION / 3.0))
	match stage:
		0:
			_status.text = "Dialing 555-0142..."
		1:
			_status.text = "Connecting at 56.6 Kbps..."
		_:
			_status.text = "Verifying user name and password..."
	if _elapsed >= DURATION:
		_finish(true)


func cancel() -> void:
	_finish(false)


func is_done() -> bool:
	return _done


func _finish(connected: bool) -> void:
	if _done:
		return
	_done = true
	set_process(false)
	finished.emit(connected)
	close_requested.emit()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.925, 0.91, 0.847)
	sb.border_color = Color(0.09, 0.24, 0.59)
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	var mc := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 14)
	mc.add_child(vb)
	panel.add_child(mc)

	var title := Label.new()
	title.text = "Connect to WEXP Internet"
	title.add_theme_font_override("font", UiTheme.bold())
	title.add_theme_font_size_override("font_size", 14)
	vb.add_child(title)

	_status = Label.new()
	_status.text = "Dialing 555-0142..."
	_status.add_theme_font_size_override("font_size", 12)
	vb.add_child(_status)

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 14)
	_bar.value = 0
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.87, 0.86, 0.8)
	bg_sb.set_border_width_all(1)
	bg_sb.border_color = Color(0.45, 0.44, 0.37)
	bg_sb.set_corner_radius_all(2)
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.23, 0.45, 0.85)
	fill_sb.set_corner_radius_all(2)
	_bar.add_theme_stylebox_override("background", bg_sb)
	_bar.add_theme_stylebox_override("fill", fill_sb)
	vb.add_child(_bar)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.pressed.connect(cancel)
	row.add_child(cancel_btn)
	vb.add_child(row)
