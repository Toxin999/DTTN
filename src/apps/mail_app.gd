extends AppBase

## Phase 1 placeholder content: inbox list.

const ROWS := [
	["From: mark_holt@...", "RE: have you heard from kat?", "Sep 30"],
	["From: trailtalk-mod@...", "Thread locked — missing person", "Sep 28"],
	["From: mom@...", "dinner sunday?", "Sep 27"],
]


func build() -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	for row in ROWS:
		var l := Label.new()
		l.text = "%s\n%s          %s" % [row[0], row[1], row[2]]
		l.add_theme_font_size_override("font_size", 12)
		vb.add_child(l)
	var mc := margin_container(10)
	mc.add_child(vb)
