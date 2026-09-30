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
	"terminal": {
		"title": "Command Prompt",
		"size": Vector2i(660, 440),
		"script": "res://src/apps/terminal_app.gd",
	},
	"caseboard": {
		"title": "CaseBoard — evidence notes",
		"size": Vector2i(420, 460),
		"script": "res://src/apps/caseboard_app.gd",
	},
}

var _host: Control
var _theme: Theme
var _taskbar: Taskbar
var _start_menu: StartMenu
var _windows: Array[WexpWindow] = []
var _dialogs: Array[Window] = []
var _modal: Window
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
	_taskbar.set_press_hook(_regrab_modal_deferred)

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
	if is_instance_valid(_modal):
		return null
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
	if app is AppBase:
		app.window = w
		app.manager = self
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	w.content_parent().add_child(app)
	if app.has_method("build"):
		app.call("build")
	if app is AppBase:
		w.app = app

	w.close_requested.connect(func(): close_window(w))
	w.minimize_requested.connect(func(): minimize_window(w))
	w.maximize_requested.connect(func(): toggle_maximize(w))
	w.focus_entered.connect(func(): _on_window_focus(w))
	w.focus_exited.connect(func():
		w.set_meta("dragging", false)
		_taskbar.sync_button(w))
	w.title_changed.connect(func(): _taskbar.sync_button(w))

	_taskbar.add_window_button(w)
	w.grab_focus()
	if w.has_focus():
		# Embedded windows auto-focus on add, which emits focus_entered
		# before our handler is connected — sync the state explicitly.
		_on_window_focus(w)
	_restack_overlays()
	return w


func close_window(w: WexpWindow) -> void:
	if not is_instance_valid(w):
		return
	if w == _last_active:
		_last_active = null
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
	if is_instance_valid(_modal) and w != _modal:
		_modal.grab_focus()
		return
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
	if is_instance_valid(_modal):
		return
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


# ---------------------------------------------------------------- dialogs

## Dialogs stack above the taskbar and start menu, and block mouse input to
## app windows while open (embedded subwindows ignore Window.exclusive, so
## blocking is done with per-window input blockers).
## The caller creates the window (content included) but must not add it.
func open_dialog(dialog: Window, modal := true) -> Window:
	dialog.theme = _theme
	dialog.exclusive = modal
	add_child(dialog)
	var vis := _host.get_viewport().get_visible_rect().size
	dialog.position = Vector2i(
		int((vis.x - dialog.size.x) / 2.0),
		int((vis.y - dialog.size.y) / 2.5))
	_dialogs.append(dialog)
	dialog.close_requested.connect(func(): close_dialog(dialog))
	if modal:
		_modal = dialog
		_set_windows_blocked(true)
	dialog.grab_focus()
	_restack_overlays()
	return dialog


func close_dialog(dialog: Window) -> void:
	if not is_instance_valid(dialog):
		return
	_dialogs.erase(dialog)
	if _modal == dialog:
		_modal = null
		_set_windows_blocked(false)
	dialog.exclusive = false
	dialog.queue_free()
	_restack_overlays()
	_restore_active_focus()


func _restore_active_focus() -> void:
	# Focus can only move once the exclusive dialog has left the tree.
	await get_tree().process_frame
	if is_instance_valid(_last_active) and _last_active.visible:
		_last_active.grab_focus()


func _set_windows_blocked(blocked: bool) -> void:
	for w in _windows:
		if is_instance_valid(w):
			w.set_input_blocked(blocked)


## Clicks on the desktop background also steal subwindow focus from a modal.
func notify_background_click() -> void:
	_regrab_modal_deferred()


func _regrab_modal_deferred() -> void:
	if not is_instance_valid(_modal):
		return
	# Focus transitions land a frame (or two) after the click.
	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(_modal) and not _modal.has_focus():
		_modal.grab_focus()


func dialog_count() -> int:
	return _dialogs.size()


func dialogs() -> Array[Window]:
	return _dialogs


## Dial-up modal for the browser. on_result(connected: bool) always runs,
## even if the caller is freed while the modal is open (caller must guard).
func dial_up(on_result: Callable) -> DialupModal:
	var modal := DialupModal.new()
	modal.setup()
	modal.finished.connect(func(connected: bool):
		if on_result.is_valid():
			on_result.call(connected))
	open_dialog(modal, true)
	return modal


# ---------------------------------------------------------------- taskbar

func _on_taskbar_button(w: WexpWindow) -> void:
	if not is_instance_valid(w):
		return
	if is_instance_valid(_modal):
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
	for d in _dialogs:
		if is_instance_valid(d) and d.get_index() != get_child_count() - 1:
			move_child(d, -1)


# ---------------------------------------------------------------- shell

func quit_game() -> void:
	for w in _windows.duplicate():
		if is_instance_valid(w):
			w.queue_free()
	_windows.clear()
	for d in _dialogs.duplicate():
		if is_instance_valid(d):
			d.queue_free()
	_dialogs.clear()
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


func find_app(app_id: String) -> AppBase:
	var w := find_window(app_id)
	return w.app if w else null


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
