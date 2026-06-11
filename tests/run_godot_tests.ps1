param(
    [string]$Godot = "godot"
)

$ErrorActionPreference = "Stop"

$env:APPDATA = Join-Path (Get-Location) ".godot_appdata"
$env:LOCALAPPDATA = Join-Path (Get-Location) ".godot_localappdata"
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null

& $Godot --headless --path . --import --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Godot --headless --path . -s res://tests/gdscript/test_secure_save.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Godot --headless --path . -s res://tests/gdscript/test_secure_value.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Godot --headless --path . -s res://tests/gdscript/test_privacy_identity.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Godot --headless --path . -s res://tests/gdscript/test_settings.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Godot --headless --path . -s res://tests/gdscript/test_file_integrity.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Godot --headless --path . -s res://tests/gdscript/test_monitors.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Godot --headless --path . -s res://tests/gdscript/test_reporting.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Godot --headless --path . -s res://tests/gdscript/test_native_bridge.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
