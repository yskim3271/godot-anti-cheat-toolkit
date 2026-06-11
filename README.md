# Godot Anti-Cheat Toolkit

Client-side anti-cheat toolkit for Godot 4.x games targeting Windows.

This addon is a defensive layer, not a kernel-level anti-cheat. It is designed to make common client-side attacks harder and to produce structured detection events that can be logged or reported to a backend after review.

## Verified Godot Baseline

Checked on 2026-06-11:

- Current stable Godot download: Godot 4.6.3.
- Native extension baseline: GDExtension with `compatibility_minimum = "4.3"`.
- godot-cpp build target: `api_version=4.3` for wider 4.x minor compatibility. The godot-cpp README states that an extension targeting an earlier Godot minor should work in later minor versions, but not the reverse.

Primary development target: Godot 4.6.3, Windows x86_64.

## Features

- Obfuscated in-memory values with tamper checks.
- Signed save files with rollback high-water checks.
- Speed-hack drift monitoring using game delta and monotonic time.
- System clock manipulation detection.
- File integrity manifests and runtime verification.
- Native debugger detection.
- Native loaded module enumeration for DLL review.
- Native suspicious process enumeration.
- Structured JSONL event logging.
- Server-report queue preparation without automatic punishment.
- Opt-in hashed per-install device fingerprint for report correlation.
- Editor dock for common settings.
- Example Godot project and test scaffolding.

## Safety Boundaries

The toolkit does not bypass OS protections, hide processes, escalate privileges, terminate arbitrary processes, inspect unrelated user data, or enforce immediate bans. Default behavior is log/report oriented. Development and QA builds can disable or soften detections.

## Layout

- `addons/anti_cheat_toolkit/` - Godot addon.
- `native/` - GDExtension C++ native core.
- `example/` - Demo scene and script inside the root Godot project.
- `tests/` - Static and Godot-oriented tests.
- `docs/` - Security review, usage, build, and limitations.
- `scripts/` - Bootstrap and build helpers.

## Quick Start

1. Open this folder in Godot 4.6.3 or later.
2. Enable `Anti-Cheat Toolkit` in `Project > Project Settings > Plugins`.
3. Add or verify the `AntiCheat` autoload.
4. Run the example scene.

For native checks, build the GDExtension libraries first. See `docs/build_and_distribution.md`.

This workspace includes verified Windows x86_64 debug/release DLLs built from the sources in `native/`.
