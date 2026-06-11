extends RefCounted
class_name ACTReportQueue

var _settings: Resource
var _queue: Array = []
var _queue_path := "user://anti_cheat_report_queue.jsonl"

func configure(settings: Resource) -> void:
	_settings = settings
	if settings != null:
		_queue_path = settings.report_queue_path


func queue_event(event: Dictionary) -> void:
	_queue.append(_sanitize(event))


func pending_count() -> int:
	return _queue.size()


func persist() -> int:
	if _queue.is_empty():
		return OK
	var file := FileAccess.open(_queue_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(_queue_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.seek_end()
	for event in _queue:
		file.store_line(JSON.stringify(_build_payload(Dictionary(event))))
	_queue.clear()
	return OK


func build_payloads() -> Array:
	var out := []
	for event in _queue:
		out.append(_build_payload(Dictionary(event)))
	return out


func _build_payload(event: Dictionary) -> Dictionary:
	return {
		"schema": "godot_act_detection_event_v1",
		"endpoint": _settings.report_endpoint if _settings != null else "",
		"event": _sanitize(event)
	}


func _sanitize(event: Dictionary) -> Dictionary:
	var copy := event.duplicate(true)
	if _settings == null or _settings.include_native_paths:
		return copy
	if copy.has("details") and copy["details"] is Dictionary:
		_scrub_paths(copy["details"])
	return copy


func _scrub_paths(value: Variant) -> void:
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary := Dictionary(value)
		for key in dictionary.keys():
			if String(key).to_lower().contains("path"):
				dictionary[key] = String(dictionary[key]).sha256_text()
			else:
				_scrub_paths(dictionary[key])
	elif typeof(value) == TYPE_ARRAY:
		for item in Array(value):
			_scrub_paths(item)
