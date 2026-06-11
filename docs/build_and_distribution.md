# Build and Distribution Guide

## Verified Baseline

Checked on 2026-06-11:

- Godot stable: 4.6.3.
- GDExtension compatibility minimum used by this addon: 4.3.
- godot-cpp build target: `api_version=4.3`.

The native code is intended to be built against godot-cpp v10 or newer because that branch can target Godot 4.3 or later, including 4.6.

Reference pages checked:

- Godot download page: https://godotengine.org/download/windows/
- Godot GDExtension overview: https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/what_is_gdextension.html
- godot-cpp README: https://github.com/godotengine/godot-cpp

## Requirements

- Git.
- Python 3.11 or newer.
- SCons (`python -m pip install scons`).
- godot-cpp checkout.
- Visual Studio 2022 with C++ desktop tools.
- Windows SDK.

## Bootstrap godot-cpp

```powershell
./scripts/bootstrap_godot_cpp.ps1
```

This clones godot-cpp to `native/thirdparty/godot-cpp`.

## Build Windows

From PowerShell:

```powershell
python -m pip install scons
./scripts/build_windows.ps1 -Target template_debug
./scripts/build_windows.ps1 -Target template_release
```

Expected outputs:

- `addons/anti_cheat_toolkit/bin/anti_cheat_native.windows.template_debug.x86_64.dll`
- `addons/anti_cheat_toolkit/bin/anti_cheat_native.windows.template_release.x86_64.dll`

This workspace already contains Windows x86_64 debug/release DLLs that were built and loaded successfully with Godot 4.6.3.

## CI Builds

`.github/workflows/native-libraries.yml` builds Windows DLLs on `windows-latest`, downloads Godot 4.6.3, runs headless tests including native bridge registration, then uploads the native artifacts.

## Godot Export

1. Build native libraries for the target.
2. Verify `addons/anti_cheat_toolkit/bin/anti_cheat_native.gdextension` paths match outputs.
3. Export Windows builds from Godot.
4. Sign the Windows executable and DLLs if your release pipeline requires it.

## Package Addon

After both Windows DLLs are present:

```powershell
./scripts/package_addon.ps1
```

The package script fails when a required file is missing and writes `dist/godot_anti_cheat_toolkit.zip`.

## Server Reporting

The addon prepares JSONL report payloads but does not ship an opinionated uploader. Recommended backend handling:

- Accept signed detection event batches.
- Attach account/session identifiers from the game server, not from local device fingerprinting.
- Rate-limit reports.
- Treat events as risk signals.
- Review correlated detections before enforcement.

## Release Checklist

- Build release native libraries.
- Run static tests.
- Run Godot headless tests.
- Run `./scripts/package_addon.ps1`.
- Rebuild file integrity manifest after final content changes.
- Verify development-mode settings are correct for release.
- Verify privacy settings and player-facing disclosures.
- Code-sign the executable and DLLs where required.
