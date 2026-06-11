extends Resource
class_name ACTSettings

@export var enabled := true
@export var auto_start := true
@export var developer_mode := false
@export var disable_in_development := true
@export var native_checks_enabled := true
@export var native_check_interval_sec := 10.0
@export var report_send_enabled := false
@export var report_endpoint := ""
@export var log_path := "user://anti_cheat_events.jsonl"
@export var report_queue_path := "user://anti_cheat_report_queue.jsonl"

@export var speed_hack_enabled := true
@export var speed_tolerance := 0.25
@export var speed_sample_window_sec := 4.0

@export var time_check_enabled := true
@export var max_wall_clock_drift_ms := 3000

@export var save_protection_enabled := true
@export var rollback_store_path := "user://anti_cheat_rollback_store.json"

@export var file_integrity_enabled := true
@export var file_integrity_manifest_path := "res://addons/anti_cheat_toolkit/integrity_manifest.json"
@export var file_integrity_manifest_secret := ""
@export var monitored_files := PackedStringArray()

@export var device_fingerprint_opt_in := false
@export var device_fingerprint_salt := ""
@export var include_hardware_id_in_fingerprint := false
@export var install_id_path := "user://anti_cheat_install_id"
@export var include_native_paths := false
@export var suspicious_process_names := PackedStringArray([
	"cheatengine",
	"cheatengine-x86_64",
	"x64dbg",
	"x32dbg",
	"ida",
	"ida64",
	"ollydbg",
	"processhacker"
])
@export var allowed_module_names := PackedStringArray()

func apply_overrides(overrides: Dictionary) -> void:
	var property_names := {}
	for property in get_property_list():
		property_names[String(property.get("name", ""))] = true
	for key in overrides.keys():
		if property_names.has(String(key)):
			set(key, overrides[key])


static func from_project_settings():
	ensure_project_settings()
	var s = load("res://addons/anti_cheat_toolkit/src/act_settings.gd").new()
	s.enabled = bool(_project_get("anti_cheat_toolkit/enabled", true))
	s.auto_start = bool(_project_get("anti_cheat_toolkit/auto_start", true))
	s.developer_mode = bool(_project_get("anti_cheat_toolkit/developer_mode", OS.is_debug_build()))
	s.disable_in_development = bool(_project_get("anti_cheat_toolkit/disable_in_development", true))
	s.native_checks_enabled = bool(_project_get("anti_cheat_toolkit/native_checks_enabled", true))
	s.native_check_interval_sec = float(_project_get("anti_cheat_toolkit/native_check_interval_sec", 10.0))
	s.report_send_enabled = bool(_project_get("anti_cheat_toolkit/report_send_enabled", false))
	s.report_endpoint = String(_project_get("anti_cheat_toolkit/report_endpoint", ""))
	s.log_path = String(_project_get("anti_cheat_toolkit/log_path", "user://anti_cheat_events.jsonl"))
	s.report_queue_path = String(_project_get("anti_cheat_toolkit/report_queue_path", "user://anti_cheat_report_queue.jsonl"))
	s.speed_hack_enabled = bool(_project_get("anti_cheat_toolkit/speed/enabled", true))
	s.speed_tolerance = float(_project_get("anti_cheat_toolkit/speed/tolerance", 0.25))
	s.speed_sample_window_sec = float(_project_get("anti_cheat_toolkit/speed/sample_window_sec", 4.0))
	s.time_check_enabled = bool(_project_get("anti_cheat_toolkit/time/enabled", true))
	s.max_wall_clock_drift_ms = int(_project_get("anti_cheat_toolkit/time/max_wall_clock_drift_ms", 3000))
	s.rollback_store_path = String(_project_get("anti_cheat_toolkit/save/rollback_store_path", "user://anti_cheat_rollback_store.json"))
	s.file_integrity_enabled = bool(_project_get("anti_cheat_toolkit/file_integrity/enabled", true))
	s.file_integrity_manifest_path = String(_project_get("anti_cheat_toolkit/file_integrity/manifest_path", s.file_integrity_manifest_path))
	s.file_integrity_manifest_secret = String(_project_get("anti_cheat_toolkit/file_integrity/manifest_secret", ""))
	s.monitored_files = PackedStringArray(_project_get("anti_cheat_toolkit/file_integrity/monitored_files", PackedStringArray()))
	s.device_fingerprint_opt_in = bool(_project_get("anti_cheat_toolkit/privacy/device_fingerprint_opt_in", false))
	s.device_fingerprint_salt = String(_project_get("anti_cheat_toolkit/privacy/device_fingerprint_salt", ""))
	s.include_hardware_id_in_fingerprint = bool(_project_get("anti_cheat_toolkit/privacy/include_hardware_id_in_fingerprint", false))
	s.install_id_path = String(_project_get("anti_cheat_toolkit/privacy/install_id_path", "user://anti_cheat_install_id"))
	s.include_native_paths = bool(_project_get("anti_cheat_toolkit/privacy/include_native_paths", false))
	s.suspicious_process_names = PackedStringArray(_project_get("anti_cheat_toolkit/native/suspicious_process_names", s.suspicious_process_names))
	s.allowed_module_names = PackedStringArray(_project_get("anti_cheat_toolkit/native/allowed_module_names", PackedStringArray()))
	return s


static func ensure_project_settings() -> void:
	_ensure("anti_cheat_toolkit/enabled", TYPE_BOOL, true)
	_ensure("anti_cheat_toolkit/auto_start", TYPE_BOOL, true)
	_ensure("anti_cheat_toolkit/developer_mode", TYPE_BOOL, OS.is_debug_build())
	_ensure("anti_cheat_toolkit/disable_in_development", TYPE_BOOL, true)
	_ensure("anti_cheat_toolkit/native_checks_enabled", TYPE_BOOL, true)
	_ensure("anti_cheat_toolkit/native_check_interval_sec", TYPE_FLOAT, 10.0)
	_ensure("anti_cheat_toolkit/report_send_enabled", TYPE_BOOL, false)
	_ensure("anti_cheat_toolkit/report_endpoint", TYPE_STRING, "")
	_ensure("anti_cheat_toolkit/log_path", TYPE_STRING, "user://anti_cheat_events.jsonl")
	_ensure("anti_cheat_toolkit/report_queue_path", TYPE_STRING, "user://anti_cheat_report_queue.jsonl")
	_ensure("anti_cheat_toolkit/save_secret", TYPE_STRING, "")
	_ensure("anti_cheat_toolkit/save/rollback_store_path", TYPE_STRING, "user://anti_cheat_rollback_store.json")
	_ensure("anti_cheat_toolkit/speed/enabled", TYPE_BOOL, true)
	_ensure("anti_cheat_toolkit/speed/tolerance", TYPE_FLOAT, 0.25)
	_ensure("anti_cheat_toolkit/speed/sample_window_sec", TYPE_FLOAT, 4.0)
	_ensure("anti_cheat_toolkit/time/enabled", TYPE_BOOL, true)
	_ensure("anti_cheat_toolkit/time/max_wall_clock_drift_ms", TYPE_INT, 3000)
	_ensure("anti_cheat_toolkit/file_integrity/enabled", TYPE_BOOL, true)
	_ensure("anti_cheat_toolkit/file_integrity/manifest_path", TYPE_STRING, "res://addons/anti_cheat_toolkit/integrity_manifest.json")
	_ensure("anti_cheat_toolkit/file_integrity/manifest_secret", TYPE_STRING, "")
	_ensure("anti_cheat_toolkit/file_integrity/monitored_files", TYPE_PACKED_STRING_ARRAY, PackedStringArray())
	_ensure("anti_cheat_toolkit/privacy/device_fingerprint_opt_in", TYPE_BOOL, false)
	_ensure("anti_cheat_toolkit/privacy/device_fingerprint_salt", TYPE_STRING, "")
	_ensure("anti_cheat_toolkit/privacy/include_hardware_id_in_fingerprint", TYPE_BOOL, false)
	_ensure("anti_cheat_toolkit/privacy/install_id_path", TYPE_STRING, "user://anti_cheat_install_id")
	_ensure("anti_cheat_toolkit/privacy/include_native_paths", TYPE_BOOL, false)
	_ensure("anti_cheat_toolkit/native/suspicious_process_names", TYPE_PACKED_STRING_ARRAY, PackedStringArray([
		"cheatengine",
		"cheatengine-x86_64",
		"x64dbg",
		"x32dbg",
		"ida",
		"ida64",
		"ollydbg",
		"processhacker"
	]))
	_ensure("anti_cheat_toolkit/native/allowed_module_names", TYPE_PACKED_STRING_ARRAY, PackedStringArray())


static func _ensure(name: String, type: int, default_value: Variant) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)
	ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.add_property_info({"name": name, "type": type})


static func _project_get(name: String, default_value: Variant) -> Variant:
	if ProjectSettings.has_setting(name):
		return ProjectSettings.get_setting(name)
	return default_value
