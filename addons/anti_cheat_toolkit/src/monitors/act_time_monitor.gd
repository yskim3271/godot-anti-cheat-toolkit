extends RefCounted
class_name ACTTimeMonitor

var _settings: Resource
var _bridge: RefCounted
var _baseline_wall_usec := 0
var _baseline_mono_usec := 0
var _last_wall_usec := 0

func configure(settings: Resource, bridge: RefCounted) -> void:
	_settings = settings
	_bridge = bridge
	_baseline_wall_usec = _bridge.get_system_time_usec()
	_baseline_mono_usec = _bridge.get_monotonic_time_usec()
	_last_wall_usec = _baseline_wall_usec


func sample() -> Array:
	var events := []
	if _settings == null or not _settings.time_check_enabled:
		return events

	var wall: int = int(_bridge.get_system_time_usec())
	var mono: int = int(_bridge.get_monotonic_time_usec())
	var expected_wall: int = _baseline_wall_usec + (mono - _baseline_mono_usec)
	var drift_ms := int((wall - expected_wall) / 1000)

	if wall + 1000000 < _last_wall_usec:
		events.append({
			"type": "time.clock_moved_back",
			"severity": "medium",
			"details": {"previous_wall_usec": _last_wall_usec, "current_wall_usec": wall}
		})
	elif abs(drift_ms) > _settings.max_wall_clock_drift_ms:
		events.append({
			"type": "time.wall_clock_drift",
			"severity": "medium",
			"details": {"drift_ms": drift_ms, "limit_ms": _settings.max_wall_clock_drift_ms}
		})
		_baseline_wall_usec = wall
		_baseline_mono_usec = mono

	_last_wall_usec = wall
	return events
