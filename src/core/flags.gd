extends Node

## Story flags + collected keywords. Autoload: Flags.
## Pull-based model: content is revealed by flags, never pushed by timers.

signal flag_changed(flag: String)
signal keyword_collected(keyword: String)

var _flags: Dictionary = {}
var _keywords: Dictionary = {}


func set_flag(flag: String) -> void:
	if _flags.has(flag):
		return
	_flags[flag] = true
	flag_changed.emit(flag)


func has(flag: String) -> bool:
	return _flags.has(flag)


func all_flags() -> Array:
	var keys := _flags.keys()
	keys.sort()
	return keys


func collect_keyword(keyword: String, source: String, label := "") -> void:
	if keyword.is_empty() or _keywords.has(keyword):
		return
	_keywords[keyword] = {"keyword": keyword, "source": source, "label": label}
	keyword_collected.emit(keyword)


func keywords() -> Array:
	var out := _keywords.values()
	out.sort_custom(func(a, b): return a.keyword < b.keyword)
	return out


func reset() -> void:
	_flags.clear()
	_keywords.clear()
