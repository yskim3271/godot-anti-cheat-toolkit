extends SceneTree

const ACTSettings := preload("res://addons/anti_cheat_toolkit/src/act_settings.gd")
const ACTSpeedMonitor := preload("res://addons/anti_cheat_toolkit/src/monitors/act_speed_monitor.gd")
const ACTTimeMonitor := preload("res://addons/anti_cheat_toolkit/src/monitors/act_time_monitor.gd")

class FakeBridge:
	extends RefCounted

	var mono_usec := 0
	var wall_usec := 0

	func get_monotonic_time_usec() -> int:
		return mono_usec

	func get_system_time_usec() -> int:
		return wall_usec


func _initialize() -> void:
	_test_speed_drift()
	_test_time_drift()
	_test_clock_moved_back()
	quit(0)


func _test_speed_drift() -> void:
	var settings = ACTSettings.new()
	settings.speed_hack_enabled = true
	settings.speed_tolerance = 0.10
	settings.speed_sample_window_sec = 1.0

	var bridge := FakeBridge.new()
	bridge.mono_usec = 1_000_000
	var monitor = ACTSpeedMonitor.new()
	monitor.configure(settings, bridge)
	bridge.mono_usec = 2_000_000

	var events := monitor.sample(2.0, 1.0)
	if events.size() != 1 or Dictionary(events[0]).get("type", "") != "speed.drift":
		_fail("speed drift was not detected: %s" % JSON.stringify(events))


func _test_time_drift() -> void:
	var settings = ACTSettings.new()
	settings.time_check_enabled = true
	settings.max_wall_clock_drift_ms = 100

	var bridge := FakeBridge.new()
	bridge.mono_usec = 1_000_000
	bridge.wall_usec = 100_000_000
	var monitor = ACTTimeMonitor.new()
	monitor.configure(settings, bridge)
	bridge.mono_usec = 2_000_000
	bridge.wall_usec = 102_000_000

	var events := monitor.sample()
	if events.size() != 1 or Dictionary(events[0]).get("type", "") != "time.wall_clock_drift":
		_fail("wall clock drift was not detected: %s" % JSON.stringify(events))


func _test_clock_moved_back() -> void:
	var settings = ACTSettings.new()
	settings.time_check_enabled = true

	var bridge := FakeBridge.new()
	bridge.mono_usec = 1_000_000
	bridge.wall_usec = 100_000_000
	var monitor = ACTTimeMonitor.new()
	monitor.configure(settings, bridge)
	bridge.mono_usec = 1_500_000
	bridge.wall_usec = 98_000_000

	var events := monitor.sample()
	if events.size() != 1 or Dictionary(events[0]).get("type", "") != "time.clock_moved_back":
		_fail("clock rollback was not detected: %s" % JSON.stringify(events))


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

