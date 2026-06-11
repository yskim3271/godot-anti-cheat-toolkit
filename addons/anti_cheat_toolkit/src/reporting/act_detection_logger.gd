extends RefCounted
class_name ACTDetectionLogger

var _settings: Resource
var _log_path := "user://anti_cheat_events.jsonl"

func configure(settings: Resource) -> void:
	_settings = settings
	if settings != null:
		_log_path = settings.log_path


func log_event(event: Dictionary) -> int:
	var file := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(_log_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.seek_end()
	file.store_line(JSON.stringify(_sanitize(event)))
	return OK


func _sanitize(event: Dictionary) -> Dictionary:
	var copy := event.duplicate(true)
	if _settings == null or _settings.include_native_paths:
		return copy
	if copy.has("details") and copy["details"] is Dictionary:
		_scrub_paths(Dictionary(copy["details"]))
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
