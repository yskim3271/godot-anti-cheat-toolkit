# Security Review

## Scope

This addon provides client-side hardening and telemetry for Godot games on Windows. It is not a kernel anti-cheat, DRM system, malware scanner, or authoritative security boundary.

## Threats Addressed

- Simple memory value scanning and replacement.
- Local save-file editing.
- Save rollback to replay rewards.
- Speed hacks that skew frame delta or timing APIs.
- System clock manipulation.
- Local game file tampering.
- Debugger attachment to the game process.
- Unexpected DLL loading signals.
- Suspicious tool processes by configured name list.

## Non-Goals

- Kernel drivers or privileged services.
- Undocumented OS behavior or security policy bypass.
- Stealth, concealment, rootkit behavior, anti-forensics, or process termination.
- Arbitrary memory scanning of other processes.
- Collection of personal files, browsing data, account data, or unrelated user data.
- Automatic bans as a default action.

## OS API Review

### Windows

The native extension uses documented user-mode APIs:

- `IsDebuggerPresent`
- `CheckRemoteDebuggerPresent`
- `CreateToolhelp32Snapshot`
- `Process32FirstW` / `Process32NextW`
- `Module32FirstW` / `Module32NextW`
- `OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION)`
- `QueryFullProcessImageNameW`

The extension only reads process metadata and the current process module list. It does not request debug privileges, inject code, write remote process memory, or terminate processes.

Static tests enforce this boundary by rejecting destructive, privilege-escalation, process-injection, remote-memory, and process-termination APIs. The only `OpenProcess` usage is constrained to `PROCESS_QUERY_LIMITED_INFORMATION`.

## Privacy

Default settings avoid full native paths in logs. When `include_native_paths=false`, path-like fields are replaced with hashes before writing JSONL events.

The same path hashing is applied to report queue payloads, so server-bound JSONL does not carry raw process/module paths unless `include_native_paths=true`.

Device fingerprinting is opt-in only through `device_fingerprint_opt_in`. When enabled, the toolkit logs only a SHA-256 hash. By default the hash uses an app salt, platform, and random per-install ID; hardware IDs are excluded unless `include_hardware_id_in_fingerprint` is explicitly enabled.

## False Positive Controls

- `disable_in_development` disables runtime detections in editor/debug builds.
- Speed and time monitors use tolerance windows.
- Suspicious process names are configurable.
- Module allow-list detection is disabled when no allow-list is configured.
- Events are logged/reported for review rather than punished immediately.
- Save rollback detection is based on a signed local high-water counter and can be disabled per load for migration or recovery workflows.

## Residual Risk

All client-side controls can be bypassed by an attacker who controls the device, process, filesystem, and runtime. Use this toolkit to raise cost and collect signals. For competitive or high-value games, pair it with server-authoritative state, replay validation, economy validation, and anomaly detection.

Unsigned file integrity manifests can be modified by an attacker who can change both the game file and manifest. Signed manifests improve local tamper evidence but do not create a true trust anchor if the secret is embedded in the client.
