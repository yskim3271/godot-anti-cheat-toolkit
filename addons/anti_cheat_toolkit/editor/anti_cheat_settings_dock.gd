@tool
extends VBoxContainer

const ACTSettings := preload("res://addons/anti_cheat_toolkit/src/act_settings.gd")
const ACTFileIntegrity := preload("res://addons/anti_cheat_toolkit/src/integrity/act_file_integrity.gd")

var _status: Label

func _ready() -> void:
	name = "Anti-Cheat"
	ACTSettings.ensure_project_settings()

	var title := Label.new()
	title.text = "Anti-Cheat Toolkit"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)

	add_child(_checkbox("Enabled", "anti_cheat_toolkit/enabled", true))
	add_child(_checkbox("Auto start", "anti_cheat_toolkit/auto_start", true))
	add_child(_checkbox("Disable in development builds", "anti_cheat_toolkit/disable_in_development", true))
	add_child(_checkbox("Native checks", "anti_cheat_toolkit/native_checks_enabled", true))
	add_child(_checkbox("Speed checks", "anti_cheat_toolkit/speed/enabled", true))
	add_child(_checkbox("System time checks", "anti_cheat_toolkit/time/enabled", true))
	add_child(_checkbox("File integrity", "anti_cheat_toolkit/file_integrity/enabled", true))
	add_child(_checkbox("Report queue enabled", "anti_cheat_toolkit/report_send_enabled", false))
	add_child(_checkbox("Device fingerprint opt-in", "anti_cheat_toolkit/privacy/device_fingerprint_opt_in", false))
	add_child(_checkbox("Include native paths", "anti_cheat_toolkit/privacy/include_native_paths", false))
	add_child(_line_edit("Report endpoint", "anti_cheat_toolkit/report_endpoint", ""))
	add_child(_line_edit("Fingerprint salt", "anti_cheat_toolkit/privacy/device_fingerprint_salt", ""))
	add_child(_line_edit("Integrity manifest secret", "anti_cheat_toolkit/file_integrity/manifest_secret", ""))
	add_child(_string_array_edit("Suspicious process names", "anti_cheat_toolkit/native/suspicious_process_names", PackedStringArray()))
	add_child(_string_array_edit("Allowed module names", "anti_cheat_toolkit/native/allowed_module_names", PackedStringArray()))

	var manifest_button := Button.new()
	manifest_button.text = "Build Integrity Manifest"
	manifest_button.pressed.connect(_build_manifest)
	add_child(manifest_button)

	var docs_button := Button.new()
	docs_button.text = "Open Usage Docs"
	docs_button.pressed.connect(func(): OS.shell_open(ProjectSettings.globalize_path("res://docs/usage.md")))
	add_child(docs_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)


func _checkbox(label: String, setting: String, default_value: bool) -> CheckBox:
	var box := CheckBox.new()
	box.text = label
	box.button_pressed = bool(ProjectSettings.get_setting(setting, default_value))
	box.toggled.connect(func(value: bool): _set_setting(setting, value))
	return box


func _line_edit(label: String, setting: String, default_value: String) -> VBoxContainer:
	var container := VBoxContainer.new()
	var text_label := Label.new()
	text_label.text = label
	var edit := LineEdit.new()
	edit.text = String(ProjectSettings.get_setting(setting, default_value))
	edit.text_submitted.connect(func(value: String): _set_setting(setting, value))
	edit.focus_exited.connect(func(): _set_setting(setting, edit.text))
	container.add_child(text_label)
	container.add_child(edit)
	return container


func _string_array_edit(label: String, setting: String, default_value: PackedStringArray) -> VBoxContainer:
	var container := VBoxContainer.new()
	var text_label := Label.new()
	text_label.text = label
	var edit := LineEdit.new()
	var values := PackedStringArray(ProjectSettings.get_setting(setting, default_value))
	edit.text = ", ".join(values)
	edit.text_submitted.connect(func(value: String): _set_setting(setting, _csv_to_array(value)))
	edit.focus_exited.connect(func(): _set_setting(setting, _csv_to_array(edit.text)))
	container.add_child(text_label)
	container.add_child(edit)
	return container


func _set_setting(setting: String, value: Variant) -> void:
	ProjectSettings.set_setting(setting, value)
	ProjectSettings.save()
	if _status != null:
		_status.text = "Saved %s" % setting


func _csv_to_array(value: String) -> PackedStringArray:
	var out := PackedStringArray()
	for raw_part in value.split(",", false):
		var part := raw_part.strip_edges()
		if not part.is_empty():
			out.append(part)
	return out


func _build_manifest() -> void:
	var paths := PackedStringArray(ProjectSettings.get_setting("anti_cheat_toolkit/file_integrity/monitored_files", PackedStringArray()))
	var manifest_path := String(ProjectSettings.get_setting("anti_cheat_toolkit/file_integrity/manifest_path", "res://addons/anti_cheat_toolkit/integrity_manifest.json"))
	var secret_text := String(ProjectSettings.get_setting("anti_cheat_toolkit/file_integrity/manifest_secret", ""))
	var secret := PackedByteArray()
	if not secret_text.is_empty():
		secret = ACTFileIntegrity.secret_from_string(secret_text)
	var err := ACTFileIntegrity.build_manifest(paths, manifest_path, secret)
	if _status != null:
		_status.text = "Manifest written." if err == OK else "Manifest build failed: %s" % err
