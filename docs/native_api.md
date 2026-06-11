# Native API

Class: `AntiCheatNative`

This class is registered by the GDExtension library when native binaries are present.

## Methods

### `is_debugger_attached() -> bool`

Returns whether the current process appears to have a debugger attached.

### `get_loaded_modules(include_paths: bool) -> Array`

Returns dictionaries for modules loaded in the current process.

When `include_paths=false`, only module names are returned. This is the recommended privacy-preserving default.

### `find_suspicious_processes(suspicious_names: PackedStringArray, include_paths: bool) -> Array`

Returns process metadata for process names matching configured suspicious names.

### `get_runtime_report(suspicious_names, allowed_modules, include_paths) -> Dictionary`

Combines debugger, process, and module checks into one report.

### `get_monotonic_time_usec() -> int`

Returns native monotonic time in microseconds.

### `get_system_time_usec() -> int`

Returns native system time in microseconds since Unix epoch.

