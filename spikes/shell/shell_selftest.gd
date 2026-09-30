extends Control

## Phase 1 selftest: scripted desktop session — open apps, drag, taskbar
## toggle, start menu, settings app, close, graceful quit.
## Prints SELFTEST lines with expected values and saves capture PNGs.

const DESKTOP := preload("res://src/shell/desktop.tscn")

var _mgr: WindowManager


func _ready() -> void:
	OS.low_processor_usage_mode = false
	var desktop := DESKTOP.instantiate()
	desktop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(desktop)
	await get_tree().process_frame
	_mgr = desktop.get_node("WindowManager")
	await _run()


func _run() -> void:
	await _wait(0.5)
	await _shot("shell_desktop")

	var browser := _mgr.open_app("browser")
	var mail := _mgr.open_app("mail")
	await _wait(0.3)
	print("SELFTEST open 2 apps -> ", _mgr.windows().size(), " windows (expect 2)")

	var start := Vector2(browser.position) + Vector2(140, 15)
	_press(start)
	await _wait(0.05)
	for i in 4:
		_motion(start + Vector2(30 * (i + 1), 18 * (i + 1)), Vector2(30, 18))
		await _wait(0.05)
	_release(start + Vector2(120, 72))
	await _wait(0.1)
	print("SELFTEST drag browser -> ", browser.position, " (expect (210, 132))")

	# chrome buttons: maximize / restore
	var max_btn := _mgr.chrome_button_center(browser, "max")
	_press(max_btn)
	_release(max_btn)
	await _wait(0.15)
	print("SELFTEST maximize -> size ", browser.size, " pos ", browser.position,
		" (expect (1280, 686) (0, 0))")
	max_btn = _mgr.chrome_button_center(browser, "max")
	_press(max_btn)
	_release(max_btn)
	await _wait(0.15)
	print("SELFTEST restore -> size ", browser.size, " pos ", browser.position,
		" (expect (760, 480) (210, 132))")

	# chrome minimize + restore via taskbar
	var min_btn := _mgr.chrome_button_center(browser, "min")
	_press(min_btn)
	_release(min_btn)
	await _wait(0.15)
	print("SELFTEST chrome minimize -> browser visible ", browser.visible, " (expect false)")
	var browser_btn := _mgr.taskbar_button_center(browser)
	_press(browser_btn)
	_release(browser_btn)
	await _wait(0.15)
	print("SELFTEST taskbar restore browser -> visible ", browser.visible,
		" focused ", browser.has_focus(), " (expect true true)")

	# resize by the grip
	var grip_pos: Vector2 = Vector2(browser.position) + Vector2(browser.size) - Vector2(8, 8)
	_press(grip_pos)
	await _wait(0.05)
	for i in 3:
		_motion(grip_pos + Vector2(20 * (i + 1), 12 * (i + 1)), Vector2(20, 12))
		await _wait(0.05)
	_release(grip_pos + Vector2(60, 36))
	await _wait(0.1)
	print("SELFTEST grip resize -> size ", browser.size, " (expect (820, 516))")

	mail.grab_focus()
	await _wait(0.15)
	print("SELFTEST taskbar pre-click focus -> mail.has_focus ", mail.has_focus(),
		" (fyi; click routing may move focus)")
	var mail_btn := _mgr.taskbar_button_center(mail)
	_press(mail_btn)
	_release(mail_btn)
	await _wait(0.15)
	print("SELFTEST taskbar click (focused) -> mail visible ", mail.visible, " (expect false)")
	_press(mail_btn)
	_release(mail_btn)
	await _wait(0.15)
	print("SELFTEST taskbar click (restore) -> visible ", mail.visible,
		" focused ", mail.has_focus(), " (expect true true)")

	# Escape closes the menu and clears the start button state (F1 regression)
	_mgr.toggle_start_menu()
	await _wait(0.2)
	print("SELFTEST menu via api -> open ", _mgr.start_menu_open(), " (expect true)")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await _wait(0.2)
	print("SELFTEST escape -> menu open ", _mgr.start_menu_open(),
		" start active ", _mgr.start_button_active(), " (expect false false)")

	# desktop click closes the menu
	_mgr.toggle_start_menu()
	await _wait(0.2)
	_press(Vector2(1150, 320))
	_release(Vector2(1150, 320))
	await _wait(0.2)
	print("SELFTEST desktop click -> menu open ", _mgr.start_menu_open(), " (expect false)")

	# taskbar click also closes the menu (F2)
	_mgr.toggle_start_menu()
	await _wait(0.2)
	_press(browser_btn)
	_release(browser_btn)
	await _wait(0.2)
	print("SELFTEST taskbar click closes menu -> open ", _mgr.start_menu_open(),
		" (expect false), browser focused ", browser.has_focus(), " (expect true)")

	var start_btn := _mgr.taskbar_start_center()
	_press(start_btn)
	_release(start_btn)
	await _wait(0.25)
	print("SELFTEST start button -> menu open ", _mgr.start_menu_open(), " (expect true)")
	await _shot("shell_startmenu")

	var item := _mgr.start_menu_item_center("app:settings")
	_press(item)
	await _wait(0.05)
	_release(item)
	await _wait(0.35)
	print("SELFTEST menu item Control Panel -> windows ", _mgr.windows().size(),
		" (expect 3), menu open ", _mgr.start_menu_open(), " (expect false)")
	var settings_win := _mgr.find_window("settings")
	print("SELFTEST settings window -> valid ", settings_win != null,
		" visible ", settings_win.visible if settings_win else false,
		" focused ", settings_win.has_focus() if settings_win else false)
	await _shot("shell_settings")

	# viewport resize clamp (position/size pulled back into the work area)
	browser.position = Vector2i(3000, 3000)
	browser.size = Vector2i(2000, 1500)
	_mgr.handle_viewport_resize()
	await _wait(0.1)
	print("SELFTEST resize clamp -> pos ", browser.position, " size ", browser.size,
		" (expect (1220, 656) (1280, 686))")

	_mgr.close_window(browser)
	_mgr.close_window(mail)
	await _wait(0.25)
	print("SELFTEST close 2 windows -> ", _mgr.windows().size(), " (expect 1)")
	await _shot("shell_final")

	# settings debounced persistence (F4)
	Settings.set_value("text_speed", 1.3)
	await _wait(0.9)
	var cf := ConfigFile.new()
	var err := cf.load("user://settings.cfg")
	print("SELFTEST settings debounce -> file loaded ", err == OK,
		" speed ", cf.get_value("gameplay", "text_speed", -1.0), " (expect true 1.3)")
	Settings.set_value("text_speed", 1.0)  # restore default (exit_tree flushes)

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


func _press(pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = pos
	e.global_position = pos
	Input.parse_input_event(e)


func _release(pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = pos
	e.global_position = pos
	Input.parse_input_event(e)


func _motion(pos: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.relative = rel
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)
