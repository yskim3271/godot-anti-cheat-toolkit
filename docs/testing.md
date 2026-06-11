# Testing

## Static Tests

```powershell
./tests/run_static.ps1
```

These tests verify project layout, manifest JSON, GDExtension paths, documented baseline, CI wiring, and native security boundaries that forbid destructive or injection-related APIs.

## Godot Headless Test

Install Godot 4.6.3 or newer and run:

```powershell
./tests/run_godot_tests.ps1 -Godot "C:/path/to/Godot_v4.6.3-stable_win64.exe"
```

The Godot tests cover:

- Secure save write/read and HMAC validation path setup.
- Secure save tamper detection and signed rollback high-water checks.
- Secure value round-trip and tamper detection.
- Opt-in hashed device identity behavior.
- ProjectSettings loading for native scan interval, log/report paths, rollback store path, suspicious process names, and module allow-list.
- File integrity manifest build, modification detection, missing-file detection, and signed manifest tamper detection.
- Speed drift, wall-clock drift, and clock rollback monitor behavior using deterministic fake clocks.
- Event logger and report queue JSONL output, including native path hashing when path collection is disabled.
- Native bridge class registration, loaded module enumeration, no-path module privacy, suspicious process negative matching, and strict module allow-list unauthorized-module reporting when native libraries are present.

## Manual Security Test Matrix

- Attach a debugger to a release build and confirm a `native.debugger_attached` event.
- Run a configured suspicious process name and confirm `native.suspicious_process`.
- Modify `user://demo_save.act` and confirm `save.validation_failed`.
- Restore an older save counter and confirm rollback detection.
- Modify a manifest-covered file and confirm `file.integrity_failed`.
- Change system time backwards and confirm `time.clock_moved_back`.
- Artificially skew game delta and confirm `speed.drift`.
