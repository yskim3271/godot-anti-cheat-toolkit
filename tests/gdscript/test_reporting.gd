extends SceneTree

const ACTSettings := preload("res://addons/anti_cheat_toolkit/src/act_settings.gd")
const ACTDetectionLogger := preload("res://addons/anti_cheat_toolkit/src/reporting/act_detection_logger.gd")
const ACTReportQueue := preload("res://addons/anti_cheat_toolkit/src/reporting/act_report_queue.gd")

func _initialize() -> void:
	var stamp := str(Time.get_ticks_usec())
	var settings = ACTSettings.new()
	settings.include_native_paths = false
	settings.log_path = "user://act_events_%s.jsonl" % stamp
	settings.report_queue_path = "user://act_reports_%s.jsonl" % stamp
	settings.report_endpoint = "https://example.invalid/anti-cheat"

	var event := {
		"type": "native.suspicious_process",
		"severity": "medium",
		"details": {
			"path": "C:/Users/player/Tools/Cheat.exe",
			"nested": [{"module_path": "C:/Tools/overlay_hook.dll"}]
		}
	}

	var logger = ACTDetectionLogger.new()
	logger.configure(settings)
	var err := logger.log_event(event)
	if err != OK:
		_fail("log_event failed: %s" % err)
		return

	var raw_log := FileAccess.get_file_as_string(settings.log_path)
	if raw_log.contains("C:/Users/player") or raw_log.contains("C:/Tools/overlay_hook.dll"):
		_fail("logger leaked raw native path: %s" % raw_log)
		return

	var parsed: Variant = JSON.parse_string(raw_log.strip_edges())
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("logger wrote invalid JSON: %s" % raw_log)
		return

	var queue = ACTReportQueue.new()
	queue.configure(settings)
	queue.queue_event(event)
	if queue.pending_count() != 1:
		_fail("report queue did not retain queued event")
		return
	var payloads := queue.build_payloads()
	var payload := Dictionary(payloads[0])
	if payload.get("schema", "") != "godot_act_detection_event_v1" or payload.get("endpoint", "") != settings.report_endpoint:
		_fail("report payload shape mismatch: %s" % JSON.stringify(payload))
		return
	var payload_json := JSON.stringify(payload)
	if payload_json.contains("C:/Users/player") or payload_json.contains("C:/Tools/overlay_hook.dll"):
		_fail("report payload leaked raw native path: %s" % payload_json)
		return
	err = queue.persist()
	if err != OK or queue.pending_count() != 0:
		_fail("report queue persist failed: err=%s count=%s" % [err, queue.pending_count()])
		return
	var queue_file := FileAccess.get_file_as_string(settings.report_queue_path)
	if queue_file.is_empty():
		_fail("report queue file was empty")
		return
	if queue_file.contains("C:/Users/player") or queue_file.contains("C:/Tools/overlay_hook.dll"):
		_fail("report queue file leaked raw native path: %s" % queue_file)
		return

	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
