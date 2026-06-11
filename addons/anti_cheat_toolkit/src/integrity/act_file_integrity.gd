extends RefCounted
class_name ACTFileIntegrity

const ACTCrypto := preload("res://addons/anti_cheat_toolkit/src/crypto/act_crypto.gd")

const FORMAT := "godot_act_integrity_manifest_v1"

static func secret_from_string(secret: String) -> PackedByteArray:
	return ACTCrypto.sha256_bytes(secret.to_utf8_buffer())


static func build_manifest(paths: PackedStringArray, manifest_path: String, secret: PackedByteArray = PackedByteArray()) -> int:
	var entries := []
	for path in paths:
		if FileAccess.file_exists(path):
			entries.append(_entry_for_file(path))
		elif DirAccess.open(path) != null:
			for file_path in _files_in_dir(path):
				entries.append(_entry_for_file(file_path))

	var manifest := {
		"format": FORMAT,
		"created_unix": str(int(Time.get_unix_time_from_system())),
		"entries": entries
	}
	if not secret.is_empty():
		manifest["mac"] = _mac_manifest(manifest, secret)
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(manifest, "\t"))
	file.flush()
	file = null
	return OK


static func verify_manifest(manifest_path: String, secret: PackedByteArray = PackedByteArray()) -> Dictionary:
	if not FileAccess.file_exists(manifest_path):
		return {"ok": false, "reason": "missing_manifest", "manifest_path": manifest_path}

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "invalid_manifest_json", "manifest_path": manifest_path}
	var manifest := Dictionary(parsed)
	if String(manifest.get("format", "")) != FORMAT:
		return {"ok": false, "reason": "unsupported_manifest", "manifest_path": manifest_path}

	if manifest.has("mac") or not secret.is_empty():
		if secret.is_empty():
			return {"ok": false, "reason": "missing_manifest_secret", "manifest_path": manifest_path}
		var actual_mac := String(manifest.get("mac", ""))
		if actual_mac.is_empty():
			return {"ok": false, "reason": "unsigned_manifest", "manifest_path": manifest_path}
		var expected_mac := _mac_manifest(manifest, secret)
		if not ACTCrypto.constant_time_equals(expected_mac, actual_mac):
			return {"ok": false, "reason": "manifest_mac_mismatch", "manifest_path": manifest_path}

	var changed := []
	var missing := []
	for raw_entry in Array(manifest.get("entries", [])):
		var entry := Dictionary(raw_entry)
		var path := String(entry.get("path", ""))
		if not FileAccess.file_exists(path):
			missing.append(path)
			continue
		var current := _entry_for_file(path)
		if current.get("sha256", "") != entry.get("sha256", "") or String(current.get("size", "")) != String(entry.get("size", "")):
			changed.append({"path": path, "expected": entry, "actual": current})

	return {
		"ok": changed.is_empty() and missing.is_empty(),
		"reason": "ok" if changed.is_empty() and missing.is_empty() else "integrity_mismatch",
		"changed": changed,
		"missing": missing,
		"manifest_path": manifest_path
	}


static func _entry_for_file(path: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(path)
	return {"path": path, "size": str(bytes.size()), "sha256": ACTCrypto.sha256_hex(bytes)}


static func _files_in_dir(root: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name == "." or name == "..":
			name = dir.get_next()
			continue
		var path := root.path_join(name)
		if dir.current_is_dir():
			out.append_array(_files_in_dir(path))
		else:
			out.append(path)
		name = dir.get_next()
	dir.list_dir_end()
	return out


static func _mac_manifest(manifest: Dictionary, secret: PackedByteArray) -> String:
	var copy := manifest.duplicate(true)
	copy.erase("mac")
	return ACTCrypto.hmac_sha256_hex(secret, _canonical_json(copy).to_utf8_buffer())


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
