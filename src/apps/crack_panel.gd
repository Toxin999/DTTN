class_name CrackPanel
extends Control

## Dictionary-attack minigame: pick a collected keyword (or type an attempt)
## to break a target. Optional per-attempt timer (Settings.timer_enabled),
## lockout cooldown in in-game minutes, hints after repeated failures.

signal resolved(target_id: String, success: bool)

const TIMER_SECONDS := 12.0

var _target_id := ""
var _target: Dictionary = {}
var _active := false
var _locked_until_minute := 0
var _wrong_streak := 0
var _time_left := 0.0

var _info: Label
var _timer_bar: ProgressBar
var _keywords_box: HBoxContainer
var _manual: LineEdit
var _log: RichTextLabel
var _hint: Label


func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.07)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 12)
	add_child(mc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	mc.add_child(vb)

	var title := Label.new()
	title.text = "PASSWORD CRACK — dictionary attack"
	title.add_theme_font_override("font", UiTheme.bold())
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
	vb.add_child(title)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 12)
	_info.add_theme_color_override("font_color", Color(0.8, 0.85, 0.8))
	vb.add_child(_info)

	_timer_bar = ProgressBar.new()
	_timer_bar.show_percentage = false
	_timer_bar.custom_minimum_size = Vector2(0, 10)
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.12, 0.14, 0.12)
	bg_sb.set_border_width_all(1)
	bg_sb.border_color = Color(0.35, 0.45, 0.35)
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.4, 0.8, 0.4)
	_timer_bar.add_theme_stylebox_override("background", bg_sb)
	_timer_bar.add_theme_stylebox_override("fill", fill_sb)
	vb.add_child(_timer_bar)

	var kw_label := Label.new()
	kw_label.text = "Keyword list (collected from your reading):"
	kw_label.add_theme_font_size_override("font_size", 11)
	kw_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.7))
	vb.add_child(kw_label)

	var flow := MarginContainer.new()
	vb.add_child(flow)
	_keywords_box = HBoxContainer.new()
	_keywords_box.add_theme_constant_override("separation", 6)
	flow.add_child(_keywords_box)

	var manual_row := HBoxContainer.new()
	manual_row.add_theme_constant_override("separation", 6)
	_manual = LineEdit.new()
	_manual.placeholder_text = "type a password guess"
	_manual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_manual.text_submitted.connect(func(text: String): submit_manual(text))
	manual_row.add_child(_manual)
	var try_btn := Button.new()
	try_btn.text = "Try"
	try_btn.focus_mode = Control.FOCUS_NONE
	try_btn.pressed.connect(func(): submit_manual(_manual.text))
	manual_row.add_child(try_btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "Close"
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.pressed.connect(func():
		_active = false
		visible = false)
	manual_row.add_child(cancel_btn)
	vb.add_child(manual_row)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_color_override("default_color", Color(0.85, 0.9, 0.85))
	_log.add_theme_font_size_override("normal_font_size", 12)
	vb.add_child(_log)

	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	vb.add_child(_hint)

	visible = false


func start(target_id: String, target: Dictionary) -> void:
	_target_id = target_id
	_target = target
	_active = true
	_log.text = ""
	_hint.text = ""
	_manual.text = ""
	visible = true
	_refresh_keywords()
	_refresh_info()
	if not is_locked() and Settings.timer_enabled:
		_time_left = TIMER_SECONDS


func submit_keyword(keyword: String) -> void:
	_try(keyword, "keyword '%s'" % keyword)


func submit_manual(text: String) -> void:
	var clean := text.strip_edges()
	if clean.is_empty():
		return
	_try(clean, "manual '%s'" % clean)


func is_active() -> bool:
	return _active


func target_id() -> String:
	return _target_id


func is_locked() -> bool:
	return WorldClock.minutes_total() < _locked_until_minute


func attempts_left_label() -> String:
	return _info.text


func log_text() -> String:
	return _log.get_parsed_text()


func hint_text() -> String:
	return _hint.text


func timer_active() -> bool:
	return _active and Settings.timer_enabled and not is_locked()


func _process(delta: float) -> void:
	if not timer_active():
		return
	_time_left -= delta
	_timer_bar.value = clampf(_time_left / TIMER_SECONDS, 0.0, 1.0) * 100.0
	if _time_left <= 0.0:
		_fail("the session timed out")


func _try(attempt: String, label: String) -> void:
	if not _active:
		return
	if is_locked():
		_log.append_text("[color=#e08080]Target is locked. Try again in %d min.[/color]\n" \
			% (_locked_until_minute - WorldClock.minutes_total()))
		return
	if _matches(attempt):
		_succeed(label)
		return
	_fail("no match for " + label)


func _matches(attempt: String) -> bool:
	var a := attempt.to_lower().replace(" ", "")
	if str(_target.get("answer_keyword", "")).to_lower().replace(" ", "") == a:
		return true
	for accepted in _target.get("accepted", []):
		if str(accepted).to_lower().replace(" ", "") == a:
			return true
	return false


func _succeed(label: String) -> void:
	_active = false
	_timer_bar.value = 0
	_log.append_text("[color=#7fe07f]ACCESS GRANTED[/color] — matched %s\n" % label)
	_log.append_text(str(_target.get("reward", "")) + "\n")
	Flags.set_flag("cracked:" + _target_id)
	resolved.emit(_target_id, true)


func _fail(reason: String) -> void:
	_wrong_streak += 1
	_log.append_text("[color=#e08080]FAILED[/color] — %s\n" % reason)
	if Settings.timer_enabled:
		_time_left = TIMER_SECONDS
	var hints: Array = _target.get("hints", [])
	var hint_index := int(floor(_wrong_streak / 3.0)) - 1
	if hint_index >= 0 and hint_index < hints.size():
		_hint.text = "hint: " + str(hints[hint_index])
	if _wrong_streak % 3 == 0:
		_locked_until_minute = WorldClock.minutes_total() + int(_target.get("lockout_minutes", 5))
		_log.append_text("[color=#e0c060]Locked out for %d min (in-game).[/color]\n" \
			% int(_target.get("lockout_minutes", 5)))
		resolved.emit(_target_id, false)
	_refresh_info()


func _refresh_info() -> void:
	_info.text = "target: %s   |   wrong attempts: %d   |   %s" % [
		str(_target.get("label", _target_id)),
		_wrong_streak,
		"LOCKED (%d min)" % (_locked_until_minute - WorldClock.minutes_total()) if is_locked() else "ready",
	]


func _refresh_keywords() -> void:
	for child in _keywords_box.get_children():
		child.queue_free()
	var kws := Flags.keywords()
	if kws.is_empty():
		var none := Label.new()
		none.text = "(nothing collected yet — go read something)"
		none.add_theme_font_size_override("font_size", 11)
		none.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_keywords_box.add_child(none)
		return
	for kw in kws:
		var b := Button.new()
		b.text = str(kw["keyword"])
		b.tooltip_text = str(kw.get("label", ""))
		b.focus_mode = Control.FOCUS_NONE
		var word := str(kw["keyword"])
		b.pressed.connect(func(): submit_keyword(word))
		_keywords_box.add_child(b)
