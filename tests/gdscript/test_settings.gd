extends SceneTree

const ACTSettings := preload("res://addons/anti_cheat_toolkit/src/act_settings.gd")

func _initialize() -> void:
	ProjectSettings.set_setting("anti_cheat_toolkit/native_check_interval_sec", 3.5)
	ProjectSettings.set_setting("anti_cheat_toolkit/log_path", "user://custom_events.jsonl")
	ProjectSettings.set_setting("anti_cheat_toolkit/report_queue_path", "user://custom_reports.jsonl")
	ProjectSettings.set_setting("anti_cheat_toolkit/save/rollback_store_path", "user://custom_rollback.json")
	ProjectSettings.set_setting("anti_cheat_toolkit/file_integrity/manifest_secret", "custom-manifest-secret")
	ProjectSettings.set_setting("anti_cheat_toolkit/native/suspicious_process_names", PackedStringArray(["tool_a", "tool_b"]))
	ProjectSettings.set_setting("anti_cheat_toolkit/native/allowed_module_names", PackedStringArray(["game.dll", "engine.dll"]))

	var settings = ACTSettings.from_project_settings()
	if abs(settings.native_check_interval_sec - 3.5) > 0.001:
		_fail("native interval did not load")
		return
	if settings.log_path != "user://custom_events.jsonl" or settings.report_queue_path != "user://custom_reports.jsonl":
		_fail("log/report paths did not load")
		return
	if settings.rollback_store_path != "user://custom_rollback.json":
		_fail("rollback store path did not load")
		return
	if settings.file_integrity_manifest_secret != "custom-manifest-secret":
		_fail("manifest secret did not load")
		return
	if settings.suspicious_process_names != PackedStringArray(["tool_a", "tool_b"]):
		_fail("suspicious process names did not load")
		return
	if settings.allowed_module_names != PackedStringArray(["game.dll", "engine.dll"]):
		_fail("allowed module names did not load")
		return
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
