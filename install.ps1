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
foreach ($name in @("multigravity.ps1", "multigravity-gui.ps1", "multigravity-gui-launcher.cs")) {
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

# PNG downloads must remain binary. Windows shortcut icons require an ICO.
Write-Step "Downloading Multigravity app icon..."
$pngPath = Join-Path $INSTALL_DIR 'multigravity-gui-icon.png'
$icoPath = Join-Path $INSTALL_DIR 'multigravity-gui.ico'
$iconTmp = "$pngPath.download"
try {
    Invoke-WebRequest -Uri "$RAW/assets/multigravity-gui-icon.png" -OutFile $iconTmp -UseBasicParsing -ErrorAction Stop
    Move-Item -LiteralPath $iconTmp -Destination $pngPath -Force
    $png = [System.IO.File]::ReadAllBytes($pngPath)
    $writer = [System.IO.BinaryWriter]::new([System.IO.File]::Create($icoPath))
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
        $writer.Write([uint32]$png.Length)
        $writer.Write([uint32]22)
        $writer.Write($png)
    } finally { $writer.Dispose() }
} catch {
    Write-Warning "Could not install GUI icon: $_"
} finally {
    if (Test-Path -LiteralPath $iconTmp) { Remove-Item -LiteralPath $iconTmp -Force }
}

# Build a tiny Windows GUI host with a native executable icon. This keeps
# the taskbar from showing powershell.exe, rather than just changing the
# shortcut image. If the compiler is unavailable, the WPF script still works.
$exePath = Join-Path $INSTALL_DIR 'MultigravityProfileManager.exe'
$launcherSource = Join-Path $INSTALL_DIR 'multigravity-gui-launcher.cs'
$compilerPaths = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
)
$cscPath = $compilerPaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($cscPath -and (Test-Path -LiteralPath $icoPath)) {
    Write-Step "Building standalone GUI launcher..."
    try {
        $automationAssembly = [System.Management.Automation.PSObject].Assembly.Location
        $compilerArguments = @(
            '/nologo', '/target:winexe',
            ('/out:"' + $exePath + '"'),
            ('/win32icon:"' + $icoPath + '"'),
            ('/reference:"' + $automationAssembly + '"'),
            '/reference:System.Core.dll',
            '/reference:System.Windows.Forms.dll',
            ('"' + $launcherSource + '"')
        )
        $compilerOutput = & $cscPath @compilerArguments 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $exePath)) {
            throw "C# compiler failed: $compilerOutput"
        }
    } catch {
        Write-Warning "Native GUI host could not be built: $_"
        if (Test-Path -LiteralPath $exePath) { Remove-Item -LiteralPath $exePath -Force }
    }
} else {
    Write-Warning "C# compiler or icon not available; PowerShell WPF fallback will be used."
}

Write-Step "Creating wrapper script..."
$wrapper = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0multigravity.ps1" %*
"@

# Save wrapper as ASCII for widest compatibility with cmd.exe
[System.IO.File]::WriteAllText("$INSTALL_DIR\multigravity.cmd", $wrapper, [System.Text.Encoding]::ASCII)

# Add a standalone Start Menu entry with the new icon.
try {
    $menuPath = [Environment]::GetFolderPath('Programs')
    $shortcutPath = Join-Path $menuPath 'Multigravity Profile Manager.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    if (Test-Path -LiteralPath $exePath) {
        $shortcut.TargetPath = $exePath
        $shortcut.Arguments = ''
    } else {
        $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $guiFile = Join-Path $INSTALL_DIR 'multigravity-gui.ps1'
        $shortcut.Arguments = '-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $guiFile + '"'
    }
    $shortcut.WorkingDirectory = $INSTALL_DIR
    $shortcut.Description = 'Manage Antigravity IDE profiles'
    if (Test-Path -LiteralPath $icoPath) { $shortcut.IconLocation = "$icoPath,0" }
    $shortcut.Save()
} catch { Write-Warning "Could not create GUI shortcut: $_" }

Write-Host ""
Write-Host "Multigravity installed successfully!"
Write-Host ""
Write-Host "Usage:"
Write-Host "  multigravity help"
Write-Host "  multigravity new <profile-name>"
Write-Host "  multigravity <profile-name>"
Write-Host "  multigravity gui"
