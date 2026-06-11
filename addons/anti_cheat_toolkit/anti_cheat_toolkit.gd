extends Node
class_name AntiCheatToolkit

const ACTSettings := preload("res://addons/anti_cheat_toolkit/src/act_settings.gd")
const ACTSecureValue := preload("res://addons/anti_cheat_toolkit/src/memory/act_secure_value.gd")
const ACTSecureSave := preload("res://addons/anti_cheat_toolkit/src/save/act_secure_save.gd")
const ACTNativeBridge := preload("res://addons/anti_cheat_toolkit/src/native/act_native_bridge.gd")
const ACTSpeedMonitor := preload("res://addons/anti_cheat_toolkit/src/monitors/act_speed_monitor.gd")
const ACTTimeMonitor := preload("res://addons/anti_cheat_toolkit/src/monitors/act_time_monitor.gd")
const ACTFileIntegrity := preload("res://addons/anti_cheat_toolkit/src/integrity/act_file_integrity.gd")
const ACTDetectionLogger := preload("res://addons/anti_cheat_toolkit/src/reporting/act_detection_logger.gd")
const ACTReportQueue := preload("res://addons/anti_cheat_toolkit/src/reporting/act_report_queue.gd")
const ACTDeviceIdentity := preload("res://addons/anti_cheat_toolkit/src/privacy/act_device_identity.gd")

signal detection_event(event: Dictionary)
signal report_queued(event: Dictionary)

var settings = ACTSettings.new()
var native_bridge = ACTNativeBridge.new()
var speed_monitor = ACTSpeedMonitor.new()
var time_monitor = ACTTimeMonitor.new()
var logger = ACTDetectionLogger.new()
var report_queue = ACTReportQueue.new()

var _running := false
var _session_id := ""
var _native_check_accum := 0.0
var _file_check_done := false

func _ready() -> void:
	settings = ACTSettings.from_project_settings()
	logger.configure(settings)
	report_queue.configure(settings)
	_session_id = _make_session_id()
	set_process(false)
	if settings.auto_start:
		start()


func start(overrides: Dictionary = {}) -> void:
	settings = ACTSettings.from_project_settings()
	settings.apply_overrides(overrides)
	logger.configure(settings)
	report_queue.configure(settings)

	if not settings.enabled:
		return
	if settings.disable_in_development and (OS.is_debug_build() or Engine.is_editor_hint()):
		record_event("toolkit.development_mode", "info", {"message": "Runtime detections are softened in development mode."})
		return

	native_bridge.configure(settings)
	speed_monitor.configure(settings, native_bridge)
	time_monitor.configure(settings, native_bridge)
	_native_check_accum = 0.0
	_file_check_done = false
	_running = true
	set_process(true)
	record_event("toolkit.started", "info", {"native_available": native_bridge.is_available()})


func stop() -> void:
	if not _running:
		return
	_running = false
	set_process(false)
	record_event("toolkit.stopped", "info", {})


func _process(delta: float) -> void:
	if not _running:
		return

	for event in speed_monitor.sample(delta, Engine.time_scale):
		_emit_detection(event)

	for event in time_monitor.sample():
		_emit_detection(event)

	_native_check_accum += delta
	if _native_check_accum >= settings.native_check_interval_sec:
		_native_check_accum = 0.0
		_run_native_checks()

	if not _file_check_done and settings.file_integrity_enabled:
		_file_check_done = true
		verify_file_integrity()


func create_secure_value(value: Variant, salt: String = ""):
	return ACTSecureValue.new(value, salt)


func read_secure_value(protected_value: Variant, default_value: Variant = null) -> Variant:
	if protected_value == null:
		return default_value
	if protected_value.is_tampered():
		record_event("memory.tamper", "high", {"reason": "secure_value_checksum_mismatch"})
		return default_value
	return protected_value.get_value(default_value)


func write_secure_save(path: String, data: Dictionary, options: Dictionary = {}) -> int:
	var secret := _get_save_secret(options)
	if secret.is_empty():
		record_event("save.configuration_error", "medium", {"reason": "missing_save_secret", "path": path})
		return ERR_INVALID_PARAMETER
	var result := ACTSecureSave.save_dict(path, data, secret, options)
	if result != OK:
		record_event("save.write_failed", "medium", {"path": path, "error": result})
	return result


func read_secure_save(path: String, options: Dictionary = {}) -> Dictionary:
	var secret := _get_save_secret(options)
	if secret.is_empty():
		var missing := {"ok": false, "error": ERR_INVALID_PARAMETER, "reason": "missing_save_secret", "data": {}}
		record_event("save.configuration_error", "medium", {"reason": "missing_save_secret", "path": path})
		return missing
	var result := ACTSecureSave.load_dict(path, secret, options)
	if not bool(result.get("ok", false)):
		record_event("save.validation_failed", "high", {
			"path": path,
			"reason": result.get("reason", "unknown"),
			"error": result.get("error", FAILED)
		})
	return result


func verify_file_integrity() -> Dictionary:
	if not settings.file_integrity_enabled:
		return {"ok": true, "skipped": true}
	var result := ACTFileIntegrity.verify_manifest(settings.file_integrity_manifest_path, _get_integrity_secret())
	if not bool(result.get("ok", false)):
		record_event("file.integrity_failed", "high", result)
	return result


func record_event(event_type: String, severity: String, details: Dictionary = {}) -> Dictionary:
	var event := {
		"type": event_type,
		"severity": severity,
		"timestamp_unix": int(Time.get_unix_time_from_system()),
		"monotonic_usec": native_bridge.get_monotonic_time_usec(),
		"session_id": _session_id,
		"platform": OS.get_name(),
		"details": details
	}
	var fingerprint_hash := get_device_fingerprint_hash()
	if not fingerprint_hash.is_empty():
		event["device_fingerprint_hash"] = fingerprint_hash
	logger.log_event(event)
	if settings.report_send_enabled:
		report_queue.queue_event(event)
		report_queued.emit(event)
	detection_event.emit(event)
	return event


func flush_report_queue() -> int:
	return report_queue.persist()


func get_device_fingerprint_hash(options: Dictionary = {}) -> String:
	return ACTDeviceIdentity.get_fingerprint_hash(settings, options)


func _emit_detection(event: Dictionary) -> void:
	record_event(String(event.get("type", "unknown")), String(event.get("severity", "medium")), Dictionary(event.get("details", {})))


func _run_native_checks() -> void:
	if not settings.native_checks_enabled or not native_bridge.is_available():
		return

	var report := native_bridge.get_runtime_report()
	if bool(report.get("debugger_attached", false)):
		record_event("native.debugger_attached", "high", {"source": report.get("debugger_source", "native")})

	for proc in Array(report.get("suspicious_processes", [])):
		record_event("native.suspicious_process", "medium", proc)

	for module in Array(report.get("unauthorized_modules", [])):
		record_event("native.unauthorized_module", "high", module)


func _get_save_secret(options: Dictionary) -> PackedByteArray:
	if options.has("secret") and options["secret"] is PackedByteArray:
		return options["secret"]
	var configured_secret := String(ProjectSettings.get_setting("anti_cheat_toolkit/save_secret", ""))
	if configured_secret.is_empty():
		return PackedByteArray()
	return ACTSecureSave.secret_from_string(configured_secret)


func _get_integrity_secret() -> PackedByteArray:
	if settings == null or String(settings.file_integrity_manifest_secret).is_empty():
		return PackedByteArray()
	return ACTFileIntegrity.secret_from_string(String(settings.file_integrity_manifest_secret))


func _make_session_id() -> String:
	var data := "%s:%s:%s" % [OS.get_name(), Time.get_ticks_usec(), randi()]
	return data.sha256_text().substr(0, 16)
