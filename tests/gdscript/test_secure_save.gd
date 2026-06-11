extends SceneTree

const ACTSecureSave := preload("res://addons/anti_cheat_toolkit/src/save/act_secure_save.gd")

func _initialize() -> void:
	var secret := ACTSecureSave.secret_from_string("test-secret")
	var path := "user://act_test_save.json"
	var store_path := "user://act_test_rollback_%s.json" % Time.get_ticks_usec()
	var err := ACTSecureSave.save_dict(path, {"coins": 10}, secret, {"save_id": "test", "counter": 1})
	if err != OK:
		_fail("save failed: %s" % err)
		return
	var loaded := ACTSecureSave.load_dict(path, secret, {"save_id": "test", "rollback_store_path": store_path})
	if not bool(loaded.get("ok", false)):
		_fail("load failed: %s" % JSON.stringify(loaded))
		return
	if int(Dictionary(loaded.get("data", {})).get("coins", 0)) != 10:
		_fail("loaded data mismatch: %s" % JSON.stringify(loaded))
		return

	err = ACTSecureSave.save_dict(path, {"coins": 20}, secret, {"save_id": "test", "counter": 2})
	if err != OK:
		_fail("save counter 2 failed: %s" % err)
		return
	loaded = ACTSecureSave.load_dict(path, secret, {"save_id": "test", "rollback_store_path": store_path})
	if not bool(loaded.get("ok", false)) or int(loaded.get("counter", 0)) != 2:
		_fail("counter 2 load failed: %s" % JSON.stringify(loaded))
		return

	err = ACTSecureSave.save_dict(path, {"coins": 15}, secret, {"save_id": "test", "counter": 1})
	if err != OK:
		_fail("rollback save failed: %s" % err)
		return
	loaded = ACTSecureSave.load_dict(path, secret, {"save_id": "test", "rollback_store_path": store_path})
	if bool(loaded.get("ok", true)) or String(loaded.get("reason", "")) != "rollback_detected":
		_fail("rollback was not detected: %s" % JSON.stringify(loaded))
		return

	err = ACTSecureSave.save_dict(path, {"coins": 30}, secret, {"save_id": "test", "counter": 3})
	if err != OK:
		_fail("tamper setup save failed: %s" % err)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var envelope := Dictionary(parsed)
	envelope["counter"] = "4"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(envelope, "\t"))
	file.flush()
	file = null
	loaded = ACTSecureSave.load_dict(path, secret, {"save_id": "test", "rollback_store_path": store_path})
	if bool(loaded.get("ok", true)) or String(loaded.get("reason", "")) != "mac_mismatch":
		_fail("tamper was not detected: %s" % JSON.stringify(loaded))
		return
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
