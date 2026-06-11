param(
    [string]$GodotCppPath = "native/thirdparty/godot-cpp",
    [string]$Branch = "master"
)

$ErrorActionPreference = "Stop"

if (Test-Path $GodotCppPath) {
    Write-Host "godot-cpp already exists at $GodotCppPath"
    exit 0
}

New-Item -ItemType Directory -Force -Path (Split-Path $GodotCppPath) | Out-Null
git clone --depth 1 --branch $Branch https://github.com/godotengine/godot-cpp $GodotCppPath

