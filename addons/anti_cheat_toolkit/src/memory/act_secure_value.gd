extends RefCounted
class_name ACTSecureValue

const ACTCrypto := preload("res://addons/anti_cheat_toolkit/src/crypto/act_crypto.gd")

var _key := PackedByteArray()
var _encoded := PackedByteArray()
var _checksum := ""
var _salt := ""
var _plain_hash := ""

func _init(value: Variant = null, salt: String = "") -> void:
	_salt = salt
	set_value(value)


func set_value(value: Variant) -> void:
	var payload := var_to_bytes(value)
	_key = ACTCrypto.random_bytes(max(16, payload.size()))
	_encoded = ACTCrypto.xor_bytes(payload, _key)
	_plain_hash = ACTCrypto.sha256_hex(ACTCrypto.concat([payload, _salt.to_utf8_buffer()]))
	_checksum = _calculate_checksum()


func get_value(default_value: Variant = null) -> Variant:
	if is_tampered():
		return default_value
	var payload := ACTCrypto.xor_bytes(_encoded, _key)
	var decoded: Variant = bytes_to_var(payload)
	var decoded_hash := ACTCrypto.sha256_hex(ACTCrypto.concat([payload, _salt.to_utf8_buffer()]))
	if decoded_hash != _plain_hash:
		return default_value
	return decoded


func is_tampered() -> bool:
	if _key.is_empty() or _encoded.is_empty():
		return true
	return _checksum != _calculate_checksum()


func scrub() -> void:
	_key.clear()
	_encoded.clear()
	_checksum = ""
	_plain_hash = ""


func _calculate_checksum() -> String:
	return ACTCrypto.sha256_hex(ACTCrypto.concat([
		_key,
		_encoded,
		_salt.to_utf8_buffer(),
		_plain_hash.to_utf8_buffer()
	]))

