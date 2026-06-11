extends RefCounted
class_name ACTDeviceIdentity

const ACTCrypto := preload("res://addons/anti_cheat_toolkit/src/crypto/act_crypto.gd")

static func get_fingerprint_hash(settings: Resource, options: Dictionary = {}) -> String:
	var opt_in := false
	if options.has("opt_in"):
		opt_in = bool(options["opt_in"])
	elif settings != null:
		opt_in = bool(settings.device_fingerprint_opt_in)
	if not opt_in:
		return ""

	var salt := String(options.get("salt", ""))
	if salt.is_empty() and settings != null:
		salt = String(settings.device_fingerprint_salt)
	if salt.is_empty():
		salt = String(ProjectSettings.get_setting("application/config/name", "godot_game"))

	var install_id_path := String(options.get("install_id_path", ""))
	if install_id_path.is_empty() and settings != null:
		install_id_path = String(settings.install_id_path)
	if install_id_path.is_empty():
		install_id_path = "user://anti_cheat_install_id"

	var parts := PackedStringArray([
		"godot_act_device_fingerprint_v1",
		salt,
		OS.get_name(),
		_get_or_create_install_id(install_id_path)
	])

	var include_hardware_id := bool(options.get("include_hardware_id", false))
	if settings != null:
		include_hardware_id = include_hardware_id or bool(settings.include_hardware_id_in_fingerprint)
	if include_hardware_id:
		parts.append(String(OS.get_unique_id()))

	return ACTCrypto.sha256_hex("|".join(parts).to_utf8_buffer())


static func _get_or_create_install_id(path: String) -> String:
	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path).strip_edges()
	var install_id := ACTCrypto.bytes_to_hex(ACTCrypto.random_bytes(16))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(install_id)
	return install_id

