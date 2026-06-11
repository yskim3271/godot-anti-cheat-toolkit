#include "anti_cheat_native.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>

#include <algorithm>
#include <chrono>
#include <cctype>
#include <cstdint>
#include <string>

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <tlhelp32.h>
#endif

namespace godot {
namespace {

std::string to_std_string(const String &value) {
	CharString utf8 = value.utf8();
	return std::string(utf8.get_data());
}

std::string to_lower_ascii(std::string value) {
	std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
		return static_cast<char>(std::tolower(c));
	});
	return value;
}

std::string basename_lower(const std::string &path) {
	size_t slash = path.find_last_of("/\\");
	std::string name = slash == std::string::npos ? path : path.substr(slash + 1);
	size_t dot = name.find_last_of('.');
	if (dot != std::string::npos) {
		std::string ext = to_lower_ascii(name.substr(dot));
		if (ext == ".exe" || ext == ".dll") {
			name = name.substr(0, dot);
		}
	}
	return to_lower_ascii(name);
}

bool contains_suspicious_name(const std::string &process_name, const PackedStringArray &needles) {
	const std::string normalized_process = basename_lower(process_name);
	for (int i = 0; i < needles.size(); ++i) {
		const std::string needle = basename_lower(to_std_string(needles[i]));
		if (!needle.empty() && normalized_process.find(needle) != std::string::npos) {
			return true;
		}
	}
	return false;
}

bool is_allowed_module(const std::string &module_name, const PackedStringArray &allowed_modules) {
	if (allowed_modules.is_empty()) {
		return true;
	}
	const std::string normalized = basename_lower(module_name);
	for (int i = 0; i < allowed_modules.size(); ++i) {
		if (normalized == basename_lower(to_std_string(allowed_modules[i]))) {
			return true;
		}
	}
	return false;
}

#ifdef _WIN32
String from_wide(const wchar_t *value) {
	return String(value);
}
#endif

} // namespace

void AntiCheatNative::_bind_methods() {
	ClassDB::bind_method(D_METHOD("is_debugger_attached"), &AntiCheatNative::is_debugger_attached);
	ClassDB::bind_method(D_METHOD("get_loaded_modules", "include_paths"), &AntiCheatNative::get_loaded_modules);
	ClassDB::bind_method(D_METHOD("find_suspicious_processes", "suspicious_names", "include_paths"), &AntiCheatNative::find_suspicious_processes);
	ClassDB::bind_method(D_METHOD("get_runtime_report", "suspicious_names", "allowed_modules", "include_paths"), &AntiCheatNative::get_runtime_report);
	ClassDB::bind_method(D_METHOD("get_monotonic_time_usec"), &AntiCheatNative::get_monotonic_time_usec);
	ClassDB::bind_method(D_METHOD("get_system_time_usec"), &AntiCheatNative::get_system_time_usec);
}

bool AntiCheatNative::is_debugger_attached() const {
#ifdef _WIN32
	if (IsDebuggerPresent()) {
		return true;
	}
	BOOL remote_debugger = FALSE;
	CheckRemoteDebuggerPresent(GetCurrentProcess(), &remote_debugger);
	return remote_debugger == TRUE;
#else
	return false;
#endif
}

Array AntiCheatNative::get_loaded_modules(bool include_paths) const {
	Array modules;
#ifdef _WIN32
	const DWORD pid = GetCurrentProcessId();
	HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, pid);
	if (snapshot == INVALID_HANDLE_VALUE) {
		return modules;
	}
	MODULEENTRY32W entry {};
	entry.dwSize = sizeof(entry);
	if (Module32FirstW(snapshot, &entry)) {
		do {
			Dictionary item;
			item["name"] = from_wide(entry.szModule);
			if (include_paths) {
				item["path"] = from_wide(entry.szExePath);
			}
			modules.append(item);
		} while (Module32NextW(snapshot, &entry));
	}
	CloseHandle(snapshot);
#endif
	return modules;
}

Array AntiCheatNative::find_suspicious_processes(const PackedStringArray &suspicious_names, bool include_paths) const {
	Array findings;
	if (suspicious_names.is_empty()) {
		return findings;
	}
#ifdef _WIN32
	HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	if (snapshot == INVALID_HANDLE_VALUE) {
		return findings;
	}
	PROCESSENTRY32W entry {};
	entry.dwSize = sizeof(entry);
	if (Process32FirstW(snapshot, &entry)) {
		do {
			const String process_name = from_wide(entry.szExeFile);
			if (!contains_suspicious_name(to_std_string(process_name), suspicious_names)) {
				continue;
			}
			Dictionary item;
			item["pid"] = static_cast<int64_t>(entry.th32ProcessID);
			item["name"] = process_name;
			if (include_paths) {
				HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, entry.th32ProcessID);
				if (process != nullptr) {
					wchar_t path[MAX_PATH] {};
					DWORD path_size = MAX_PATH;
					if (QueryFullProcessImageNameW(process, 0, path, &path_size)) {
						item["path"] = from_wide(path);
					}
					CloseHandle(process);
				}
			}
			findings.append(item);
		} while (Process32NextW(snapshot, &entry));
	}
	CloseHandle(snapshot);
#endif
	return findings;
}

Dictionary AntiCheatNative::get_runtime_report(
		const PackedStringArray &suspicious_names,
		const PackedStringArray &allowed_modules,
		bool include_paths) const {
	Dictionary report;
	report["native_available"] = true;
	report["debugger_attached"] = is_debugger_attached();
	report["debugger_source"] = "documented_os_api";
	report["suspicious_processes"] = find_suspicious_processes(suspicious_names, include_paths);

	Array modules = get_loaded_modules(include_paths);
	Array unauthorized;
	for (int i = 0; i < modules.size(); ++i) {
		Dictionary module = modules[i];
		const std::string name = to_std_string(String(module.get("name", "")));
		if (!is_allowed_module(name, allowed_modules)) {
			Dictionary item;
			item["name"] = module.get("name", "");
			if (include_paths && module.has("path")) {
				item["path"] = module["path"];
			}
			unauthorized.append(item);
		}
	}
	report["loaded_module_count"] = modules.size();
	report["unauthorized_modules"] = unauthorized;
	return report;
}

int64_t AntiCheatNative::get_monotonic_time_usec() const {
	const auto now = std::chrono::steady_clock::now().time_since_epoch();
	return std::chrono::duration_cast<std::chrono::microseconds>(now).count();
}

int64_t AntiCheatNative::get_system_time_usec() const {
	const auto now = std::chrono::system_clock::now().time_since_epoch();
	return std::chrono::duration_cast<std::chrono::microseconds>(now).count();
}

} // namespace godot
