extends RefCounted
class_name ACTNativeBridge

var _settings: Resource
var _native: Object

func configure(settings: Resource) -> void:
	_settings = settings
	if _native != null:
		return
	if ClassDB.class_exists("AntiCheatNative"):
		_native = ClassDB.instantiate("AntiCheatNative")


func is_available() -> bool:
	return _native != null


func get_monotonic_time_usec() -> int:
	if _native != null and _native.has_method("get_monotonic_time_usec"):
		return int(_native.call("get_monotonic_time_usec"))
	return Time.get_ticks_usec()


func get_system_time_usec() -> int:
	if _native != null and _native.has_method("get_system_time_usec"):
		return int(_native.call("get_system_time_usec"))
	return int(Time.get_unix_time_from_system() * 1000000.0)


func get_runtime_report() -> Dictionary:
	if _native == null:
		return {"native_available": false}
	var suspicious := PackedStringArray()
	var allowed := PackedStringArray()
	var include_paths := false
	if _settings != null:
		suspicious = _settings.suspicious_process_names
		allowed = _settings.allowed_module_names
		include_paths = _settings.include_native_paths
	return Dictionary(_native.call("get_runtime_report", suspicious, allowed, include_paths))
