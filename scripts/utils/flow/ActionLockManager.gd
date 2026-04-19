class_name ActionLockManager
extends RefCounted

var _in_flight: Dictionary = {}
var _cooldown_until_ms: Dictionary = {}

func can_execute(action_key: String) -> bool:
	if action_key.is_empty():
		return false
	if bool(_in_flight.get(action_key, false)):
		return false
	var now_ms := Time.get_ticks_msec()
	var until_ms := int(_cooldown_until_ms.get(action_key, 0))
	return now_ms >= until_ms

func try_begin(action_key: String) -> bool:
	if not can_execute(action_key):
		return false
	_in_flight[action_key] = true
	return true

func end(action_key: String, cooldown_seconds: float = 0.1) -> void:
	if action_key.is_empty():
		return
	_in_flight.erase(action_key)
	var cooldown_ms := int(round(maxf(0.0, cooldown_seconds) * 1000.0))
	if cooldown_ms > 0:
		_cooldown_until_ms[action_key] = Time.get_ticks_msec() + cooldown_ms
	else:
		_cooldown_until_ms.erase(action_key)

func is_in_flight(action_key: String) -> bool:
	return bool(_in_flight.get(action_key, false))

func has_any_in_flight() -> bool:
	return not _in_flight.is_empty()
