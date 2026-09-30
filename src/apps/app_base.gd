class_name AppBase
extends Control

## Base class for app content. Subclasses override build().
## window/manager are injected by WindowManager before build() runs.

var window: WexpWindow
var manager: WindowManager


func build() -> void:
	pass


func margin_container(margin := 8) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, margin)
	add_child(mc)
	return mc
