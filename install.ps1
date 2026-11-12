$ErrorActionPreference = "Stop"

$REPO = if ($env:MULTIGRAVITY_REPO) { $env:MULTIGRAVITY_REPO } else { "SkrudjReal/multigravity-cli" }
$BRANCH = if ($env:MULTIGRAVITY_REF) { $env:MULTIGRAVITY_REF } else { "main" }
$RAW = "https://raw.githubusercontent.com/$REPO/$BRANCH"
$INSTALL_DIR = "$env:USERPROFILE\.local\bin"

function Write-Step ($message) {
    Write-Host "  -> $message"
}

function Abort ($message) {
    Write-Error "Error: $message"
    exit 1
}

Write-Host "Installing Multigravity to $INSTALL_DIR ..."

if (!(Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
}

$IN_PATH = $false
foreach ($path in ($env:PATH -split ';')) {
    if ($path.TrimEnd('\') -eq $INSTALL_DIR.TrimEnd('\')) {
        $IN_PATH = $true
        break
    }
}

if (!$IN_PATH) {
    Write-Step "Adding $INSTALL_DIR to user PATH..."
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $newPath = if ($userPath) { "$userPath;$INSTALL_DIR" } else { "$INSTALL_DIR" }
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    $env:PATH = "$env:PATH;$INSTALL_DIR"
    Write-Host "  Added to PATH! You may need to restart your terminal for changes to take effect."
    Write-Host ""
}

# Download raw bytes and write UTF-8 with BOM for Windows PowerShell 5.1.
$UTF8BOM = New-Object System.Text.UTF8Encoding($true)
foreach ($name in @("multigravity.ps1", "multigravity-gui.ps1")) {
    Write-Step "Downloading $name..."
    $tempFile = Join-Path $INSTALL_DIR ($name + ".download")
    try {
        Invoke-WebRequest -Uri "$RAW/$name" -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
        $content = [System.IO.File]::ReadAllText($tempFile, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText((Join-Path $INSTALL_DIR $name), $content, $UTF8BOM)
    } catch {
        Abort "Failed to download $name : $_"
    } finally {
        if (Test-Path -LiteralPath $tempFile) {
            Remove-Item -LiteralPath $tempFile -Force
        }
    }
}

Write-Step "Creating wrapper script..."
$wrapper = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0multigravity.ps1" %*
"@

# Save wrapper as ASCII for widest compatibility with cmd.exe
[System.IO.File]::WriteAllText("$INSTALL_DIR\multigravity.cmd", $wrapper, [System.Text.Encoding]::ASCII)

Write-Host ""
Write-Host "Multigravity installed successfully!"
Write-Host ""
Write-Host "Usage:"
Write-Host "  multigravity help"
Write-Host "  multigravity new <profile-name>"
Write-Host "  multigravity <profile-name>"
Write-Host "  multigravity gui"
