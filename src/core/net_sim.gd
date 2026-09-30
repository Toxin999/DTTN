extends Node

## Fake network. Autoload: NetSim.
## Pure lookup + request simulation (latency, offline/not-found). Which page
## version is visible is decided by Flags — NetSim only answers questions.

signal online_changed(online: bool)

const LATENCY := 0.35
const SITES_DIR := "res://content/en/sites"

var _sites: Dictionary = {}
var _online := false


func _ready() -> void:
	load_sites()


func load_sites(dir_path := SITES_DIR) -> int:
	_sites.clear()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("NetSim: missing site dir " + dir_path)
		return 0
	for file in dir.get_files():
		if not file.ends_with(".json"):
			continue
		var path := dir_path.path_join(file)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (parsed is Dictionary) or not parsed.has("id"):
			push_error("NetSim: bad site file " + path)
			continue
		_sites[parsed["id"]] = parsed
	return _sites.size()


func is_online() -> bool:
	return _online


func set_online(value: bool) -> void:
	if _online == value:
		return
	_online = value
	online_changed.emit(value)


func site_ids() -> Array:
	var keys := _sites.keys()
	keys.sort()
	return keys


## Simulated request. on_done receives a resolve() dictionary. The callback
## is skipped if its object was freed while the request was in flight.
func request(url: String, on_done: Callable) -> void:
	var timer := get_tree().create_timer(LATENCY)
	timer.timeout.connect(func():
		if on_done.is_valid():
			on_done.call(resolve(url)))


func resolve(url: String) -> Dictionary:
	if not _online:
		return {"status": "offline", "url": url}
	var parsed := parse_url(url)
	if parsed.is_empty() or not _sites.has(parsed["site"]):
		return {"status": "not_found", "url": url}
	var site: Dictionary = _sites[parsed["site"]]
	var pages: Dictionary = site.get("pages", {})
	var path: String = parsed["path"]
	if not pages.has(path):
		return {"status": "not_found", "url": url, "site": parsed["site"]}
	var page: Dictionary = pages[path]
	for flag in page.get("requires", []):
		if not Flags.has(flag):
			return {"status": "not_found", "url": url, "site": parsed["site"]}
	return {
		"status": "ok",
		"url": url,
		"site": parsed["site"],
		"site_name": site.get("name", parsed["site"]),
		"page": page,
	}


static func parse_url(url: String) -> Dictionary:
	# site://<site_id>/<path>
	if not url.begins_with("site://"):
		return {}
	var rest := url.trim_prefix("site://")
	var slash := rest.find("/")
	if slash < 0:
		return {"site": rest, "path": "/index"}
	var path := rest.substr(slash)
	if path.is_empty():
		path = "/index"
	return {"site": rest.substr(0, slash), "path": path}
