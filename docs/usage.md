# Anti-Cheat Toolkit Usage

## Runtime Singleton

Enable the addon in Godot and use the autoload singleton:

```gdscript
AntiCheat.start()
AntiCheat.detection_event.connect(_on_detection_event)
```

Default behavior is logging. Report queueing is disabled unless `anti_cheat_toolkit/report_send_enabled` is set.

## Secure Values

Use secure values for client-side counters such as soft currency, cooldowns, or local-only progression values.

```gdscript
var coins := AntiCheat.create_secure_value(100, "coins")
coins.set_value(125)
var value := AntiCheat.read_secure_value(coins, 0)
```

This is obfuscation plus integrity checking. A determined attacker with full process control can still reverse it, so authoritative values should remain server-side.

## Secure Saves

Save dictionaries with HMAC protection and rollback counters:

```gdscript
var secret := ACTSecureSave.secret_from_string("replace-with-server-or-build-secret")
AntiCheat.write_secure_save("user://save.act", {"coins": 10}, {
    "secret": secret,
    "save_id": "slot_1",
    "counter": 42
})
```

Load and validate:

```gdscript
var result := AntiCheat.read_secure_save("user://save.act", {
    "secret": secret,
    "save_id": "slot_1"
})
if result.ok:
    var data := result.data
```

Rollback protection stores a signed high-water counter in `user://anti_cheat_rollback_store.json`. If an attacker rolls back both the save and high-water store, detection can be bypassed; server-side counters are stronger.

Configure the rollback store path with `anti_cheat_toolkit/save/rollback_store_path`.

## Speed Hack Detection

The speed monitor compares game delta over a window against monotonic elapsed time. Configure:

- `anti_cheat_toolkit/speed/enabled`
- `anti_cheat_toolkit/speed/tolerance`
- `anti_cheat_toolkit/speed/sample_window_sec`

False positives are possible during heavy stalls, backgrounding, suspend/resume, or extreme frame pacing issues. Treat events as signals, not automatic ban decisions.

## System Time Detection

The time monitor compares wall-clock movement against monotonic time and detects large clock jumps or backwards movement.

Configure:

- `anti_cheat_toolkit/time/enabled`
- `anti_cheat_toolkit/time/max_wall_clock_drift_ms`

Use this to harden offline timers, daily rewards, and cooldowns. For high-value rewards, verify time server-side.

## File Integrity

Create a manifest from the editor dock or script:

```gdscript
ACTFileIntegrity.build_manifest(PackedStringArray([
    "res://game/scripts/player.gd",
    "res://game/balance/items.json"
]), "res://addons/anti_cheat_toolkit/integrity_manifest.json")
```

For stronger local tamper evidence, sign the manifest with a build/runtime secret:

```gdscript
var secret := ACTFileIntegrity.secret_from_string("replace-with-build-secret")
ACTFileIntegrity.build_manifest(files, manifest_path, secret)
ACTFileIntegrity.verify_manifest(manifest_path, secret)
```

Verify at runtime:

```gdscript
var result := AntiCheat.verify_file_integrity()
```

Do not include files that are expected to change at runtime. For exported games, build the manifest after final import/export-sensitive assets are stable.

Configure `anti_cheat_toolkit/file_integrity/manifest_secret` to make `AntiCheat.verify_file_integrity()` require a signed manifest. A client-embedded secret can still be extracted, so server-side or launcher-side integrity checks are stronger for high-value games.

## Native Checks

When the native GDExtension library is present, `AntiCheatNative` adds:

- Current process debugger detection.
- Current process loaded module enumeration.
- Suspicious process name matching.
- Monotonic/system time from native C++.

The native bridge is optional. The addon keeps running without it, but native-only detections are skipped.

Tune native checks with:

- `anti_cheat_toolkit/native_check_interval_sec`
- `anti_cheat_toolkit/native/suspicious_process_names`
- `anti_cheat_toolkit/native/allowed_module_names`
- `anti_cheat_toolkit/privacy/include_native_paths`

## Detection Events

Events are dictionaries with this shape:

```json
{
  "type": "native.debugger_attached",
  "severity": "high",
  "timestamp_unix": 1781130000,
  "monotonic_usec": 123456789,
  "session_id": "short-hash",
  "platform": "Windows",
  "details": {}
}
```

Events are appended to `user://anti_cheat_events.jsonl`. If reporting is enabled, events are queued as JSONL payloads for a backend uploader.

When `anti_cheat_toolkit/privacy/include_native_paths=false`, path-like fields in event details are hashed before they are written to logs or report queue payloads.

## Device Fingerprint Hash

Device fingerprinting is disabled by default. When `anti_cheat_toolkit/privacy/device_fingerprint_opt_in=true`, events include `device_fingerprint_hash`.

The hash is built from an app salt, platform, and a random per-install ID stored under `user://anti_cheat_install_id`. Hardware IDs are excluded by default; `include_hardware_id_in_fingerprint` must be explicitly enabled to add Godot's `OS.get_unique_id()` to the hash input. Raw identifiers are never logged by the toolkit.

## Development and QA

Keep `anti_cheat_toolkit/disable_in_development=true` for normal editor and QA use. Enable checks explicitly when testing the anti-cheat itself.
