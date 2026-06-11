@tool
extends EditorPlugin

const AUTOLOAD_NAME := "AntiCheat"
const AUTOLOAD_PATH := "res://addons/anti_cheat_toolkit/anti_cheat_toolkit.gd"
const SettingsDock := preload("res://addons/anti_cheat_toolkit/editor/anti_cheat_settings_dock.gd")
const ACTSettings := preload("res://addons/anti_cheat_toolkit/src/act_settings.gd")

var _dock: Control

func _enter_tree() -> void:
	ACTSettings.ensure_project_settings()
	if not ProjectSettings.has_setting("autoload/%s" % AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

	_dock = SettingsDock.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null


func _disable_plugin() -> void:
	if ProjectSettings.has_setting("autoload/%s" % AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)

