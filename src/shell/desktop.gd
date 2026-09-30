extends Control

## Desktop shell root: wallpaper, window manager, overlays.

const WALLPAPER := "res://assets/ui/luna/wallpaper_hills.png"

var _manager: WindowManager


func _ready() -> void:
	theme = UiTheme.build()
	_build_wallpaper()
	_build_click_catcher()
	_manager = WindowManager.new()
	_manager.name = "WindowManager"
	add_child(_manager)
	_manager.setup(self, theme)


func manager() -> WindowManager:
	return _manager


func _build_wallpaper() -> void:
	var bg := TextureRect.new()
	bg.texture = load(WALLPAPER)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _build_click_catcher() -> void:
	var catcher := Control.new()
	catcher.name = "DesktopCatcher"
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(func(_e: InputEvent):
		if _manager and _manager.start_menu_open():
			_manager.close_start_menu())
	add_child(catcher)
