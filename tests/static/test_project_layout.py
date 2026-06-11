from pathlib import Path
import json
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


class LayoutTests(unittest.TestCase):
    def test_required_files_exist(self):
        required = [
            "addons/anti_cheat_toolkit/plugin.cfg",
            "addons/anti_cheat_toolkit/anti_cheat_toolkit.gd",
            "addons/anti_cheat_toolkit/bin/anti_cheat_native.gdextension",
            "native/src/anti_cheat_native.cpp",
            "native/SConstruct",
            "scripts/package_addon.ps1",
            "scripts/build_windows.ps1",
            ".github/workflows/native-libraries.yml",
            "example/scenes/main.tscn",
            "docs/security_review.md",
            "docs/usage.md",
            "docs/build_and_distribution.md",
            "docs/limitations.md",
        ]
        for rel in required:
            self.assertTrue((ROOT / rel).exists(), rel)

    def test_gdextension_baseline(self):
        text = (ROOT / "addons/anti_cheat_toolkit/bin/anti_cheat_native.gdextension").read_text(encoding="utf-8")
        self.assertIn('compatibility_minimum = "4.3"', text)
        self.assertIn("windows.editor.x86_64", text)
        self.assertIn("windows.debug.x86_64", text)
        self.assertIn("windows.release.x86_64", text)
        self.assertNotIn("macos.", text)

    def test_ci_builds_and_tests_windows(self):
        workflow = (ROOT / ".github/workflows/native-libraries.yml").read_text(encoding="utf-8")
        self.assertIn("./scripts/build_windows.ps1 -Target template_debug", workflow)
        self.assertIn("./scripts/build_windows.ps1 -Target template_release", workflow)
        self.assertIn("./tests/run_godot_tests.ps1", workflow)
        self.assertIn("https://github.com/godotengine/godot/releases/download/", workflow)

    def test_release_package_requires_windows_payload(self):
        script = (ROOT / "scripts/package_addon.ps1").read_text(encoding="utf-8")
        self.assertIn("anti_cheat_native.windows.template_debug.x86_64.dll", script)
        self.assertIn("anti_cheat_native.windows.template_release.x86_64.dll", script)
        self.assertIn("throw \"Missing required release file", script)
        self.assertIn('"scripts"', script)
        self.assertIn('"tests"', script)
        self.assertIn('"native/src"', script)
        self.assertIn(".github/workflows/native-libraries.yml", script)

    def test_docs_state_verified_godot_version(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        build_docs = (ROOT / "docs/build_and_distribution.md").read_text(encoding="utf-8")
        self.assertIn("Godot 4.6.3", readme)
        self.assertIn("api_version=4.3", readme)
        self.assertIn("https://godotengine.org/download/windows/", build_docs)
        self.assertIn("https://github.com/godotengine/godot-cpp", build_docs)

    def test_no_macos_references_remain(self):
        scan_roots = ["addons", "docs", "scripts", "tests", "native/src", ".github", "example"]
        pattern = re.compile(r"macos|darwin|__APPLE__|dylib|notarize|xcrun|stapler", re.IGNORECASE)
        offenders = []
        for root in scan_roots:
            base = ROOT / root
            if not base.exists():
                continue
            for path in base.rglob("*"):
                if path.resolve() == Path(__file__).resolve():
                    continue
                if path.suffix.lower() in {".gd", ".cpp", ".h", ".md", ".py", ".ps1", ".yml", ".cfg", ".gdextension", ".tscn"}:
                    if pattern.search(path.read_text(encoding="utf-8", errors="ignore")):
                        offenders.append(str(path.relative_to(ROOT)))
        self.assertEqual(offenders, [])

    def test_integrity_manifest_is_json(self):
        manifest = json.loads((ROOT / "addons/anti_cheat_toolkit/integrity_manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["format"], "godot_act_integrity_manifest_v1")
        self.assertIsInstance(manifest["entries"], list)

    def test_native_binaries_are_real_when_present(self):
        bin_dir = ROOT / "addons/anti_cheat_toolkit/bin"
        binaries = [p for p in bin_dir.iterdir() if re.search(r"\.(dll|so)$", p.name)]
        self.assertGreaterEqual(len(binaries), 2)
        for path in binaries:
            self.assertGreater(path.stat().st_size, 1024, path.name)


if __name__ == "__main__":
    unittest.main()
