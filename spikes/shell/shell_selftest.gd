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

	_mgr.close_window(browser)
	_mgr.close_window(mail)
	await _wait(0.25)
	print("SELFTEST close 2 windows -> ", _mgr.windows().size(), " (expect 1)")
	await _shot("shell_final")

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
