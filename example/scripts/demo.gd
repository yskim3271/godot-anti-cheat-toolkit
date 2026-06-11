extends Control

const ACTSecureSave := preload("res://addons/anti_cheat_toolkit/src/save/act_secure_save.gd")

var _secure_coins
var _counter := 0
var _secret = ACTSecureSave.secret_from_string("demo-only-replace-with-server-secret")

@onready var _status: Label = $VBoxContainer/Status
@onready var _coins: Label = $VBoxContainer/Coins
@onready var _events: TextEdit = $VBoxContainer/Events

func _ready() -> void:
	AntiCheat.detection_event.connect(_on_detection_event)
	AntiCheat.start({"disable_in_development": false})
	_secure_coins = AntiCheat.create_secure_value(100, "demo_coins")
	_update_coins()

	$VBoxContainer/AddCoinsButton.pressed.connect(_add_coins)
	$VBoxContainer/SaveButton.pressed.connect(_write_save)
	$VBoxContainer/LoadButton.pressed.connect(_read_save)
	$VBoxContainer/IntegrityButton.pressed.connect(_verify_integrity)
	_status.text = "Running. Native available: %s" % AntiCheat.native_bridge.is_available()


func _add_coins() -> void:
	var value := int(AntiCheat.read_secure_value(_secure_coins, 0))
	_secure_coins.set_value(value + 10)
	_update_coins()


func _write_save() -> void:
	_counter += 1
	var err := AntiCheat.write_secure_save("user://demo_save.act", {"coins": AntiCheat.read_secure_value(_secure_coins, 0)}, {
		"secret": _secret,
		"save_id": "demo",
		"counter": _counter
	})
	_status.text = "Save result: %s" % err


func _read_save() -> void:
	var result := AntiCheat.read_secure_save("user://demo_save.act", {
		"secret": _secret,
		"save_id": "demo"
	})
	if bool(result.get("ok", false)):
		_secure_coins.set_value(int(Dictionary(result.get("data", {})).get("coins", 0)))
		_update_coins()
	_status.text = "Load result: %s" % result.get("reason", "unknown")


func _verify_integrity() -> void:
	var result := AntiCheat.verify_file_integrity()
	_status.text = "Integrity: %s" % result.get("reason", "unknown")


func _update_coins() -> void:
	_coins.text = "Coins: %s" % AntiCheat.read_secure_value(_secure_coins, 0)


func _on_detection_event(event: Dictionary) -> void:
	_events.text += JSON.stringify(event) + "\n"
