extends RefCounted
class_name ACTCrypto

const HMAC_BLOCK_SIZE := 64

static func random_bytes(size: int) -> PackedByteArray:
	var crypto := Crypto.new()
	return crypto.generate_random_bytes(size)


static func sha256_bytes(data: PackedByteArray) -> PackedByteArray:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	if not data.is_empty():
		ctx.update(data)
	return ctx.finish()


static func sha256_hex(data: PackedByteArray) -> String:
	return bytes_to_hex(sha256_bytes(data))


static func hmac_sha256(key: PackedByteArray, message: PackedByteArray) -> PackedByteArray:
	var normalized_key := key.duplicate()
	if normalized_key.size() > HMAC_BLOCK_SIZE:
		normalized_key = sha256_bytes(normalized_key)
	while normalized_key.size() < HMAC_BLOCK_SIZE:
		normalized_key.append(0)

	var ipad := PackedByteArray()
	var opad := PackedByteArray()
	for byte in normalized_key:
		ipad.append(byte ^ 0x36)
		opad.append(byte ^ 0x5c)

	var inner := concat([ipad, message])
	return sha256_bytes(concat([opad, sha256_bytes(inner)]))


static func hmac_sha256_hex(key: PackedByteArray, message: PackedByteArray) -> String:
	return bytes_to_hex(hmac_sha256(key, message))


static func constant_time_equals(a: String, b: String) -> bool:
	var ab := a.to_utf8_buffer()
	var bb := b.to_utf8_buffer()
	if ab.size() != bb.size():
		return false
	var diff := 0
	for i in ab.size():
		diff |= ab[i] ^ bb[i]
	return diff == 0


static func xor_bytes(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	if key.is_empty():
		return data.duplicate()
	for i in data.size():
		out.append(data[i] ^ key[i % key.size()])
	return out


static func concat(parts: Array) -> PackedByteArray:
	var out := PackedByteArray()
	for part in parts:
		var bytes: PackedByteArray = part
		out.append_array(bytes)
	return out


static func bytes_to_hex(bytes: PackedByteArray) -> String:
	var text := ""
	for byte in bytes:
		text += "%02x" % byte
	return text
