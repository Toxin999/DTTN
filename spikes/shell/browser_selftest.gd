extends Control

## Phase 2a selftest: dial-up gating, navigation/history, keyword collection,
## closing mid-load, cancel path, offline navigation.

const DESKTOP := preload("res://src/shell/desktop.tscn")

var _mgr: WindowManager


func _ready() -> void:
	OS.low_processor_usage_mode = false
	Flags.reset()
	NetSim.set_online(false)
	var desktop := DESKTOP.instantiate()
	desktop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(desktop)
	await get_tree().process_frame
	_mgr = desktop.get_node("WindowManager")
	await _run()


func _run() -> void:
	await _wait(0.4)
	var browser_win := _mgr.open_app("browser")
	var app: AppBase = _mgr.find_app("browser")
	await _wait(0.3)
	print("SELFTEST dialup modal -> count ", _mgr.dialog_count(), " (expect 1)")
	await _shot("browser_dialup")


	await _wait(3.2)
	print("SELFTEST online after dial -> ", NetSim.is_online(), " (expect true)")
	await _wait(0.7)
	print("SELFTEST home -> url ", app.current_url(), " (expect site://trailtalk/index)")
	print("SELFTEST title -> ", browser_win.display_title, " (expect TrailTalk › Trip Reports — WEXP Browser)")
	await _shot("browser_page")

	app.navigate("site://trailtalk/thread/cascade")
	await _wait(0.9)
	print("SELFTEST thread -> url ", app.current_url(), " (expect site://trailtalk/thread/cascade)")
	print("SELFTEST keywords after thread -> ", Flags.keywords().size(), " (expect 3)")
	await _shot("browser_thread")

	# meta_clicked wiring (this is exactly what the label emits on a link click)
	app.content_label().meta_clicked.emit("site://mapleweb/index")
	await _wait(0.9)
	print("SELFTEST meta_clicked -> url ", app.current_url(), " (expect site://mapleweb/index)")
	print("SELFTEST keywords after webring -> ", Flags.keywords().size(), " (expect 5)")

	app.back_one()
	await _wait(0.9)
	print("SELFTEST back -> url ", app.current_url(), " (expect site://trailtalk/thread/cascade)")

	# close the window while a request is in flight (must not crash)
	app.navigate("site://trailtalk/index")
	await _wait(0.05)
	_mgr.close_window(browser_win)
	await _wait(1.0)
	print("SELFTEST close mid-load -> windows ", _mgr.windows().size(),
		" online ", NetSim.is_online(), " (expect 0 false)")

	# reopening dials again; cancel leaves the browser offline
	var browser_win2 := _mgr.open_app("browser")
	var app2: AppBase = _mgr.find_app("browser")
	await _wait(0.3)
	print("SELFTEST redial modal -> count ", _mgr.dialog_count(), " (expect 1)")
	var modal: DialupModal = _mgr.dialogs()[0]
	modal.cancel()
	await _wait(0.5)
	print("SELFTEST cancel -> modals ", _mgr.dialog_count(),
		" online ", NetSim.is_online(), " (expect 0 false)")
	await _shot("browser_offline")

	app2.navigate("site://trailtalk/index")
	await _wait(0.4)
	print("SELFTEST offline navigate -> status ", app2.status_text(), " (expect Error)")
	print("SELFTEST offline title -> ", browser_win2.display_title,
		" (expect Cannot find server — WEXP Browser)")

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
