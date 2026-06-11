from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
SCAN_ROOTS = [
    ROOT / "native" / "src",
    ROOT / "addons" / "anti_cheat_toolkit",
]


class SecurityBoundaryTests(unittest.TestCase):
    def _source_text(self) -> str:
        parts = []
        for root in SCAN_ROOTS:
            for path in root.rglob("*"):
                if path.suffix.lower() in {".cpp", ".h", ".gd"}:
                    parts.append(path.read_text(encoding="utf-8", errors="ignore"))
        return "\n".join(parts)

    def test_no_destructive_or_injection_apis(self):
        text = self._source_text()
        forbidden_patterns = [
            r"\bTerminateProcess\s*\(",
            r"\bCreateRemoteThread\s*\(",
            r"\bWriteProcessMemory\s*\(",
            r"\bReadProcessMemory\s*\(",
            r"\bVirtualAllocEx\s*\(",
            r"\bVirtualProtectEx\s*\(",
            r"\bSetWindowsHookEx\s*\(",
            r"\bAdjustTokenPrivileges\s*\(",
            r"\bOpenProcessToken\s*\(",
            r"\bSeDebugPrivilege\b",
            r"\bDebugActiveProcess\s*\(",
            r"\bptrace\s*\(",
            r"\btask_for_pid\s*\(",
            r"\bkill\s*\(",
            r"\bsystem\s*\(",
        ]
        for pattern in forbidden_patterns:
            self.assertIsNone(re.search(pattern, text), pattern)

    def test_open_process_is_query_only(self):
        text = self._source_text()
        calls = re.findall(r"OpenProcess\s*\(([^;]+?)\)", text, flags=re.DOTALL)
        for call in calls:
            self.assertIn("PROCESS_QUERY_LIMITED_INFORMATION", call)
            self.assertNotIn("PROCESS_ALL_ACCESS", call)
            self.assertNotIn("PROCESS_VM_WRITE", call)
            self.assertNotIn("PROCESS_VM_READ", call)
            self.assertNotIn("PROCESS_VM_OPERATION", call)
            self.assertNotIn("PROCESS_TERMINATE", call)


if __name__ == "__main__":
    unittest.main()

