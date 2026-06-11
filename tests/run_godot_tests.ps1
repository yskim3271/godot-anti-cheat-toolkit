param(
    [string]$Godot = "godot"
)

$ErrorActionPreference = "Stop"

$env:APPDATA = Join-Path (Get-Location) ".godot_appdata"
$env:LOCALAPPDATA = Join-Path (Get-Location) ".godot_localappdata"
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null

# Cold-import exit codes are unreliable on some runner images, so the import
# only gates when a verbose retry fails too. The test scripts below quit with
# deterministic exit codes and remain the real gate.
& $Godot --headless --path . --import --quit
$importExit = $LASTEXITCODE
Write-Host "godot --import exit code: $importExit"
if ($importExit -ne 0) {
    Write-Host "Import exited nonzero. Retrying with --verbose (last 120 lines):"
    & $Godot --headless --path . --import --quit --verbose 2>&1 | Select-Object -Last 120
    $retryExit = $LASTEXITCODE
    Write-Host "verbose import exit code: $retryExit"
    if ($retryExit -ne 0) {
        exit $retryExit
    }
}

$tests = @(
    "res://tests/gdscript/test_secure_save.gd",
    "res://tests/gdscript/test_secure_value.gd",
    "res://tests/gdscript/test_privacy_identity.gd",
    "res://tests/gdscript/test_settings.gd",
    "res://tests/gdscript/test_file_integrity.gd",
    "res://tests/gdscript/test_monitors.gd",
    "res://tests/gdscript/test_reporting.gd",
    "res://tests/gdscript/test_native_bridge.gd"
)

foreach ($test in $tests) {
    & $Godot --headless --path . -s $test
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED (exit $LASTEXITCODE): $test"
        exit $LASTEXITCODE
    }
    Write-Host "PASSED: $test"
}

Write-Host "All Godot headless tests passed."
