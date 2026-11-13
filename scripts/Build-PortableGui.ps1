# Create a *single-file* portable Windows WPF executable with icon.
# Run from a Windows PowerShell 5.1 STA session, or on windows-latest Actions.
# This is a launcher with embedded .ps1 and .cs resources, not an
# independent reimplementation of Antigravity. The IDE must be installed.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root 'dist'
$bundleDir = Join-Path $outDir 'bundled-assets'
New-Item -ItemType Directory -Path $outDir,$bundleDir -Force | Out-Null

$sourceNames = @(
    'multigravity.ps1',
    'multigravity-gui.ps1',
    'multigravity-effects.cs'
)
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
foreach ($name in $sourceNames) {
    $sourcePath = Join-Path $root $name
    if (!(Test-Path -LiteralPath $sourcePath)) {
        throw "Missing required source: $sourcePath"
    }
    # Windows PowerShell 5.1 parses embedded UTF-8 scripts correctly with BOM.
    $value = [System.IO.File]::ReadAllText($sourcePath, [System.Text.Encoding]::UTF8)
    [System.IO.File]::WriteAllText((Join-Path $bundleDir $name), $value, $utf8Bom)
}

$png = Join-Path $root 'assets\multigravity-gui-icon.png'
$bundledPng = Join-Path $bundleDir 'multigravity-gui-icon.png'
if (!(Test-Path -LiteralPath $png)) { throw "Missing GUI icon: $png" }
Copy-Item -LiteralPath $png -Destination $bundledPng -Force
$ico = Join-Path $bundleDir 'multigravity-gui.ico'
$data = [System.IO.File]::ReadAllBytes($bundledPng)
$writer = [System.IO.BinaryWriter]::new([System.IO.File]::Create($ico))
try {
    $writer.Write([uint16]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]1)
    $writer.Write([byte]64)
    $writer.Write([byte]64)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]32)
    $writer.Write([uint32]$data.Length)
    $writer.Write([uint32]22)
    $writer.Write($data)
} finally {
    $writer.Dispose()
}

$compilerPaths = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
)
$csc = $compilerPaths | Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1
if (-not $csc) { throw 'Requires .NET Framework 4.x C# compiler on Windows.' }

$scriptFile = Join-Path $root 'multigravity-gui-portable-launcher.cs'
$exeFile = Join-Path $outDir 'MultigravityProfileManager.exe'
$automation = [System.Management.Automation.PSObject].Assembly.Location
if (!(Test-Path -LiteralPath $automation)) { throw 'Windows PowerShell 5.1 assembly not found.' }
$arguments = @(
    '/nologo', '/target:winexe',
    ('/out:"' + $exeFile + '"'),
    ('/win32icon:"' + $ico + '"'),
    ('/reference:"' + $automation + '"'),
    '/reference:System.Core.dll',
    '/reference:System.Windows.Forms.dll'
)
foreach ($name in @($sourceNames + @('multigravity-gui-icon.png','multigravity-gui.ico'))) {
    $filePath = Join-Path $bundleDir $name
    $arguments += ('/resource:"' + $filePath + '",Multigravity.Bundle.' + $name)
}
$arguments += ('"' + $scriptFile + '"')
& $csc @arguments
if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $exeFile)) {
    throw "C# compiler failed with exit code $LASTEXITCODE"
}
$exeBytes = [System.IO.File]::ReadAllBytes($exeFile)
if ($exeBytes.Length -lt 1024 -or $exeBytes[0] -ne 77 -or $exeBytes[1] -ne 90) {
    throw 'Compiled output is not a valid Windows PE executable.'
}

$readme = @'
Multigravity Profile Manager - Glass / Sakura (Windows portable)
===============================================================

Double-click MultigravityProfileManager.exe to launch.

This is a SINGLE-FILE executable with the PowerShell GUI, profile CLI,
animations, and icon EMBEDDED INSIDE IT. On first start it extracts the
bundled application files to:
  %LOCALAPPDATA%\Multigravity\GlassSakuraPortable-v0.1.0

Requires: Windows 10/11, Windows PowerShell 5.1, .NET Framework 4.x,
and a separately installed Antigravity IDE.

Existing profiles are preserved under:
  %USERPROFILE%\AntigravityProfiles

Independent login is enabled by default but relies on undocumented
Antigravity behavior. Verify login for each profile; protect token files.
No existing credentials are bundled.

To disable optional visual effects, start the application with:
  MULTIGRAVITY_DISABLE_FX=1

Source: https://github.com/SkrudjReal/multigravity-cli/tree/feature/glass-sakura-cursor
'@
$readmeFile = Join-Path $outDir 'README-Windows.txt'
[System.IO.File]::WriteAllText($readmeFile,$readme,[System.Text.Encoding]::UTF8)
$zipPath = Join-Path $outDir 'Multigravity-Glass-Sakura-Windows.zip'
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -Path $exeFile,$readmeFile -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host "SUCCESS: $exeFile"
Write-Host "SUCCESS: $zipPath"
Write-Host "EXE SHA256: $((Get-FileHash -LiteralPath $exeFile -Algorithm SHA256).Hash)"
