extends Node

## In-game clock. Autoload: WorldClock.
## One real second = one in-game minute (tunable later per chapter).

signal minute_passed(minutes_total: int)

const SECONDS_PER_GAME_MINUTE := 1.0

## 2002-09-02 15:41, the day the player first opens the thread.
var _base := {"year": 2002, "month": 9, "day": 2, "hour": 15, "minute": 41}
var running := true

var _elapsed_minutes := 0
var _accum := 0.0


func _process(delta: float) -> void:
	if not running:
		return
	_accum += delta
	while _accum >= SECONDS_PER_GAME_MINUTE:
		_accum -= SECONDS_PER_GAME_MINUTE
		_elapsed_minutes += 1
		minute_passed.emit(_elapsed_minutes)


func minutes_total() -> int:
	return _elapsed_minutes


func now() -> Dictionary:
	var d := _to_datetime(_base, _elapsed_minutes)
	return d


func time_string() -> String:
	var d := now()
	var hour := int(d["hour"])
	var ampm := "AM" if hour < 12 else "PM"
	hour = hour % 12
	if hour == 0:
		hour = 12
	return "%d:%02d %s" % [hour, d["minute"], ampm]


func datetime_string() -> String:
	var d := now()
	return "%02d-%02d-%d %d:%02d" % [d["month"], d["day"], d["year"], d["hour"], d["minute"]]


func _to_datetime(base: Dictionary, add_minutes: int) -> Dictionary:
	# Minute-level arithmetic with day/month/year rollover (proleptic simple months).
	var total := int(base["hour"]) * 60 + int(base["minute"]) + add_minutes
	var day: int = int(base["day"]) + int(floor(total / 1440.0))
	var minute_of_day := total % 1440
	var hour := int(floor(minute_of_day / 60.0))
	var minute := minute_of_day % 60
	var month: int = int(base["month"])
	var year: int = int(base["year"])
	while true:
		var dim := _days_in_month(year, month)
		if day <= dim:
			break
		day -= dim
		month += 1
		if month > 12:
			month = 1
			year += 1
	return {"year": year, "month": month, "day": day, "hour": hour, "minute": minute}


func _days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		_:
			var leap := (year % 4 == 0 and year % 100 != 0) or year % 400 == 0
			return 29 if leap else 28
