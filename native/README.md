# Native GDExtension Core

The native core exposes documented OS checks to GDScript through `AntiCheatNative`.

Implemented checks:

- Windows: `IsDebuggerPresent`, `CheckRemoteDebuggerPresent`, Toolhelp process/module snapshots, optional `QueryFullProcessImageNameW`.
- Cross-platform monotonic/system time wrappers using C++ `std::chrono`.

The extension never terminates processes, injects code, escalates privileges, hides itself, scans arbitrary memory, or bypasses OS security policy.

Build outputs are expected under `addons/anti_cheat_toolkit/bin/` and are referenced by `anti_cheat_native.gdextension`.
