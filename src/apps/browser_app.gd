extends AppBase

## Phase 1 placeholder content: a forum thread rendered with BBCode.

func build() -> void:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.add_theme_font_size_override("normal_font_size", 13)
	rt.text = """[b]TrailTalk › Trip Reports › Cascade Ridge day hike — Sat 9/14[/b]
[color=#666666]posted by river_kat on 09-02-2002 3:41 PM[/color]

Anyone up for Cascade Ridge next Saturday? Meet at the trailhead lot at 7 AM, I'll bring the map and extra water. Post here if you're coming — we can carpool from the Safeway on 3rd.

[b]Re: Cascade Ridge day hike — Sat 9/14[/b]
[color=#666666]sundance_77 on 09-05-2002 11:02 PM[/color]
I'm in. Bringing my new digicam so we better get some good light up there.

[b]Re: Cascade Ridge day hike — Sat 9/14[/b]
[color=#666666]river_kat on 09-13-2002 6:20 PM[/color]
Weather looks clear. See everyone at the lot, 7 sharp. Don't wait up!"""
	var mc := margin_container(6)
	mc.add_child(rt)
