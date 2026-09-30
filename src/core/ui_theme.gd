class_name UiTheme

## Builds the global WEXP theme in code (single source of truth).
## Applying it: assign to the desktop root Control and to every embedded
## Window (themes do not propagate across viewports).

const FONT_REG := "res://assets/fonts/PT_Sans-Web-Regular.ttf"
const FONT_BOLD := "res://assets/fonts/PT_Sans-Web-Bold.ttf"
const FONT_THAI := "res://assets/fonts/Sarabun-Regular.ttf"
const FONT_THAI_BOLD := "res://assets/fonts/Sarabun-Bold.ttf"

const TEXT := Color(0.08, 0.08, 0.08)
const MUTED := Color(0.38, 0.38, 0.38)
const CLIENT_BG := Color(0.925, 0.91, 0.847)
const CLIENT_BORDER := Color(0.13, 0.32, 0.69)


static func regular() -> FontFile:
	var f: FontFile = load(FONT_REG)
	f.fallbacks = [load(FONT_THAI)]
	return f


static func bold() -> FontFile:
	var f: FontFile = load(FONT_BOLD)
	f.fallbacks = [load(FONT_THAI_BOLD)]
	return f


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = regular()
	t.default_font_size = 13

	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font("bold_font", "RichTextLabel", bold())
	t.set_font_size("bold_font_size", "RichTextLabel", 13)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", TEXT)
	t.set_color("font_focus_color", "Button", TEXT)

	var normal := _button_style(Color(0.93, 0.91, 0.85), Color(0.45, 0.44, 0.37))
	var hover := _button_style(Color(0.985, 0.975, 0.93), Color(0.24, 0.42, 0.75))
	var pressed := _button_style(Color(0.86, 0.83, 0.75), Color(0.21, 0.37, 0.66))
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", hover)

	# CheckBox/CheckButton draw their own box icon — drop the button frame.
	var empty := StyleBoxEmpty.new()
	t.set_stylebox("normal", "CheckBox", empty)
	t.set_stylebox("hover", "CheckBox", empty)
	t.set_stylebox("pressed", "CheckBox", empty)
	t.set_stylebox("focus", "CheckBox", empty)
	t.set_stylebox("disabled", "CheckBox", empty)
	return t


static func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


static func client_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CLIENT_BG
	sb.border_color = CLIENT_BORDER
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	return sb
