class_name WindowManager
extends Node

## Owns windows, focus stack, taskbar and start menu policy.
## The taskbar and the start menu must be embedded Windows, not Controls:
## subwindows always draw above every CanvasLayer (Phase 0 finding).

const APP_REGISTRY := {
	"browser": {
		"title": "TrailTalk — WEXP Browser",
		"size": Vector2i(760, 480),
		"script": "res://src/apps/browser_app.gd",
	},
	"mail": {
		"title": "Inbox — WEXP Mail",
		"size": Vector2i(600, 420),
		"script": "res://src/apps/mail_app.gd",
	},
	"settings": {
		"title": "Control Panel",
		"size": Vector2i(440, 340),
		"script": "res://src/apps/settings_app.gd",
	},
}

var _host: Control
var _theme: Theme
var _taskbar: Taskbar
var _start_menu: StartMenu
var _windows: Array[WexpWindow] = []
var _cascade := 0
var _last_active: WexpWindow


func setup(host: Control, shell_theme: Theme) -> void:
	_host = host
	_theme = shell_theme

	_taskbar = Taskbar.new()
	add_child(_taskbar)
	_taskbar.setup(_theme)
	_taskbar.start_pressed.connect(toggle_start_menu)
	_taskbar.window_button_pressed.connect(_on_taskbar_button)

	_start_menu = StartMenu.new()
	add_child(_start_menu)
	_start_menu.setup(_theme)
	_start_menu.item_chosen.connect(_on_menu_item)
	_start_menu.close_requested.connect(close_start_menu)

	_host.get_viewport().size_changed.connect(handle_viewport_resize)
	WorldClock.minute_passed.connect(_on_minute_passed)
	_update_clock()
	handle_viewport_resize()


# ---------------------------------------------------------------- apps

func open_app(app_id: String) -> WexpWindow:
	if not APP_REGISTRY.has(app_id):
		push_error("WindowManager: unknown app '%s'" % app_id)
		return null
	for w in _windows:
		if is_instance_valid(w) and w.app_id == app_id:
			if not w.visible:
				w.visible = true
			w.grab_focus()
			return w
	var cfg: Dictionary = APP_REGISTRY[app_id]
	var w := WexpWindow.new()
	w.theme = _theme
	w.setup(app_id, cfg["title"], cfg["size"], _next_position(cfg["size"]))
	add_child(w)
	_windows.append(w)

	var app: Control = load(cfg["script"]).new()
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	w.content_parent().add_child(app)
	if app.has_method("build"):
		app.call("build")

	w.close_requested.connect(func(): close_window(w))
	w.minimize_requested.connect(func(): minimize_window(w))
	w.maximize_requested.connect(func(): toggle_maximize(w))
	w.focus_entered.connect(func(): _on_window_focus(w))
	w.focus_exited.connect(func():
		w.set_meta("dragging", false)
		_taskbar.sync_button(w))

	_taskbar.add_window_button(w)
	w.grab_focus()
	_restack_overlays()
	return w


func close_window(w: WexpWindow) -> void:
	if not is_instance_valid(w):
		return
	_taskbar.remove_window_button(w)
	_windows.erase(w)
	w.queue_free()
	focus_top_visible()


func minimize_window(w: WexpWindow) -> void:
	w.visible = false
	w.set_meta("dragging", false)
	_taskbar.sync_button(w)
	focus_top_visible()


func toggle_maximize(w: WexpWindow) -> void:
	var vis := _host.get_viewport().get_visible_rect().size
	if w.get_meta("maximized", false):
		w.position = w.get_meta("saved_pos")
		w.size = w.get_meta("saved_size")
		w.set_meta("maximized", false)
	else:
		w.set_meta("saved_pos", w.position)
		w.set_meta("saved_size", w.size)
		w.position = Vector2i.ZERO
		w.size = Vector2i(int(vis.x), int(vis.y) - Taskbar.BAR_H)
		w.set_meta("maximized", true)


func focus_top_visible() -> void:
	for i in range(_windows.size() - 1, -1, -1):
		var w: WexpWindow = _windows[i]
		if is_instance_valid(w) and w.visible:
			w.grab_focus()
			return


func _next_position(win_size: Vector2i) -> Vector2i:
	var pos := Vector2i(90, 60) + Vector2i(28, 28) * _cascade
	_cascade = (_cascade + 1) % 6
	var vis := _host.get_viewport().get_visible_rect().size
	if pos.x + win_size.x > vis.x:
		pos.x = maxi(0, int(vis.x) - win_size.x - 20)
	if pos.y + win_size.y > vis.y - Taskbar.BAR_H:
		pos.y = maxi(0, int(vis.y) - Taskbar.BAR_H - win_size.y - 20)
	return pos


func _on_window_focus(w: WexpWindow) -> void:
	_last_active = w
	for other in _windows:
		if is_instance_valid(other):
			other.set_active(other == w)
	_taskbar.sync_button(w)
	if _start_menu.is_open():
		close_start_menu()
	_restack_overlays()


# ---------------------------------------------------------------- start menu

func toggle_start_menu() -> void:
	if _start_menu.is_open():
		close_start_menu()
	else:
		_start_menu.open_menu(_host.get_viewport().get_visible_rect().size, Settings.user_name)
		_taskbar.set_start_active(true)
		_restack_overlays()


func close_start_menu() -> void:
	if not _start_menu.is_open():
		return
	_start_menu.close_menu()
	_taskbar.set_start_active(false)
	if is_instance_valid(_last_active) and _last_active.visible:
		_last_active.grab_focus()
	_restack_overlays()


func start_menu_open() -> bool:
	return _start_menu.is_open()


func _on_menu_item(action: String) -> void:
	close_start_menu()
	if action == "quit":
		quit_game()
	elif action.begins_with("app:"):
		var app_id := action.trim_prefix("app:")
		if app_id == "settings_short":
			app_id = "settings"
		open_app(app_id)


# ---------------------------------------------------------------- taskbar

func _on_taskbar_button(w: WexpWindow) -> void:
	if not is_instance_valid(w):
		return
	close_start_menu()
	if not w.visible:
		w.visible = true
		w.grab_focus()
	elif w == _last_active or w.has_focus():
		minimize_window(w)
	else:
		w.grab_focus()
	_taskbar.sync_button(w)
	_restack_overlays()


func _restack_overlays() -> void:
	if _taskbar.get_index() != get_child_count() - 1:
		move_child(_taskbar, -1)
	if _start_menu.is_open() and _start_menu.get_index() != get_child_count() - 1:
		move_child(_start_menu, -1)


# ---------------------------------------------------------------- shell

func quit_game() -> void:
	for w in _windows.duplicate():
		if is_instance_valid(w):
			w.queue_free()
	_windows.clear()
	_start_menu.queue_free()
	_taskbar.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()


func handle_viewport_resize() -> void:
	var vis := _host.get_viewport().get_visible_rect().size
	_taskbar.reposition(vis)
	if _start_menu.is_open():
		_start_menu.open_menu(vis, Settings.user_name)
	for w in _windows:
		if not is_instance_valid(w):
			continue
		w.size = Vector2i(mini(w.size.x, int(vis.x)), mini(w.size.y, int(vis.y) - Taskbar.BAR_H))
		if w.get_meta("maximized", false):
			w.size = Vector2i(int(vis.x), int(vis.y) - Taskbar.BAR_H)
		else:
			var np: Vector2 = Vector2(w.position)
			np.x = clampf(np.x, -w.size.x + 90.0, maxf(0.0, vis.x - 60.0))
			np.y = clampf(np.y, 0.0, maxf(0.0, vis.y - Taskbar.BAR_H - WexpWindow.TITLE_H))
			w.position = Vector2i(np)
	_restack_overlays()


func _on_minute_passed(_minutes: int) -> void:
	_update_clock()


func _update_clock() -> void:
	_taskbar.set_clock(WorldClock.time_string())


# ---------------------------------------------------------------- test helpers

func windows() -> Array[WexpWindow]:
	return _windows


func find_window(app_id: String) -> WexpWindow:
	for w in _windows:
		if is_instance_valid(w) and w.app_id == app_id:
			return w
	return null


func taskbar_button_center(w: WexpWindow) -> Vector2:
	return _taskbar.button_center(w)


func taskbar_start_center() -> Vector2:
	return _taskbar.start_center()


func start_menu_item_center(action: String) -> Vector2:
	return _start_menu.item_center(action)


func chrome_button_center(w: WexpWindow, glyph: String) -> Vector2:
	return w.button_center(glyph)


func start_button_active() -> bool:
	return _taskbar.start_is_active()
