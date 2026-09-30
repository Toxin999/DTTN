extends AppBase

## CaseBoard: the live list of keywords collected from reading.
## The terminal's crack minigame uses the same store.

var _list: VBoxContainer
var _count: Label


func build() -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)

	var head := Label.new()
	head.text = "Evidence — collected keywords"
	head.add_theme_font_override("font", UiTheme.bold())
	head.add_theme_font_size_override("font_size", 14)
	vb.add_child(head)

	_count = Label.new()
	_count.add_theme_font_size_override("font_size", 11)
	_count.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	vb.add_child(_count)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	var hint := Label.new()
	hint.text = "Use these in the command prompt: crack <target>"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	vb.add_child(hint)

	var mc := margin_container(10)
	mc.add_child(vb)

	Flags.keyword_collected.connect(_on_keyword_collected)
	Flags.flag_changed.connect(_on_flag_changed)
	_rebuild()


func _exit_tree() -> void:
	if Flags.keyword_collected.is_connected(_on_keyword_collected):
		Flags.keyword_collected.disconnect(_on_keyword_collected)
	if Flags.flag_changed.is_connected(_on_flag_changed):
		Flags.flag_changed.disconnect(_on_flag_changed)


func row_count() -> int:
	return _list.get_child_count()


func _on_keyword_collected(_keyword: String) -> void:
	_rebuild()


func _on_flag_changed(_flag: String) -> void:
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	var kws := Flags.keywords()
	_count.text = "%d keyword%s collected" % [kws.size(), "" if kws.size() == 1 else "s"]
	if kws.is_empty():
		var none := Label.new()
		none.text = "Nothing yet. Read pages in the browser — interesting words get filed here automatically."
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.add_theme_font_size_override("font_size", 12)
		none.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		_list.add_child(none)
		return
	for kw in kws:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		var name_label := Label.new()
		name_label.text = str(kw["keyword"])
		name_label.add_theme_font_override("font", UiTheme.bold())
		name_label.add_theme_font_size_override("font_size", 13)
		row.add_child(name_label)
		var src := Label.new()
		src.text = "%s — %s" % [str(kw.get("label", "")), str(kw.get("source", ""))]
		src.add_theme_font_size_override("font_size", 10)
		src.add_theme_color_override("font_color", Color(0.42, 0.42, 0.42))
		row.add_child(src)
		_list.add_child(row)
