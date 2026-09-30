extends Control

## Phase 2b selftest: WebRing traversal, flag-gated pages, cache recovery
## (authored snapshot + visited-page cache), cache list, mail offline state.

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
	var browser_win := _mgr.open_app("browser")
	var app: AppBase = _mgr.find_app("browser")
	await _wait(0.8)

	# WebRing traversal
	app.navigate("site://mapleweb/index")
	await _wait(0.7)
	print("SELFTEST ring next -> ", app.ring_url("next"), " (expect site://katpage/index)")
	app.navigate(app.ring_url("next"))
	await _wait(0.7)
	print("SELFTEST ring arrived -> ", app.current_url(), " (expect site://katpage/index)")
	print("SELFTEST ring back link -> ", app.ring_url("prev"), " (expect site://mapleweb/index)")
	await _shot("ring_page")

	# flag-gated page
	app.navigate("site://katpage/private")
	await _wait(0.7)
	print("SELFTEST gated before flag -> status ", app.status_text(), " (expect Error)")
	app.navigate("site://katpage/about")
	await _wait(0.7)
	print("SELFTEST about sets flag -> ", Flags.has("kat_about_read"), " (expect true)")
	app.navigate("site://katpage/private")
	await _wait(0.7)
	print("SELFTEST gated after flag -> status ", app.status_text(),
		" (expect site://katpage/private)")

	# authored cache snapshot of a deleted page
	app.navigate("site://katpage/oldguestbook")
	await _wait(0.7)
	print("SELFTEST deleted page live -> status ", app.status_text(), " (expect Error)")
	app.navigate("cache://katpage/oldguestbook")
	await _wait(0.7)
	print("SELFTEST cache view -> ", app.is_cache_view(),
		" status ", app.status_text(), " (expect true Cached: site://katpage/oldguestbook)")
	var kw := Flags.keywords().size()
	print("SELFTEST cache keyword collected -> ", kw, " (expect 8)")
	await _shot("cache_page")

	# visited-page cache + cache list
	app.show_cache_list()
	await _wait(0.3)
	print("SELFTEST cache list -> status ", app.status_text(), " (expect cache://)")
	print("SELFTEST cache urls -> ", NetSim.all_cache_urls(),
		" (expect contains cache://katpage/about)")
	await _shot("cache_list")

	# mail offline state follows the connection
	var mail_win := _mgr.open_app("mail")
	var mail: AppBase = _mgr.find_app("mail")
	await _wait(0.3)
	print("SELFTEST mail online -> offline view ", mail.is_offline_view(), " (expect false)")
	_mgr.close_window(browser_win)
	await _wait(0.4)
	print("SELFTEST mail after disconnect -> offline view ", mail.is_offline_view(),
		" (expect true), online ", NetSim.is_online(), " (expect false)")
	await _shot("mail_offline")
	_mgr.close_window(mail_win)

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
