#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

namespace godot {

class AntiCheatNative : public RefCounted {
	GDCLASS(AntiCheatNative, RefCounted)

protected:
	static void _bind_methods();

public:
	bool is_debugger_attached() const;
	Array get_loaded_modules(bool include_paths) const;
	Array find_suspicious_processes(const PackedStringArray &suspicious_names, bool include_paths) const;
	Dictionary get_runtime_report(
			const PackedStringArray &suspicious_names,
			const PackedStringArray &allowed_modules,
			bool include_paths) const;
	int64_t get_monotonic_time_usec() const;
	int64_t get_system_time_usec() const;
};

} // namespace godot

