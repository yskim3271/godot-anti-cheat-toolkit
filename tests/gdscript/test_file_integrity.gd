extends SceneTree

const ACTFileIntegrity := preload("res://addons/anti_cheat_toolkit/src/integrity/act_file_integrity.gd")

func _initialize() -> void:
	var stamp := str(Time.get_ticks_usec())
	var file_path := "user://act_integrity_%s.txt" % stamp
	var manifest_path := "user://act_integrity_manifest_%s.json" % stamp

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		_fail("failed to create integrity test file")
		return
	file.store_string("original")
	file = null

	var err := ACTFileIntegrity.build_manifest(PackedStringArray([file_path]), manifest_path)
	if err != OK:
		_fail("manifest build failed: %s" % err)
		return

	var ok_result := ACTFileIntegrity.verify_manifest(manifest_path)
	if not bool(ok_result.get("ok", false)):
		_fail("manifest should verify before modification: %s" % JSON.stringify(ok_result))
		return

	file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string("modified")
	file = null
	var changed_result := ACTFileIntegrity.verify_manifest(manifest_path)
	if bool(changed_result.get("ok", true)) or Array(changed_result.get("changed", [])).is_empty():
		_fail("manifest should detect modified file: %s" % JSON.stringify(changed_result))
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path))
	var missing_result := ACTFileIntegrity.verify_manifest(manifest_path)
	if bool(missing_result.get("ok", true)) or Array(missing_result.get("missing", [])).is_empty():
		_fail("manifest should detect missing file: %s" % JSON.stringify(missing_result))
		return

	var signed_file_path := "user://act_integrity_signed_%s.txt" % stamp
	var signed_manifest_path := "user://act_integrity_signed_manifest_%s.json" % stamp
	var secret := ACTFileIntegrity.secret_from_string("manifest-test-secret")
	file = FileAccess.open(signed_file_path, FileAccess.WRITE)
	file.store_string("signed-original")
	file.flush()
	file = null
	err = ACTFileIntegrity.build_manifest(PackedStringArray([signed_file_path]), signed_manifest_path, secret)
	if err != OK:
		_fail("signed manifest build failed: %s" % err)
		return
	var signed_ok := ACTFileIntegrity.verify_manifest(signed_manifest_path, secret)
	if not bool(signed_ok.get("ok", false)):
		_fail("signed manifest should verify: %s" % JSON.stringify(signed_ok))
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(signed_manifest_path))
	var manifest := Dictionary(parsed)
	var entries := Array(manifest.get("entries", []))
	var first_entry := Dictionary(entries[0])
	first_entry["sha256"] = "0000000000000000000000000000000000000000000000000000000000000000"
	entries[0] = first_entry
	manifest["entries"] = entries
	file = FileAccess.open(signed_manifest_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.flush()
	file = null
	var signed_tampered := ACTFileIntegrity.verify_manifest(signed_manifest_path, secret)
	if bool(signed_tampered.get("ok", true)) or String(signed_tampered.get("reason", "")) != "manifest_mac_mismatch":
		_fail("signed manifest tamper should be detected: %s" % JSON.stringify(signed_tampered))
		return

	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
