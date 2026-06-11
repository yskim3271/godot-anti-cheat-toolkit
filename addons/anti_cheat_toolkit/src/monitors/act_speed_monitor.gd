extends RefCounted
class_name ACTSpeedMonitor

var _settings: Resource
var _bridge: RefCounted
var _last_real_usec := 0
var _window_real_usec := 0
var _window_game_usec := 0

func configure(settings: Resource, bridge: RefCounted) -> void:
	_settings = settings
	_bridge = bridge
	_last_real_usec = _bridge.get_monotonic_time_usec()
	_window_real_usec = 0
	_window_game_usec = 0


func sample(delta: float, expected_time_scale: float) -> Array:
	var events := []
	if _settings == null or not _settings.speed_hack_enabled:
		return events

	var now: int = int(_bridge.get_monotonic_time_usec())
	if _last_real_usec <= 0:
		_last_real_usec = now
		return events

	var real_delta := max(0, now - _last_real_usec)
	_last_real_usec = now
	if real_delta <= 0:
		return events

	_window_real_usec += real_delta
	_window_game_usec += int(max(delta, 0.0) * 1000000.0)

	var window_limit := int(_settings.speed_sample_window_sec * 1000000.0)
	if _window_real_usec < window_limit:
		return events

	var expected_game_usec: float = float(_window_real_usec) * max(expected_time_scale, 0.0001)
	var ratio: float = float(_window_game_usec) / max(expected_game_usec, 1.0)
	if abs(ratio - 1.0) > _settings.speed_tolerance:
		events.append({
			"type": "speed.drift",
			"severity": "high",
			"details": {
				"ratio": ratio,
				"window_real_usec": _window_real_usec,
				"window_game_usec": _window_game_usec,
				"expected_time_scale": expected_time_scale
			}
		})

	_window_real_usec = 0
	_window_game_usec = 0
	return events
