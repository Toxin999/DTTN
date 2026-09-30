extends Control

## Phase 2c selftest: terminal commands, crack minigame (keyword dictionary,
## timer toggle, lockout cooldown, hints), CaseBoard live list, gated payoff.

const DESKTOP := preload("res://src/shell/desktop.tscn")

var _mgr: WindowManager


func _ready() -> void:
	OS.low_processor_usage_mode = false
	Flags.reset()
	NetSim.set_online(true)
	var desktop := DESKTOP.instantiate()
	desktop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(desktop)
	await get_tree().process_frame
	_mgr = desktop.get_node("WindowManager")
	await _run()


func _run() -> void:
	await _wait(0.4)

	# collect keywords the honest way: read pages
	var browser := _mgr.open_app("browser")
	var bapp: AppBase = _mgr.find_app("browser")
	await _wait(0.8)
	bapp.navigate("site://katpage/about")
	await _wait(0.7)
	bapp.navigate("cache://katpage/oldguestbook")
	await _wait(0.7)
	print("SELFTEST keywords collected -> ", Flags.keywords().size(), " (expect 4)")

	# terminal basics
	var term_win := _mgr.open_app("terminal")
	var term: AppBase = _mgr.find_app("terminal")
	await _wait(0.3)
	term.run_command("help")
	print("SELFTEST help -> ", term.output_text().contains("CRACK"), " (expect true)")
	term.run_command("nonsense")
	print("SELFTEST bad command -> ", term.output_text().contains("Bad command"), " (expect true)")
	term.run_command("type notes.txt")
	print("SELFTEST type file -> ", term.output_text().contains("blue civic"), " (expect true)")

	# crack with a wrong keyword, then the right one
	term.run_command("crack katpage")
	await _wait(0.3)
	var crack: CrackPanel = term.crack_panel()
	print("SELFTEST crack mode -> ", term.is_crack_mode(), " (expect true)")
	crack.submit_keyword("maple grove")
	await _wait(0.2)
	print("SELFTEST wrong keyword -> failed in log ", crack.log_text().contains("FAILED"), " (expect true)")
	print("SELFTEST info -> ", crack.attempts_left_label(), " (contains wrong attempts: 1)")
	crack.submit_keyword("cascade ridge")
	await _wait(0.2)
	print("SELFTEST right keyword -> granted ", crack.log_text().contains("ACCESS GRANTED"), " (expect true)")
	print("SELFTEST flag -> ", Flags.has("cracked:katpage"), " (expect true)")
	await _shot("crack_panel")

	# timer toggle follows Settings
	print("SELFTEST timer active -> ", crack.timer_active(), " (expect false, was resolved)")
	term.run_command("crack guestbook")
	await _wait(0.3)
	print("SELFTEST timer on -> ", crack.timer_active(), " (expect true)")
	Settings.set_value("timer_enabled", false)
	print("SELFTEST timer off via settings -> ", crack.timer_active(), " (expect false)")
	Settings.set_value("timer_enabled", true)

	# lockout after 3 wrong attempts, then cooldown expiry (2 in-game min)
	crack.submit_manual("nope1")
	crack.submit_manual("nope2")
	crack.submit_manual("nope3")
	await _wait(0.2)
	print("SELFTEST lockout -> ", crack.is_locked(), " (expect true)")
	crack.submit_keyword("third base")
	print("SELFTEST locked blocks try -> granted ", crack.log_text().contains("ACCESS GRANTED"),
		" (expect false)")
	print("SELFTEST hint shown -> ", crack.hint_text().length() > 0, " (expect true)")
	await _wait(2.4)  # lockout_minutes=2, 1 game minute per real second
	print("SELFTEST cooldown expired -> ", crack.is_locked(), " (expect false)")
	crack.submit_keyword("third base")
	await _wait(0.2)
	print("SELFTEST after cooldown -> granted ", crack.log_text().contains("ACCESS GRANTED"),
		" (expect true)")

	# caseboard lists the collected keywords live
	var board_win := _mgr.open_app("caseboard")
	var board: AppBase = _mgr.find_app("caseboard")
	await _wait(0.3)
	print("SELFTEST caseboard rows -> ", board.row_count(), " vs keywords ",
		Flags.keywords().size(), " (expect equal)")
	await _shot("caseboard")

	# gated payoff page opens after the crack
	bapp.navigate("site://katpage/secrets")
	await _wait(0.7)
	print("SELFTEST secrets page -> status ", bapp.status_text(),
		" (expect site://katpage/secrets)")
	await _shot("secrets_page")

	print("SELFTEST quit -> graceful shutdown")
	_mgr.quit_game()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(shot_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://spikes/out/%s.png" % shot_name)
	print("CAPTURED ", shot_name)
