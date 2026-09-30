class_name BootScreen
extends Control

## WEXP boot sequence. Draws logo + segmented progress bar, skippable
## with any key/click after a short grace period.

signal finished

const DURATION := 2.6
const SKIP_AFTER := 0.4

var _elapsed := 0.0
var _done := false
var _bar: ProgressBar


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	_bar.value = clampf(_elapsed / DURATION, 0.0, 1.0) * 100.0
	if _elapsed >= DURATION:
		_finish()


func _input(event: InputEvent) -> void:
	if _done or _elapsed < SKIP_AFTER:
		return
	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		pressed = event.pressed
	if pressed:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	finished.emit()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 10)
	add_child(center)

	var logo := Label.new()
	logo.text = "WEXP"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_override("font", UiTheme.bold())
	logo.add_theme_font_size_override("font_size", 64)
	logo.add_theme_color_override("font_color", Color(0.92, 0.95, 1))
	logo.add_theme_color_override("font_shadow_color", Color(0.25, 0.45, 0.9, 0.6))
	logo.add_theme_constant_override("shadow_offset_x", 2)
	logo.add_theme_constant_override("shadow_offset_y", 2)
	center.add_child(logo)

	var sub := Label.new()
	sub.text = "Professional"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
	center.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 26)
	center.add_child(spacer)

	var bar_wrap := CenterContainer.new()
	center.add_child(bar_wrap)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(260, 16)
	_bar.value = 0
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.06, 0.08, 0.12)
	bg_sb.set_border_width_all(1)
	bg_sb.border_color = Color(0.35, 0.45, 0.62)
	bg_sb.set_corner_radius_all(3)
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.23, 0.45, 0.85)
	fill_sb.set_corner_radius_all(2)
	_bar.add_theme_stylebox_override("background", bg_sb)
	_bar.add_theme_stylebox_override("fill", fill_sb)
	bar_wrap.add_child(_bar)

	var hint := Label.new()
	hint.text = "Press any key to skip"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
	var hint_mc := MarginContainer.new()
	hint_mc.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint_mc.add_theme_constant_override("margin_bottom", 28)
	hint_mc.add_child(hint)
	add_child(hint_mc)
