extends AppBase

## WEXP Browser: dial-up gating, block renderer, navigation + history.
## Pull-based: pages appear per flags; nothing is pushed into the app.

const HOME := "site://trailtalk/index"

var _rt: RichTextLabel
var _status: Label
var _history: Array[String] = []
var _history_index := -1
var _current_url := ""
var _ring: Dictionary = {}
var _cache_view := false


func build() -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	var back := Button.new()
	back.text = "◀ Back"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(back_one)
	bar.add_child(back)
	var cache_btn := Button.new()
	cache_btn.text = "Cache"
	cache_btn.focus_mode = Control.FOCUS_NONE
	cache_btn.tooltip_text = "Temporary Internet Files"
	cache_btn.pressed.connect(show_cache_list)
	bar.add_child(cache_btn)
	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	bar.add_child(_status)
	vb.add_child(bar)

	_rt = RichTextLabel.new()
	_rt.bbcode_enabled = true
	_rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rt.meta_clicked.connect(_on_meta_clicked)
	vb.add_child(_rt)

	var mc := margin_container(6)
	mc.add_child(vb)

	if NetSim.is_online():
		navigate(HOME)
	else:
		# Deferred: creating an embedded Window while the app is still being
		# added to its parent window breaks its rendering.
		_offer_dialup.call_deferred()


func _exit_tree() -> void:
	if window and window.app_id == "browser":
		NetSim.set_online(false)


# ---------------------------------------------------------------- api

func navigate(url: String) -> void:
	_request(url, true)


func back_one() -> void:
	if _history_index <= 0:
		return
	_history_index -= 1
	_request(_history[_history_index], false)


func current_url() -> String:
	return _current_url


func history_size() -> int:
	return _history.size()


func status_text() -> String:
	return _status.text


func content_label() -> RichTextLabel:
	return _rt


func ring_url(direction: String) -> String:
	return str(_ring.get(direction, ""))


func is_cache_view() -> bool:
	return _cache_view


# ---------------------------------------------------------------- dial-up

func _offer_dialup() -> void:
	_status.text = "Offline"
	_rt.text = "[b]You are not connected to the Internet.[/b]\n\nDialing in..."
	manager.dial_up(_on_dialup_result)


func _on_dialup_result(connected: bool) -> void:
	if not is_inside_tree():
		return
	if connected:
		NetSim.set_online(true)
		navigate(HOME)
	else:
		NetSim.set_online(false)
		_show_error("Dial-up was cancelled.",
			"The connection was not established. Open the browser again to redial.")


# ---------------------------------------------------------------- loading

func _request(url: String, push_history: bool) -> void:
	if not is_inside_tree():
		return
	if not NetSim.is_online():
		_show_error("Cannot find server", "You are offline. Open the browser to dial in.")
		return
	_status.text = "Opening %s ..." % url
	NetSim.request(url, func(result: Dictionary):
		_on_page_loaded(result, push_history))


func _on_page_loaded(result: Dictionary, push_history: bool) -> void:
	if not is_inside_tree():
		return
	match result.get("status", "not_found"):
		"ok":
			_current_url = result["url"]
			if push_history:
				_push_history(_current_url)
			_cache_view = false
			_render_page(result)
		"cache":
			_current_url = result["url"]
			if push_history:
				_push_history(_current_url)
			_cache_view = true
			_render_page(result)
		"offline":
			_show_error("Cannot find server", "You are offline. Open the browser to dial in.")
		_:
			_show_error("Cannot find server",
				"The page cannot be displayed: %s" % result.get("url", ""))


func _push_history(url: String) -> void:
	if _history_index >= 0 and _history[_history_index] == url:
		return
	_history = _history.slice(0, _history_index + 1)
	_history.append(url)
	_history_index = _history.size() - 1


func _render_page(result: Dictionary) -> void:
	var page: Dictionary = result["page"]
	var from_cache: bool = str(result.get("status", "")) == "cache"
	_ring = result.get("ring", {})
	var title: String = page.get("title", result.get("site_name", "Untitled"))
	if from_cache:
		title = "Cached: " + title
	if window:
		window.update_title("%s — WEXP Browser" % title)
	_status.text = "Cached: %s" % result.get("original_url", "") if from_cache else str(result.get("url", ""))
	for flag in page.get("sets_flags", []):
		Flags.set_flag(str(flag))
	var body := _render_blocks(page.get("blocks", []), _ring)
	if from_cache:
		body = "[i][color=#666666]Cached copy of %s — saved %s[/color][/i]\n\n%s" % [
			result.get("original_url", ""), result.get("cached_at", "unknown"), body]
	_rt.text = body
	for kw in page.get("keywords", []):
		Flags.collect_keyword(kw.get("keyword", ""), result.get("url", ""), kw.get("label", ""))
	Flags.set_flag("visited:" + str(result.get("site", "")))


## Internal page: everything currently recoverable from the cache.
func show_cache_list() -> void:
	_cache_view = false
	var urls := NetSim.all_cache_urls()
	var lines: Array[String] = ["[b]WEXP Browser — Temporary Internet Files[/b]", ""]
	if urls.is_empty():
		lines.append("The cache is empty. Browse a few pages first.")
	else:
		for url in urls:
			lines.append(UiTheme.link(url, url))
	_status.text = "cache://"
	if window:
		window.update_title("Temporary Internet Files — WEXP Browser")
	_rt.text = "\n".join(lines)


func _show_error(title: String, detail: String) -> void:
	_status.text = "Error"
	_rt.text = "[b]%s[/b]\n\n%s" % [title, detail]
	if window:
		window.update_title("Cannot find server — WEXP Browser")


func _render_blocks(blocks: Array, ring: Dictionary) -> String:
	var parts: Array[String] = []
	for block in blocks:
		match str(block.get("type", "")):
			"heading":
				parts.append("[b][font_size=16]%s[/font_size][/b]" % block.get("text", ""))
			"text":
				parts.append(str(block.get("text", "")))
			"links":
				var lines: Array[String] = []
				for item in block.get("items", []):
					lines.append(UiTheme.link(str(item.get("url", "")), str(item.get("text", ""))))
				parts.append("\n".join(lines))
			"ring":
				var nav := _render_ring(ring)
				if not nav.is_empty():
					parts.append(nav)
			"rule":
				parts.append("[hr]")
			_:
				push_warning("browser: unknown block type " + str(block.get("type", "")))
	return "\n\n".join(parts)


func _render_ring(ring: Dictionary) -> String:
	if ring.is_empty():
		return ""
	var nav: Array[String] = []
	if ring.has("prev"):
		nav.append(UiTheme.link(str(ring["prev"]), "◀ prev site"))
	nav.append("[i]%s[/i]" % str(ring.get("position", "WebRing")))
	if ring.has("next"):
		nav.append(UiTheme.link(str(ring["next"]), "next site ▶"))
	return "[center]%s[/center]" % "   ·   ".join(nav)


func _on_meta_clicked(meta: Variant) -> void:
	navigate(str(meta))
