extends AppBase

## WEXP Command Prompt. A handful of diegetic commands plus the password
## crack minigame (`crack <target>`), which is a dictionary attack over the
## keywords the player has collected from reading.

const TARGETS_PATH := "res://content/en/crack/targets.json"

const FILES := {
	"notes.txt": "cascade ridge trip:\n- meet 7:00 am, trailhead lot\n- bring map + water\n- kat drives the blue civic\n",
	"trail.htm": "<html><body><h1>Cascade Ridge</h1><p>Trail 7, 4.2 miles round trip. Parking lot open May-Oct.</p></body></html>\n",
	"readme.txt": "WEXP command prompt — type HELP for commands.\n",
}

var _out: RichTextLabel
var _input: LineEdit
var _crack: CrackPanel
var _targets: Dictionary = {}


func build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.07)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 10)
	add_child(mc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	mc.add_child(vb)

	_out = RichTextLabel.new()
	_out.bbcode_enabled = true
	_out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_out.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_out.add_theme_color_override("default_color", Color(0.82, 0.86, 0.82))
	_out.add_theme_font_size_override("normal_font_size", 12)
	vb.add_child(_out)

	_input = LineEdit.new()
	_input.placeholder_text = "command"
	_input.text_submitted.connect(func(text: String): run_command(text))
	vb.add_child(_input)

	_crack = CrackPanel.new()
	_crack.build()
	_crack.resolved.connect(_on_crack_resolved)
	add_child(_crack)

	_load_targets()
	_print_banner()
	_input.grab_focus()


func _print_banner() -> void:
	_out.append_text("[color=#8fd08f]WEXP Command Prompt[/color]  [color=#888888](C:\\WEXP)[/color]\n")
	_out.append_text("Type HELP for a list of commands.\n\n")


func _load_targets() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TARGETS_PATH))
	if parsed is Dictionary:
		_targets = parsed
	else:
		push_error("terminal: bad crack target file " + TARGETS_PATH)


# ---------------------------------------------------------------- api

func run_command(line: String) -> void:
	var text := line.strip_edges()
	if text.is_empty():
		return
	_out.append_text("[color=#8fd08f]C:\\>[/color] " + text + "\n")
	var parts := text.split(" ", false)
	var cmd := parts[0].to_lower()
	var arg := " ".join(parts.slice(1)) if parts.size() > 1 else ""
	match cmd:
		"help":
			_cmd_help()
		"dir":
			_cmd_dir()
		"type":
			_cmd_type(arg)
		"crack":
			_cmd_crack(arg)
		"clear":
			_out.text = ""
		"exit":
			if window:
				manager.close_window(window)
		_:
			_out.append_text("[color=#e08080]Bad command or file name[/color]\n\n")
	_input.text = ""
	_input.grab_focus()


func output_text() -> String:
	return _out.get_parsed_text()


func crack_panel() -> CrackPanel:
	return _crack


func is_crack_mode() -> bool:
	return _crack.is_active()


# ---------------------------------------------------------------- commands

func _cmd_help() -> void:
	_out.append_text("""DIR            list files in the current directory
TYPE <file>    print a file
CRACK <target> start a password crack against a known target
CLEAR          clear the screen
EXIT           close the window

Targets: %s
""" % ", ".join(_targets.keys()) + "\n")


func _cmd_dir() -> void:
	_out.append_text("[color=#888888] Volume in drive C is WEXP2000[/color]\n")
	for file_name in FILES.keys():
		_out.append_text(" %-12s %6d  09-28-2002\n" % [file_name.to_upper(), FILES[file_name].length()])
	_out.append_text("\n")


func _cmd_type(arg: String) -> void:
	if FILES.has(arg):
		_out.append_text(FILES[arg] + "\n")
	else:
		_out.append_text("[color=#e08080]File not found[/color]\n\n")


func _cmd_crack(arg: String) -> void:
	if arg.is_empty() or not _targets.has(arg):
		_out.append_text("[color=#e08080]Usage: CRACK <target>[/color] (targets: %s)\n\n" \
			% ", ".join(_targets.keys()))
		return
	if Flags.has("cracked:" + arg):
		_out.append_text("Target '%s' is already cracked.\n\n" % arg)
		return
	_out.append_text("Starting dictionary attack on '%s'...\n\n" % arg)
	_crack.start(arg, _targets[arg])


func _on_crack_resolved(target_id: String, success: bool) -> void:
	_out.append_text(("Target '%s' [color=#7fe07f]cracked[/color].\n\n" % target_id) if success \
		else ("Target '%s' locked — wait for the cooldown.\n\n" % target_id))
