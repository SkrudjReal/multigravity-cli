# Static checks for Windows PowerShell 5.1 WPF GUI files.
# Run from the repository root: powershell.exe -NoProfile -File .\tests\Test-WindowsGui.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$filenames = @('multigravity.ps1', 'multigravity-gui.ps1', 'install.ps1')

foreach ($filename in $filenames) {
    $path = Join-Path $root $filename
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $filename"
    }
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $path, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) {
        $messages = @($errors | ForEach-Object { $_.Message }) -join '; '
        throw "PowerShell parser errors in $filename : $messages"
    }
    Write-Host "PASS: PowerShell syntax for $filename"
}

$source = [System.IO.File]::ReadAllText(
    (Join-Path $root 'multigravity-gui.ps1'),
    [System.Text.Encoding]::UTF8)
$match = [regex]::Match($source, '(?s)\[xml\]\$xaml = @''\r?\n(.*?)\r?\n''@')
if (-not $match.Success) {
    throw 'Could not find embedded WPF XAML here-string.'
}
[xml]$xaml = $match.Groups[1].Value
if ($xaml.DocumentElement.LocalName -ne 'Window') {
    throw 'Root XAML element must be a Window.'
}
$namespaceManager = New-Object System.Xml.XmlNamespaceManager($xaml.NameTable)
$namespaceManager.AddNamespace('x', 'http://schemas.microsoft.com/winfx/2006/xaml')
foreach ($control in @('ProfileList', 'RefreshButton', 'CreateButton', 'LaunchButton',
                       'RenameButton', 'DeleteButton', 'OpenFolderButton')) {
    $found = $xaml.SelectSingleNode("//*[@x:Name='$control']", $namespaceManager)
    if ($null -eq $found) {
        throw "Missing WPF control: $control"
    }
}
Write-Host 'PASS: embedded XAML parses and all required controls exist.'
Write-Host 'NOTE: This is a static check, not a full Windows GUI runtime test.'
