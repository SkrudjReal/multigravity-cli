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
# WPF controls live in the presentation namespace; xaml without
# /presentation parses as XML but fails to create Window at runtime.
$presentationNamespace = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation'
if ($xaml.DocumentElement.NamespaceURI -ne $presentationNamespace) {
    throw "Invalid root Window XAML namespace: $($xaml.DocumentElement.NamespaceURI)"
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
$cliSource = [System.IO.File]::ReadAllText(
    (Join-Path $root 'multigravity.ps1'),
    [System.Text.Encoding]::UTF8)
foreach ($expected in @('--user-data-dir=', '--extensions-dir=', '--isolated-auth',
                       'SSH_CONNECTION', 'finally {')) {
    if (-not $cliSource.Contains($expected)) {
        throw "Missing expected isolation launcher feature: $expected"
    }
}
if (-not $source.Contains('x:Name="IsolatedAuthCheck"')) {
    throw 'Missing explicit opt-in to file-based authentication in the GUI.'
}
Write-Host 'PASS: isolation flags and opt-in auth control are present.'

# Regression checks for responsive layout and the custom icon.
foreach ($expected in @('x:Name="ProfilesLayout"', 'x:Name="DetailsPanel"',
                        'x:Name="HeaderLayout"', 'VerticalScrollBarVisibility="Auto"',
                        'function Update-ResponsiveLayout', 'Add_SizeChanged',
                        'multigravity-gui-icon.png')) {
    if (-not $source.Contains($expected)) {
        throw "Missing responsive layout or icon feature: $expected"
    }
}
if ($source.Contains('Independent login (experimental)')) {
    throw 'The outdated experimental UI label is still present.'
}
$iconPath = Join-Path $root 'assets\multigravity-gui-icon.png'
if (-not (Test-Path -LiteralPath $iconPath)) {
    throw 'Missing generated PNG app icon.'
}
$png = [System.IO.File]::ReadAllBytes($iconPath)
$signature = [byte[]]@(137,80,78,71,13,10,26,10)
for ($i = 0; $i -lt $signature.Length; $i++) {
    if ($png[$i] -ne $signature[$i]) {
        throw 'Custom icon has an invalid PNG signature.'
    }
}
$installerSource = [System.IO.File]::ReadAllText(
    (Join-Path $root 'install.ps1'), [System.Text.Encoding]::UTF8)
if ($installerSource[0] -eq [char]0xFEFF) {
    throw 'install.ps1 must not start with BOM when run by irm | iex.'
}
foreach ($expected in @('assets/multigravity-gui-icon.png',
                        'multigravity-gui.ico', 'Multigravity Profile Manager.lnk')) {
    if (-not $installerSource.Contains($expected)) {
        throw "Installer is missing GUI asset or shortcut: $expected"
    }
}
Write-Host 'PASS: responsive UI, icon asset, and installer integration.'

# Also load the XAML using the real WPF runtime on Windows; XML parsing alone
# cannot detect unsupported property values.
if ($env:OS -eq 'Windows_NT') {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
    try {
        foreach ($name in @('ProfilesLayout', 'DetailsPanel', 'HeaderLayout',
                            'RefreshButton', 'IsolatedAuthCheck')) {
            if ($null -eq $window.FindName($name)) {
                throw "WPF could not resolve named control: $name"
            }
        }
        Write-Host 'PASS: WPF created the window and resolved responsive controls.'
    } finally {
        $window.Close()
    }
}
# Visual-theme regression checks: the disabled button state must remain dark,
# not fall back to the Windows default white control template.
foreach ($fragment in @('x:Name="OrbitSpark"', 'Property="IsEnabled" Value="False"',
                      'TargetName="Chrome" Property="Background" Value="#201A2C"',
                      'Style x:Key="DangerButton"', 'DoubleAnimation',
                      'Color="#0D0917"', 'Property="BorderBrush" Value="#AE81D5"')) {
    if (-not $source.Contains($fragment)) {
        throw "Missing astral UI theme or animation: $fragment"
    }
}
foreach ($fragment in @('SetCurrentProcessExplicitAppUserModelID',
                      'MultigravityTaskbar', 'SendMessage($hwnd, 0x80',
                      'Add_ContentRendered')) {
    if (-not $source.Contains($fragment)) {
        throw "Missing branded taskbar or entrance behavior: $fragment"
    }
}
$cliSource = [System.IO.File]::ReadAllText(
    (Join-Path $root 'multigravity.ps1'), [System.Text.Encoding]::UTF8)
if (-not $cliSource.Contains('MultigravityProfileManager.exe')) {
    throw 'multigravity gui is not configured to launch the branded host.'
}
$launcherPath = Join-Path $root 'multigravity-gui-launcher.cs'
if (-not (Test-Path -LiteralPath $launcherPath)) {
    throw 'Missing native-icon C# GUI launcher source.'
}
$launcherSource = [System.IO.File]::ReadAllText($launcherPath, [System.Text.Encoding]::UTF8)
if (-not $launcherSource.Contains('RunspaceFactory.CreateRunspace')) {
    throw 'Native launcher does not host the PowerShell GUI script.'
}
foreach ($fragment in @('/target:winexe', '/win32icon:', 'multigravity-gui-launcher.cs')) {
    if (-not $installerSource.Contains($fragment)) {
        throw "Installer is missing native GUI compilation step: $fragment"
    }
}
Write-Host 'PASS: branded taskbar identity, custom dark controls, and WPF motion present.'

# Frost / Neon appearance and input effects tests.
$uiNamespace = New-Object System.Xml.XmlNamespaceManager($xaml.NameTable)
$uiNamespace.AddNamespace('x', 'http://schemas.microsoft.com/winfx/2006/xaml')
$login = $xaml.SelectSingleNode("//*[@x:Name='IsolatedAuthCheck']", $uiNamespace)
if ($null -eq $login -or $login.GetAttribute('IsChecked') -ne 'True') {
    throw 'Independent login must be checked by default.'
}
foreach ($element in @('FxSky', 'FxSparks', 'FrostRim', 'AccentEdge',
                        'SelectionNeon', 'TrackThumb')) {
    if ($null -eq $xaml.SelectSingleNode("//*[@x:Name='$element']", $uiNamespace)) {
        throw "Missing frost/neon component: $element"
    }
}
if (-not $source.Contains('TextOptions.TextRenderingMode="ClearType"')) {
    throw 'Expected refined WPF font rendering configuration.'
}
if (-not $source.Contains('FontFamily="Segoe UI Variable Text, Segoe UI"')) {
    throw 'Expected friendly, legible Windows typography.'
}
if (-not $source.Contains('x:Key="FrostThumb"')) {
    throw 'Custom scrollbar thumb style missing.'
}
if (-not $source.Contains('TargetProperty="Opacity"')) {
    throw 'Missing opacity / hover animations.'
}

$effectsPath = Join-Path $root 'multigravity-effects.cs'
if (-not (Test-Path -LiteralPath $effectsPath)) {
    throw 'WPF effects C# source is missing.'
}
$effectsSource = [System.IO.File]::ReadAllText($effectsPath,
    [System.Text.Encoding]::UTF8)
foreach ($needle in @('class FrostEffects', 'AddSnowflake', 'PreviewMouseMove',
                      'PreviewMouseLeftButtonDown', 'MaxTransient = 55',
                      'while (alive.Count >= MaxTransient)', 'window.Closed += Closed')) {
    if (-not $effectsSource.Contains($needle)) {
        throw "Missing performance/safety behavior in particle engine: $needle"
    }
}
if (-not $installerSource.Contains('multigravity-effects.cs')) {
    throw 'Windows installer must download the effects source.'
}
Write-Host 'PASS: default independent login, frost styling, scrollbar and bounded particles.'

# Compile and instantiate the engine under the same Windows .NET Framework
# environment that users have; XML-only checks previously missed bad XAML.
if ($env:OS -eq 'Windows_NT') {
    $references = @(
        [System.Windows.Window].Assembly.Location,
        [System.Windows.Media.Brush].Assembly.Location,
        [System.Windows.DependencyObject].Assembly.Location,
        [System.Windows.Controls.Canvas].Assembly.Location
    ) | Select-Object -Unique
    Add-Type -Path $effectsPath -ReferencedAssemblies $references -ErrorAction Stop
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $fxWindow = [Windows.Markup.XamlReader]::Load($reader)
    try {
        $sky = $fxWindow.FindName('FxSky')
        $sparks = $fxWindow.FindName('FxSparks')
        $fx = [Multigravity.FrostEffects]::Attach($fxWindow, $sky, $sparks)
        if ($sky.Children.Count -lt 25) {
            throw "Expected background layers and snowflakes; got $($sky.Children.Count)"
        }
        Write-Host 'PASS: real WPF snow/particle engine compiles and attaches.'
    } finally {
        $fxWindow.Close()
    }
}
Write-Host 'NOTE: Mouse glow and animation smoothness still require a visual Windows test.'



