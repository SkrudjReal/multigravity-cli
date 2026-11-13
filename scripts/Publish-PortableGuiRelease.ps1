# Fallback release uploader for machines where GitHub-hosted Windows runners
# cannot be allocated. Requires Windows PowerShell 5.1 and authenticated gh CLI.
param(
    [string]$Tag = 'v0.1.0-glass-sakura',
    [string]$Repo = 'SkrudjReal/multigravity-cli'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

if ($env:OS -ne 'Windows_NT') {
    throw 'The portable WPF GUI must be compiled on Windows.'
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) missing. Install via: winget install --id GitHub.cli -e'
}
& gh auth status
if ($LASTEXITCODE -ne 0) {
    throw 'Authenticate with your own GitHub account using: gh auth login'
}
& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Build-PortableGui.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Portable GUI executable compilation failed. Release was not created.'
}
$assets = @(
    (Join-Path $root 'dist\MultigravityProfileManager.exe'),
    (Join-Path $root 'dist\Multigravity-Glass-Sakura-Windows.zip')
)
foreach ($path in $assets) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing compiled asset: $path" }
}
$releasesJson = & gh release list --repo $Repo --limit 100 --json tagName
if ($LASTEXITCODE -ne 0) { throw 'Cannot read GitHub release list.' }
$releases = @($releasesJson | ConvertFrom-Json)
$exists = @($releases | Where-Object { $_.tagName -eq $Tag }).Count -gt 0
if ($exists) {
    & gh release upload $Tag @assets --repo $Repo --clobber
} else {
    & gh release create $Tag @assets --repo $Repo --target 'feature/glass-sakura-cursor' --title 'Multigravity Glass / Sakura Windows GUI v0.1.0' --notes 'Experimental Windows single-file WPF GUI. Bundles its own UI, CLI, effects, and icon. Requires Windows PowerShell 5.1, .NET Framework 4.x, and an installed Antigravity IDE. Independent login is experimental.' --prerelease
}
if ($LASTEXITCODE -ne 0) { throw "GitHub release upload failed, exit $LASTEXITCODE" }
Write-Host "Published: https://github.com/$Repo/releases/tag/$Tag"
