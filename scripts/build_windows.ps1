param(
    [ValidateSet("template_debug", "template_release")]
    [string]$Target = "template_debug",
    [string]$Arch = "x86_64",
    [string]$ApiVersion = "4.3",
    [string]$GodotCppPath = "thirdparty/godot-cpp"
)

$ErrorActionPreference = "Stop"

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
    throw "vswhere.exe not found. Install Visual Studio 2022 C++ tools."
}

$vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsPath) {
    throw "Visual Studio C++ tools not found."
}

$vcvars = Join-Path $vsPath "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) {
    throw "vcvars64.bat not found at $vcvars"
}

Push-Location native
try {
    $sconsCandidates = @(
        "scons",
        "$env:APPDATA\Python\Python311\Scripts\scons.exe",
        "$env:APPDATA\Python\Python313\Scripts\scons.exe"
    )
    $scons = $null
    foreach ($candidate in $sconsCandidates) {
        if ($candidate -eq "scons") {
            if (Get-Command scons -ErrorAction SilentlyContinue) {
                $scons = "scons"
                break
            }
        }
        elseif (Test-Path $candidate) {
            $scons = $candidate
            break
        }
    }
    if (-not $scons) {
        throw "SCons not found. Run python -m pip install scons."
    }
    cmd /c "`"$vcvars`" && `"$scons`" platform=windows target=$Target arch=$Arch api_version=$ApiVersion godot_cpp_path=$GodotCppPath"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}
