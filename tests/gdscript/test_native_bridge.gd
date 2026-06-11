extends SceneTree

func _initialize() -> void:
	if OS.get_name() == "Windows" and not ClassDB.class_exists("AntiCheatNative"):
		_fail("AntiCheatNative class is not registered on %s." % OS.get_name())
		return
	if ClassDB.class_exists("AntiCheatNative"):
		var native = ClassDB.instantiate("AntiCheatNative")
		var report: Dictionary = Dictionary(native.call("get_runtime_report", PackedStringArray(), PackedStringArray(), false))
		if not bool(report.get("native_available", false)):
			_fail("Native report did not mark native_available=true: %s" % JSON.stringify(report))
			return
		if typeof(report.get("debugger_attached", null)) != TYPE_BOOL:
			_fail("Native report debugger field is not a bool: %s" % JSON.stringify(report))
			return
		if int(report.get("loaded_module_count", 0)) <= 0:
			_fail("Native report did not enumerate loaded modules: %s" % JSON.stringify(report))
			return
		if not Array(report.get("unauthorized_modules", [])).is_empty():
			_fail("Empty module allow-list should not report unauthorized modules: %s" % JSON.stringify(report))
			return
		for module in Array(native.call("get_loaded_modules", false)):
			if Dictionary(module).has("path"):
				_fail("Native module report included paths while include_paths=false: %s" % JSON.stringify(module))
				return

		var strict_report: Dictionary = Dictionary(native.call(
			"get_runtime_report",
			PackedStringArray(["process_name_that_should_not_exist_act_test"]),
			PackedStringArray(["module_name_that_should_not_exist_act_test"]),
			false
		))
		if Array(strict_report.get("suspicious_processes", [])).size() != 0:
			_fail("Impossible suspicious process name matched unexpectedly: %s" % JSON.stringify(strict_report))
			return
		var unauthorized := Array(strict_report.get("unauthorized_modules", []))
		if unauthorized.is_empty():
			_fail("Strict module allow-list should report unauthorized modules: %s" % JSON.stringify(strict_report))
			return
		for module in unauthorized:
			if Dictionary(module).has("path"):
				_fail("Unauthorized module report included paths while include_paths=false: %s" % JSON.stringify(module))
				return
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
