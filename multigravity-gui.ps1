# Windows-only WPF manager for Multigravity.
# Requires Windows PowerShell 5.1 and the built-in .NET Framework WPF assemblies.
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') {
    throw 'The WPF profile manager is only supported on Windows.'
}
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
    throw 'WPF requires STA. Start with: powershell.exe -STA -File multigravity-gui.ps1'
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$script:CliPath = Join-Path $PSScriptRoot 'multigravity.ps1'
if (-not (Test-Path -LiteralPath $script:CliPath)) {
    throw "Cannot find multigravity.ps1 next to $PSCommandPath"
}
$script:UserHome = [Environment]::GetFolderPath('UserProfile')
$script:ProfilesRoot = if ($env:MULTIGRAVITY_HOME) {
    $env:MULTIGRAVITY_HOME
} else {
    Join-Path $script:UserHome 'AntigravityProfiles'
}
$script:PSExe = Join-Path $PSHOME 'powershell.exe'

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Multigravity | Profile Manager"
        Width="980" Height="660" MinWidth="780" MinHeight="550"
        WindowStartupLocation="CenterScreen"
        Background="#0B1020" Foreground="#EAF0FF"
        FontFamily="Segoe UI" FontSize="13">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#293552"/>
            <Setter Property="Foreground" Value="#F4F7FF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="15,10"/>
            <Setter Property="Margin" Value="0,0,8,0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="MinHeight" Value="36"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#39496E"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="AccentButton" TargetType="Button">
            <Setter Property="Background" Value="#6177E9"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="18,10"/>
            <Setter Property="Margin" Value="0,0,8,0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="MinHeight" Value="36"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#161F35"/>
            <Setter Property="Foreground" Value="#F3F5FF"/>
            <Setter Property="BorderBrush" Value="#425171"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="MinHeight" Value="36"/>
        </Style>
        <Style TargetType="ListBoxItem">
            <Setter Property="Background" Value="#172038"/>
            <Setter Property="Foreground" Value="#EAF0FF"/>
            <Setter Property="Padding" Value="12"/>
            <Setter Property="Margin" Value="0,0,0,6"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#39496E"/>
                    <Setter Property="Foreground" Value="White"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="20"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="16"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid Grid.Row="0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel>
                <TextBlock Text="MULTIGRAVITY" Foreground="#8398FF"
                           FontSize="13" FontWeight="SemiBold"/>
                <TextBlock Text="Profile Manager" FontSize="30" FontWeight="Bold" Margin="0,4,0,4"/>
                <TextBlock Text="Independent Antigravity accounts, one familiar home."
                           Foreground="#95A3C4"/>
            </StackPanel>
            <Button x:Name="RefreshButton" Grid.Column="1"
                    Content="Refresh profiles" VerticalAlignment="Bottom"/>
        </Grid>
        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="1.1*"/>
                <ColumnDefinition Width="18"/>
                <ColumnDefinition Width="1*"/>
            </Grid.ColumnDefinitions>
            <Border Grid.Column="0" Background="#11192D" CornerRadius="16" Padding="19">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="12"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="18"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <DockPanel>
                        <TextBlock Text="PROFILES" FontWeight="SemiBold" Foreground="#B5C3E7"/>
                        <TextBlock x:Name="CountText" Text="0 profiles" DockPanel.Dock="Right"
                                   Foreground="#7E8CAB" HorizontalAlignment="Right"/>
                    </DockPanel>
                    <ListBox x:Name="ProfileList" Grid.Row="2"
                             Background="Transparent" BorderThickness="0"
                             ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListBox.ItemTemplate>
                            <DataTemplate>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <StackPanel>
                                        <TextBlock Text="{Binding Name}" FontSize="16"
                                                   FontWeight="SemiBold"/>
                                        <TextBlock Text="{Binding LastModified}"
                                                   Foreground="#A0AECF" FontSize="11" Margin="0,5,0,0"/>
                                    </StackPanel>
                                    <Border Grid.Column="1" Background="#263858"
                                            CornerRadius="8" Padding="8,4"
                                            VerticalAlignment="Center">
                                        <TextBlock Text="{Binding Type}" FontSize="11"
                                                   Foreground="#B9CBFF"/>
                                    </Border>
                                </Grid>
                            </DataTemplate>
                        </ListBox.ItemTemplate>
                    </ListBox>
                    <StackPanel Grid.Row="4">
                        <TextBlock Text="NEW PROFILE" Foreground="#A8B6DA"
                                   FontWeight="SemiBold" Margin="0,0,0,7"/>
                        <TextBox x:Name="NewNameInput" MaxLength="64"/>
                        <DockPanel Margin="0,10,0,0">
                            <CheckBox x:Name="SharedCheck" Content="Shared extensions and settings"
                                      Foreground="#B6C4E6" VerticalAlignment="Center"/>
                            <Button x:Name="CreateButton" Style="{StaticResource AccentButton}"
                                    Content="Create" DockPanel.Dock="Right" Margin="10,0,0,0"/>
                        </DockPanel>
                    </StackPanel>
                </Grid>
            </Border>
            <Border Grid.Column="2" Background="#11192D" CornerRadius="16" Padding="22">
                <StackPanel>
                    <TextBlock Text="SELECTED PROFILE" FontWeight="SemiBold"
                               Foreground="#A8B6DA"/>
                    <TextBlock x:Name="SelectedName" Text="Select a profile"
                               FontWeight="Bold" FontSize="27" Margin="0,13,0,6"/>
                    <TextBlock x:Name="SelectedType" Text="No profile selected"
                               Foreground="#9BADD5" Margin="0,0,0,12"/>
                    <TextBlock x:Name="SelectedPath" TextWrapping="Wrap"
                               Foreground="#8999BC" FontSize="12" Margin="0,0,0,22"/>
                    <Button x:Name="LaunchButton" Content="Launch Antigravity"
                            Style="{StaticResource AccentButton}" Margin="0,0,0,9"/>
                    <Button x:Name="OpenFolderButton" Content="Open profile folder"
                            Margin="0,0,0,22"/>
                    <TextBlock Text="RENAME PROFILE" Foreground="#A8B6DA"
                               FontWeight="SemiBold" Margin="0,0,0,8"/>
                    <TextBox x:Name="RenameInput" MaxLength="64"
                             Margin="0,0,0,10"/>
                    <WrapPanel Margin="0,0,0,16">
                        <Button x:Name="RenameButton" Content="Rename"/>
                        <Button x:Name="DeleteButton" Content="Delete profile"
                                Background="#512E42" Foreground="#FFD2D8"/>
                    </WrapPanel>
                    <TextBlock Text="Profile deletion removes its account data, settings and local extensions."
                               TextWrapping="Wrap" FontSize="12" Foreground="#7F90B3"/>
                </StackPanel>
            </Border>
        </Grid>
        <DockPanel Grid.Row="4">
            <TextBlock x:Name="StatusText" Foreground="#99AAD1"
                       Text="Ready." TextTrimming="CharacterEllipsis"/>
            <TextBlock Text="Windows PowerShell 5.1 / WPF"
                       Foreground="#667898" DockPanel.Dock="Right"/>
        </DockPanel>
    </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$script:Window = [Windows.Markup.XamlReader]::Load($reader)
$script:ProfileList = $script:Window.FindName('ProfileList')
$script:CountText = $script:Window.FindName('CountText')
$script:SelectedName = $script:Window.FindName('SelectedName')
$script:SelectedType = $script:Window.FindName('SelectedType')
$script:SelectedPath = $script:Window.FindName('SelectedPath')
$script:RenameInput = $script:Window.FindName('RenameInput')
$script:NewNameInput = $script:Window.FindName('NewNameInput')
$script:SharedCheck = $script:Window.FindName('SharedCheck')
$script:StatusText = $script:Window.FindName('StatusText')
$script:Items = New-Object 'System.Collections.ObjectModel.ObservableCollection[Object]'
$script:ProfileList.ItemsSource = $script:Items

function Test-ProfileName([string]$name) {
    return $name -match '^[a-zA-Z0-9][a-zA-Z0-9-]*$'
}

function Show-Error([string]$message) {
    $script:StatusText.Text = 'Error: ' + $message
    [void][System.Windows.MessageBox]::Show($script:Window, $message, 'Multigravity', 'OK', 'Error')
}

function Invoke-Cli([string[]]$commands, [string]$answer = '') {
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $script:PSExe
    $encodedArgs = @($commands | ForEach-Object { '"' + $_.Replace('"', '""') + '"' })
    $info.Arguments = '-NoProfile -STA -ExecutionPolicy Bypass -File "' +
                      $script:CliPath.Replace('"', '""') + '" ' + ($encodedArgs -join ' ')
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    # Never inherit a profile-specific USERPROFILE from an earlier CLI launch.
    $info.EnvironmentVariables['USERPROFILE'] = $script:UserHome
    $info.EnvironmentVariables['APPDATA'] = Join-Path $script:UserHome 'AppData\Roaming'
    $info.EnvironmentVariables['LOCALAPPDATA'] = Join-Path $script:UserHome 'AppData\Local'

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $info
    [void]$process.Start()
    if ($answer) { $process.StandardInput.WriteLine($answer) }
    $process.StandardInput.Close()
    $output = $process.StandardOutput.ReadToEnd()
    $errorText = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    $exit = $process.ExitCode
    $process.Dispose()
    if ($exit -ne 0 -or $errorText) {
        $details = if ($errorText) { $errorText.Trim() } else { $output.Trim() }
        throw "Command failed: $details"
    }
    return $output.Trim()
}

function Get-SelectedProfile {
    return $script:ProfileList.SelectedItem
}

function Sync-Selection {
    $selected = Get-SelectedProfile
    $enabled = $null -ne $selected
    foreach ($name in @('LaunchButton', 'OpenFolderButton', 'RenameButton', 'DeleteButton')) {
        $script:Window.FindName($name).IsEnabled = $enabled
    }
    if ($enabled) {
        $script:SelectedName.Text = $selected.Name
        $script:SelectedType.Text = $selected.Type + ' profile'
        $script:SelectedPath.Text = $selected.Path
        $script:RenameInput.Text = $selected.Name
    } else {
        $script:SelectedName.Text = 'Select a profile'
        $script:SelectedType.Text = 'No profile selected'
        $script:SelectedPath.Text = ''
        $script:RenameInput.Text = ''
    }
}

function Refresh-Profiles([string]$selectName = '') {
    if (-not $selectName) {
        $current = Get-SelectedProfile
        if ($null -ne $current) { $selectName = $current.Name }
    }
    $script:Items.Clear()
    if (Test-Path -LiteralPath $script:ProfilesRoot) {
        $dirs = @(Get-ChildItem -LiteralPath $script:ProfilesRoot -Directory |
            Where-Object { $_.Name -match '^[a-zA-Z0-9][a-zA-Z0-9-]*$' } |
            Sort-Object Name)
        foreach ($dir in $dirs) {
            $kind = if (Test-Path -LiteralPath (Join-Path $dir.FullName '.shared')) {
                'Shared'
            } else {
                'Full'
            }
            $script:Items.Add([pscustomobject]@{
                Name = $dir.Name
                Type = $kind
                Path = $dir.FullName
                LastModified = 'Updated ' + $dir.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            })
        }
    }
    $script:CountText.Text = "$($script:Items.Count) profiles"
    if ($selectName) {
        foreach ($item in $script:Items) {
            if ($item.Name -eq $selectName) {
                $script:ProfileList.SelectedItem = $item
                break
            }
        }
    }
    Sync-Selection
}

function Launch-Selected {
    $item = Get-SelectedProfile
    if ($null -eq $item) { return }
    try {
        [void](Invoke-Cli @($item.Name))
        $script:StatusText.Text = "Launch requested: $($item.Name)"
    } catch {
        Show-Error $_.Exception.Message
    }
}

$script:ProfileList.Add_SelectionChanged({ Sync-Selection })
$script:ProfileList.Add_MouseDoubleClick({ Launch-Selected })
$script:Window.FindName('RefreshButton').Add_Click({
    try {
        Refresh-Profiles
        $script:StatusText.Text = 'Profiles refreshed.'
    } catch { Show-Error $_.Exception.Message }
})
$script:Window.FindName('LaunchButton').Add_Click({ Launch-Selected })

$script:Window.FindName('OpenFolderButton').Add_Click({
    $item = Get-SelectedProfile
    if ($null -ne $item) {
        try {
            Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $item.Path + '"')
        } catch { Show-Error $_.Exception.Message }
    }
})
$script:Window.FindName('CreateButton').Add_Click({
    $name = $script:NewNameInput.Text.Trim()
    if (-not (Test-ProfileName $name)) {
        Show-Error 'Use letters, numbers or hyphens; start with a letter or number.'
        return
    }
    try {
        $argsList = @('new', $name)
        if ($script:SharedCheck.IsChecked -eq $true) { $argsList += '--shared' }
        [void](Invoke-Cli $argsList)
        Refresh-Profiles $name
        $script:NewNameInput.Text = ''
        $script:StatusText.Text = "Created profile: $name"
    } catch { Show-Error $_.Exception.Message }
})
$script:Window.FindName('RenameButton').Add_Click({
    $item = Get-SelectedProfile
    if ($null -eq $item) { return }
    $name = $script:RenameInput.Text.Trim()
    if (-not (Test-ProfileName $name)) {
        Show-Error 'Invalid name. Use letters, numbers and hyphens.'
        return
    }
    if ($name -eq $item.Name) { return }
    try {
        [void](Invoke-Cli @('rename', $item.Name, $name))
        Refresh-Profiles $name
        $script:StatusText.Text = "Renamed profile to: $name"
    } catch { Show-Error $_.Exception.Message }
})
$script:Window.FindName('DeleteButton').Add_Click({
    $item = Get-SelectedProfile
    if ($null -eq $item) { return }
    $message = "Permanently delete profile '$($item.Name)' and ALL its data?" +
               [Environment]::NewLine + 'Close Antigravity for this profile first.'
    $choice = [System.Windows.MessageBox]::Show(
        $script:Window, $message, 'Delete profile', 'YesNo', 'Warning')
    if ($choice -ne [System.Windows.MessageBoxResult]::Yes) { return }
    try {
        [void](Invoke-Cli @('delete', $item.Name) 'y')
        if (Test-Path -LiteralPath $item.Path) {
            throw 'Profile still exists. Ensure Antigravity is closed and try again.'
        }
        Refresh-Profiles
        $script:StatusText.Text = "Deleted profile: $($item.Name)"
    } catch { Show-Error $_.Exception.Message }
})
Refresh-Profiles
[void]$script:Window.ShowDialog()
