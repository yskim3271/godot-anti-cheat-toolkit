param(
    [string]$OutputDir = "dist"
)

$ErrorActionPreference = "Stop"

$requiredFiles = @(
    "addons/anti_cheat_toolkit/plugin.cfg",
    "addons/anti_cheat_toolkit/anti_cheat_toolkit.gd",
    "addons/anti_cheat_toolkit/bin/anti_cheat_native.gdextension",
    "addons/anti_cheat_toolkit/bin/anti_cheat_native.windows.template_debug.x86_64.dll",
    "addons/anti_cheat_toolkit/bin/anti_cheat_native.windows.template_release.x86_64.dll",
    "native/SConstruct",
    "native/README.md",
    "native/src/anti_cheat_native.cpp",
    "scripts/build_windows.ps1",
    "README.md",
    "docs/usage.md",
    "docs/security_review.md",
    "docs/build_and_distribution.md",
    "docs/limitations.md",
    "docs/testing.md"
)

foreach ($path in $requiredFiles) {
    if (-not (Test-Path $path)) {
        throw "Missing required release file: $path"
    }
}

$staging = Join-Path $OutputDir "anti_cheat_toolkit"
$zipPath = Join-Path $OutputDir "godot_anti_cheat_toolkit.zip"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType File -Force -Path (Join-Path $OutputDir ".gdignore") | Out-Null

if (Test-Path $staging) {
    Remove-Item -Recurse -Force $staging
}
New-Item -ItemType Directory -Force -Path $staging | Out-Null

$copyRoots = @("addons", "docs", "example", "scripts", "tests", "README.md", "project.godot")
foreach ($item in $copyRoots) {
    Copy-Item -Recurse -Force $item $staging
}

Get-ChildItem (Join-Path $staging "addons") -Recurse -Include *.lib, *.exp, *.pdb, *.ilk, *.obj | Remove-Item -Force

New-Item -ItemType Directory -Force -Path (Join-Path $staging "native") | Out-Null
Copy-Item -Force "native/SConstruct" (Join-Path $staging "native")
Copy-Item -Force "native/README.md" (Join-Path $staging "native")
Copy-Item -Recurse -Force "native/src" (Join-Path $staging "native/src")

New-Item -ItemType Directory -Force -Path (Join-Path $staging ".github/workflows") | Out-Null
Copy-Item -Force ".github/workflows/native-libraries.yml" (Join-Path $staging ".github/workflows")

if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $zipPath
Write-Host "Wrote $zipPath"
