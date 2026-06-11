extends SceneTree

const ACTSettings := preload("res://addons/anti_cheat_toolkit/src/act_settings.gd")
const ACTDeviceIdentity := preload("res://addons/anti_cheat_toolkit/src/privacy/act_device_identity.gd")

func _initialize() -> void:
	var settings = ACTSettings.new()
	settings.device_fingerprint_opt_in = false
	settings.device_fingerprint_salt = "test-salt"
	settings.install_id_path = "user://act_test_install_id_%s" % Time.get_ticks_usec()

	var disabled_hash := ACTDeviceIdentity.get_fingerprint_hash(settings)
	if not disabled_hash.is_empty():
		_fail("fingerprint hash should be empty when opt-in is disabled")
		return

	settings.device_fingerprint_opt_in = true
	var first_hash := ACTDeviceIdentity.get_fingerprint_hash(settings)
	var second_hash := ACTDeviceIdentity.get_fingerprint_hash(settings)
	if first_hash.length() != 64:
		_fail("fingerprint hash should be 64 hex chars: %s" % first_hash)
		return
	if first_hash != second_hash:
		_fail("fingerprint hash should be stable for the same install ID")
		return
	if first_hash.contains(OS.get_unique_id()):
		_fail("fingerprint hash leaked the raw OS unique ID")
		return
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

