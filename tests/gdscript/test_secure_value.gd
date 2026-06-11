extends SceneTree

const ACTSecureValue := preload("res://addons/anti_cheat_toolkit/src/memory/act_secure_value.gd")

func _initialize() -> void:
	var protected_value = ACTSecureValue.new(1234, "coins")
	if int(protected_value.get_value(0)) != 1234:
		_fail("secure value did not round trip")
		return

	protected_value._checksum = "tampered"
	if not protected_value.is_tampered():
		_fail("secure value tamper was not detected")
		return
	if int(protected_value.get_value(0)) != 0:
		_fail("tampered secure value did not return default")
		return
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

