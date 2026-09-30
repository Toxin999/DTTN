extends Control

## Phase 0 spike: EN + TH text shaping / line breaking in RichTextLabel.

const FONT_REG := "res://assets/fonts/PT_Sans-Web-Regular.ttf"
const FONT_BOLD := "res://assets/fonts/PT_Sans-Web-Bold.ttf"
const FONT_THAI := "res://assets/fonts/Sarabun-Regular.ttf"
const FONT_THAI_BOLD := "res://assets/fonts/Sarabun-Bold.ttf"

const TH_POST := """สวัสดีค่ะ ใครพอจะรู้ข่าวของนกบ้างไหมคะ

หายไปสองอาทิตย์แล้ว ไม่ตอบอีเมล ไม่ตอบข้อความในบอร์ดเลย เมื่อก่อนนกเข้ามาโพสต์ทุกวัน ตั้งแต่ทริปเขาใหญ่ก็เงียบไปเลย

ใครมีเบอร์หรือที่อยู่ช่วยโพสต์ไว้ในกระทู้ด้วยนะคะ เป็นห่วงมาก ตำรวจบอกว่ายังไม่มีความคืบหน้าเลยค่ะ

จากที่คุยกับพี่ชายของนกเมื่อวานเขาบอกว่านกไม่เคยหายไปแบบนี้มาก่อนเลยและไม่เคยปิดโทรศัพท์นานขนาดนี้ด้วยซึ่งมันไม่เหมือนนิสัยของนกเลยแม้แต่นิดเดียว"""

const EN_POST := """Hey everyone — has anyone actually heard from kat? She said she'd post the photos from Cascade Ridge like two weeks ago and nothing. Her AIM has been idle forever.

I called the ranger station, they said they'd check the lot logs but honestly I don't think they took it seriously. If she was gonna take off somewhere she would've told SOMEONE, she wasn't like that.

Inline [b]bold[/b], [i]italic[/i], [color=#884400]colored[/color], and a [url=trailtalk://thread/1]link[/url] check."""


func _ready() -> void:
	var thai: FontFile = load(FONT_THAI)
	var thai_bold: FontFile = load(FONT_THAI_BOLD)
	var f: FontFile = load(FONT_REG)
	f.fallbacks = [thai]
	var fb: FontFile = load(FONT_BOLD)
	fb.fallbacks = [thai_bold]

	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.2, 0.28)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var hb := HBoxContainer.new()
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	hb.add_theme_constant_override("separation", 24)
	add_child(hb)

	hb.add_child(_post_card(f, fb, "EN — 420px", EN_POST))
	hb.add_child(_post_card(f, fb, "TH — 420px", TH_POST, true))


func _post_card(f: FontFile, fb: FontFile, header: String, body: String, bold_header := false) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	var h := Label.new()
	h.text = header
	h.add_theme_font_override("font", fb if bold_header else f)
	h.add_theme_font_size_override("font_size", 12)
	h.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	vb.add_child(h)

	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_override("normal_font", f)
	rt.add_theme_font_override("bold_font", fb)
	rt.add_theme_font_size_override("normal_font_size", 13)
	rt.add_theme_font_size_override("bold_font_size", 13)
	rt.add_theme_color_override("default_color", Color(0.1, 0.1, 0.1))
	rt.text = body
	vb.add_child(rt)
	return card
