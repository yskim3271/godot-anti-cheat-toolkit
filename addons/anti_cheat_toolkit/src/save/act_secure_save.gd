extends RefCounted
class_name ACTSecureSave

const ACTCrypto := preload("res://addons/anti_cheat_toolkit/src/crypto/act_crypto.gd")

const FORMAT := "godot_act_secure_save_v1"

static func secret_from_string(secret: String) -> PackedByteArray:
	return ACTCrypto.sha256_bytes(secret.to_utf8_buffer())


static func save_dict(path: String, data: Dictionary, secret: PackedByteArray, options: Dictionary = {}) -> int:
	if secret.is_empty():
		return ERR_INVALID_PARAMETER

	var save_id := String(options.get("save_id", path))
	var counter := int(options.get("counter", Time.get_unix_time_from_system()))
	var payload := var_to_bytes(data)
	var envelope := {
		"format": FORMAT,
		"save_id": save_id,
		"counter": str(counter),
		"created_unix": str(int(Time.get_unix_time_from_system())),
		"nonce": Marshalls.raw_to_base64(ACTCrypto.random_bytes(16)),
		"payload": Marshalls.raw_to_base64(payload),
		"metadata": Dictionary(options.get("metadata", {}))
	}
	envelope["mac"] = _mac_envelope(envelope, secret)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(envelope, "\t"))
	file.flush()
	file = null
	return OK


static func load_dict(path: String, secret: PackedByteArray, options: Dictionary = {}) -> Dictionary:
	if secret.is_empty():
		return {"ok": false, "error": ERR_INVALID_PARAMETER, "reason": "missing_secret", "data": {}}
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": ERR_FILE_NOT_FOUND, "reason": "missing_file", "data": {}}

	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": ERR_PARSE_ERROR, "reason": "invalid_json", "data": {}}

	var envelope := Dictionary(parsed)
	if String(envelope.get("format", "")) != FORMAT:
		return {"ok": false, "error": ERR_FILE_UNRECOGNIZED, "reason": "unsupported_format", "data": {}}

	var expected := _mac_envelope(envelope, secret)
	var actual := String(envelope.get("mac", ""))
	if not ACTCrypto.constant_time_equals(expected, actual):
		return {"ok": false, "error": ERR_FILE_CORRUPT, "reason": "mac_mismatch", "data": {}}

	var payload := Marshalls.base64_to_raw(String(envelope.get("payload", "")))
	var data: Variant = bytes_to_var(payload)
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "error": ERR_FILE_CORRUPT, "reason": "payload_not_dictionary", "data": {}}

	if bool(options.get("rollback_protection", true)):
		var rollback_result := check_rollback(
			String(envelope.get("save_id", path)),
			int(String(envelope.get("counter", "0"))),
			secret,
			String(options.get("rollback_store_path", "user://anti_cheat_rollback_store.json"))
		)
		if not bool(rollback_result.get("ok", false)):
			return {
				"ok": false,
				"error": ERR_FILE_CORRUPT,
				"reason": rollback_result.get("reason", "rollback_detected"),
				"data": Dictionary(data),
				"metadata": envelope.get("metadata", {})
			}

	return {
		"ok": true,
		"error": OK,
		"reason": "ok",
		"data": Dictionary(data),
		"metadata": envelope.get("metadata", {}),
		"counter": int(String(envelope.get("counter", "0")))
	}


static func check_rollback(save_id: String, counter: int, secret: PackedByteArray, store_path: String) -> Dictionary:
	var store := _read_rollback_store(store_path, secret)
	if bool(store.get("_corrupt", false)):
		return {"ok": false, "reason": "rollback_store_corrupt"}

	var counters := Dictionary(store.get("counters", {}))
	var high_water := int(String(counters.get(save_id, "-1")))
	if counter < high_water:
		return {"ok": false, "reason": "rollback_detected", "counter": counter, "high_water": high_water}

	if counter > high_water:
		counters[save_id] = str(counter)
		_write_rollback_store(store_path, counters, secret)
	return {"ok": true, "reason": "ok", "counter": counter, "high_water": high_water}


static func _mac_envelope(envelope: Dictionary, secret: PackedByteArray) -> String:
	var copy := envelope.duplicate(true)
	copy.erase("mac")
	var canonical := _canonical_json(copy)
	return ACTCrypto.hmac_sha256_hex(secret, canonical.to_utf8_buffer())


static func _canonical_json(value: Variant) -> String:
	return JSON.stringify(_canonical_value(value))


static func _canonical_value(value: Variant) -> Variant:
	if typeof(value) == TYPE_DICTIONARY:
		var out := {}
		var keys := Dictionary(value).keys()
		keys.sort()
		for key in keys:
			out[String(key)] = _canonical_value(Dictionary(value)[key])
		return out
	if typeof(value) == TYPE_ARRAY:
		var array := []
		for item in Array(value):
			array.append(_canonical_value(item))
		return array
	return value


static func _read_rollback_store(path: String, secret: PackedByteArray) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"counters": {}}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"_corrupt": true}
	var store := Dictionary(parsed)
	var expected := _mac_rollback_store(Dictionary(store.get("counters", {})), secret)
	if not ACTCrypto.constant_time_equals(expected, String(store.get("mac", ""))):
		return {"_corrupt": true}
	return store


static func _write_rollback_store(path: String, counters: Dictionary, secret: PackedByteArray) -> int:
	var store := {
		"format": "godot_act_rollback_store_v1",
		"counters": counters
	}
	store["mac"] = _mac_rollback_store(counters, secret)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(store, "\t"))
	file.flush()
	file = null
	return OK


static func _mac_rollback_store(counters: Dictionary, secret: PackedByteArray) -> String:
	return ACTCrypto.hmac_sha256_hex(secret, _canonical_json(counters).to_utf8_buffer())
