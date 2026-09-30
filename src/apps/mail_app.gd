extends AppBase

## WEXP Mail: message list when online, offline notice otherwise.
## Refreshes itself when the connection state changes (pull-based).

const ROWS := [
	["From: mark_holt@...", "RE: have you heard from kat?", "Sep 30"],
	["From: trailtalk-mod@...", "Thread locked — missing person", "Sep 28"],
	["From: mom@...", "dinner sunday?", "Sep 27"],
]

var _body: Control
var _offline_view := false


func build() -> void:
	NetSim.online_changed.connect(_on_online_changed)
	_rebuild()


func _exit_tree() -> void:
	if NetSim.online_changed.is_connected(_on_online_changed):
		NetSim.online_changed.disconnect(_on_online_changed)


func is_offline_view() -> bool:
	return _offline_view


func _on_online_changed(_online: bool) -> void:
	if is_inside_tree():
		_rebuild()


func _rebuild() -> void:
	if _body:
		_body.queue_free()
	_offline_view = not NetSim.is_online()
	if _offline_view:
		_body = _offline_panel()
	else:
		_body = _list_panel()
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_body)


func _offline_panel() -> Control:
	var mc := _margin(12)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	mc.add_child(vb)
	var head := Label.new()
	head.text = "Not connected"
	head.add_theme_font_override("font", UiTheme.bold())
	head.add_theme_font_size_override("font_size", 15)
	vb.add_child(head)
	var hint := Label.new()
	hint.text = "You are not connected to the Internet.\nOpen the WEXP Browser and dial in to check your mail."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	vb.add_child(hint)
	return mc


func _list_panel() -> Control:
	var mc := _margin(10)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	mc.add_child(vb)
	for row in ROWS:
		var l := Label.new()
		l.text = "%s\n%s          %s" % [row[0], row[1], row[2]]
		l.add_theme_font_size_override("font_size", 12)
		vb.add_child(l)
	return mc


func _margin(m: int) -> MarginContainer:
	var mc := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, m)
	return mc
