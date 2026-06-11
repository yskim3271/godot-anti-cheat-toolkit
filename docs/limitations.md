# Limitations and Known Issues

## Limitations

- Client-side anti-cheat can be bypassed by users who fully control their machine.
- In-memory value protection is obfuscation, not cryptographic secrecy.
- Local save signing depends on secret management. A secret embedded in the client can be extracted.
- Rollback protection is strongest when combined with a server-side high-water counter.
- Speed detection can be affected by suspend/resume, breakpoints, severe stalls, and VM timing behavior.
- System time detection is useful for offline abuse signals but should not replace server time.
- File integrity checks only cover configured files.
- Process-name matching is heuristic and can cause false positives.
- Module allow-listing can be noisy if configured too broadly.

## Known Issues

- Windows x86_64 native DLLs are included in this workspace. Other platforms are not supported by this distribution.
- The report queue persists JSONL payloads but does not automatically POST them.
- The editor dock exposes common settings only; advanced allow-list and process-list tuning is done through project settings or script.
- The example project uses a demo secret and must not be copied into production unchanged.
- Device fingerprint hashes are per-install by default and can change if the user deletes local app data.

## Recommended Production Pairing

- Server-authoritative currency, inventory, progression, and match results.
- Backend anomaly detection.
- Replay or input validation for competitive games.
- Clear privacy notice for any telemetry collection.
- Manual or staged enforcement instead of immediate bans.
