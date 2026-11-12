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
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Multigravity | Profile Manager"
        Width="1060" Height="740" MinWidth="460" MinHeight="420"
        WindowStartupLocation="CenterScreen"
        Background="#100B1A" Foreground="#E2D8ED"
        FontFamily="Segoe UI" FontSize="13" UseLayoutRounding="True"
        SnapsToDevicePixels="True">
    <Window.Resources>
        <SolidColorBrush x:Key="Gold" Color="#D0B989"/>
        <SolidColorBrush x:Key="Muted" Color="#A99DBD"/>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#29203B"/>
            <Setter Property="Foreground" Value="#E2D8ED"/>
            <Setter Property="BorderBrush" Value="#57416C"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="18,11"/>
            <Setter Property="Margin" Value="0,0,8,0"/>
            <Setter Property="MinHeight" Value="39"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="RenderTransformOrigin" Value="0.5,0.5"/>
            <Setter Property="RenderTransform">
                <Setter.Value><ScaleTransform ScaleX="1" ScaleY="1"/></Setter.Value>
            </Setter>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Chrome" CornerRadius="10"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter Content="{TemplateBinding Content}"
                                              HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"
                                              RecognizesAccessKey="True"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Chrome" Property="BorderBrush" Value="#AE81D5"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Chrome" Property="Background" Value="#4A305F"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Chrome" Property="Background" Value="#201A2C"/>
                                <Setter TargetName="Chrome" Property="BorderBrush" Value="#3C3049"/>
                                <Setter Property="Foreground" Value="#796D85"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <EventTrigger RoutedEvent="Button.MouseEnter">
                    <BeginStoryboard>
                        <Storyboard>
                            <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)"
                                             To="1.025" Duration="0:0:0.14"/>
                            <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)"
                                             To="1.025" Duration="0:0:0.14"/>
                        </Storyboard>
                    </BeginStoryboard>
                </EventTrigger>
                <EventTrigger RoutedEvent="Button.MouseLeave">
                    <BeginStoryboard>
                        <Storyboard>
                            <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)"
                                             To="1" Duration="0:0:0.18"/>
                            <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)"
                                             To="1" Duration="0:0:0.18"/>
                        </Storyboard>
                    </BeginStoryboard>
                </EventTrigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="AccentButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#55346F"/>
            <Setter Property="BorderBrush" Value="#9667BB"/>
            <Setter Property="Foreground" Value="#F0E3FC"/>
        </Style>
        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#372332"/>
            <Setter Property="BorderBrush" Value="#6E435C"/>
            <Setter Property="Foreground" Value="#E6B4C8"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#191326"/>
            <Setter Property="Foreground" Value="#E2D8ED"/>
            <Setter Property="CaretBrush" Value="#D7AFFF"/>
            <Setter Property="SelectionBrush" Value="#71428C"/>
            <Setter Property="BorderBrush" Value="#57416C"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="11,9"/>
            <Setter Property="MinHeight" Value="39"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="BoxChrome" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="9" Padding="{TemplateBinding Padding}">
                            <ScrollViewer x:Name="PART_ContentHost"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsKeyboardFocusWithin" Value="True">
                                <Setter TargetName="BoxChrome" Property="BorderBrush" Value="#AE81D5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#C8BBD5"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Border x:Name="BoxChrome" Width="17" Height="17"
                                    CornerRadius="4" BorderThickness="1"
                                    BorderBrush="#75598B" Background="#24182F"
                                    VerticalAlignment="Center">
                                <Path x:Name="Tick" Data="M 3,8 L 7,12 L 14,4"
                                      Stroke="#EBD6FF" StrokeThickness="2"
                                      StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                                      Visibility="Collapsed"/>
                            </Border>
                            <ContentPresenter Content="{TemplateBinding Content}"
                                              Margin="9,0,0,0" VerticalAlignment="Center"/>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Tick" Property="Visibility" Value="Visible"/>
                                <Setter TargetName="BoxChrome" Property="Background" Value="#69438A"/>
                                <Setter TargetName="BoxChrome" Property="BorderBrush" Value="#C5A1E1"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="BoxChrome" Property="BorderBrush" Value="#C4A3DC"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.48"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ListBoxItem">
            <Setter Property="Background" Value="#23182F"/>
            <Setter Property="Foreground" Value="#E2D8ED"/>
            <Setter Property="Margin" Value="0,0,0,9"/>
            <Setter Property="Padding" Value="12"/>
            <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ListBoxItem">
                        <Border x:Name="RowChrome" CornerRadius="12"
                                Background="{TemplateBinding Background}"
                                BorderBrush="#453352" BorderThickness="1"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="RowChrome" Property="Background" Value="#32213E"/>
                                <Setter TargetName="RowChrome" Property="BorderBrush" Value="#9D72B4"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="RowChrome" Property="Background" Value="#422654"/>
                                <Setter TargetName="RowChrome" Property="BorderBrush" Value="#BA90D1"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid ClipToBounds="True">
        <Grid.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#0D0917" Offset="0"/>
                <GradientStop Color="#1A102A" Offset="0.53"/>
                <GradientStop Color="#0D0A19" Offset="1"/>
            </LinearGradientBrush>
        </Grid.Background>
        <Ellipse Width="560" Height="560" HorizontalAlignment="Right"
                 VerticalAlignment="Top" Margin="0,-280,-170,0" Opacity="0.10"
                 IsHitTestVisible="False" Fill="#7F419A">
            <Ellipse.Effect><BlurEffect Radius="95"/></Ellipse.Effect>
        </Ellipse>
        <Ellipse Width="340" Height="340" HorizontalAlignment="Left"
                 VerticalAlignment="Bottom" Margin="-140,0,0,-190" Opacity="0.08"
                 IsHitTestVisible="False" Fill="#9E549C">
            <Ellipse.Effect><BlurEffect Radius="70"/></Ellipse.Effect>
        </Ellipse>
        <Canvas IsHitTestVisible="False" Opacity="0.55" ClipToBounds="True">
            <Ellipse Canvas.Left="68" Canvas.Top="68" Width="3" Height="3" Fill="#CA9ED9"/>
            <Ellipse Canvas.Left="410" Canvas.Top="115" Width="2" Height="2" Fill="#E5CFAB"/>
            <Ellipse Canvas.Left="925" Canvas.Top="83" Width="3" Height="3" Fill="#9B80BC"/>
            <Ellipse Canvas.Left="740" Canvas.Top="273" Width="2" Height="2" Fill="#C6A8D6"/>
            <Ellipse Canvas.Left="160" Canvas.Top="405" Width="2" Height="2" Fill="#A893C1"/>
            <Ellipse Canvas.Left="970" Canvas.Top="545" Width="2" Height="2" Fill="#CEB88B"/>
        </Canvas>
        <Grid Margin="24,20,24,18">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="17"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="14"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Grid x:Name="HeaderLayout" Grid.Row="0">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                        <TextBlock Text="&#x2726;" Foreground="#C6A87D" FontSize="17" Margin="0,0,9,0"/>
                        <TextBlock Text="MULTIGRAVITY" Foreground="#C6A87D"
                                   FontSize="12" FontWeight="SemiBold"/>
                        <TextBlock Text="   /   PROFILE CONSTELLATION" Foreground="#867593"
                                   FontSize="11" VerticalAlignment="Center"/>
                    </StackPanel>
                    <TextBlock Text="Profile Manager" Foreground="#E8DAF3"
                               FontSize="30" FontWeight="Light" Margin="0,0,0,4"/>
                    <TextBlock Text="Every identity, its own orbit."
                               Foreground="#A899B5" FontSize="12"/>
                </StackPanel>
                <Button x:Name="RefreshButton" Grid.Column="1"
                        Content="&#x21BB;  Refresh" VerticalAlignment="Bottom"
                        Margin="12,0,0,1"/>
            </Grid>
            <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto"
                          HorizontalScrollBarVisibility="Disabled" Focusable="False">
                <Grid x:Name="ProfilesLayout">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="1.08*"/>
                        <ColumnDefinition Width="18"/>
                        <ColumnDefinition Width="1*"/>
                    </Grid.ColumnDefinitions>
                    <Border x:Name="ProfilesPanel" Grid.Column="0"
                            BorderThickness="1" BorderBrush="#544068"
                            Background="#D9181025" CornerRadius="18"
                            Padding="20" MinHeight="400">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="16"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="18"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            <Grid Grid.Row="0">
                                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock Text="&#x2726;" Foreground="#C6A87D"
                                               Margin="0,0,8,0" FontSize="13"/>
                                    <TextBlock Text="YOUR PROFILES" Foreground="#D4C2E0"
                                               FontWeight="SemiBold" FontSize="12"/>
                                </StackPanel>
                                <TextBlock x:Name="CountText" Grid.Column="1"
                                           Text="0 profiles" Foreground="#A693B8" FontSize="12"/>
                            </Grid>
                            <ListBox x:Name="ProfileList" Grid.Row="2"
                                     Background="Transparent" BorderThickness="0"
                                     MaxHeight="315" MinHeight="145"
                                     ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                                <ListBox.ItemTemplate>
                                    <DataTemplate>
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="Auto"/>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <Border Width="32" Height="32" CornerRadius="9"
                                                    BorderThickness="1" BorderBrush="#705283"
                                                    Background="#392447" VerticalAlignment="Center"
                                                    Margin="0,0,11,0">
                                                <TextBlock Text="&#x2726;" HorizontalAlignment="Center"
                                                           VerticalAlignment="Center" Foreground="#C7A7D4"
                                                           FontSize="16"/>
                                            </Border>
                                            <StackPanel Grid.Column="1">
                                                <TextBlock Text="{Binding Name}" Foreground="#E6DBEF"
                                                           FontSize="15" FontWeight="SemiBold"/>
                                                <TextBlock Text="{Binding LastModified}" Foreground="#A194AE"
                                                           FontSize="10.5" Margin="0,4,0,0"/>
                                            </StackPanel>
                                            <Border Grid.Column="2" BorderBrush="#594360"
                                                    BorderThickness="1" Background="#2F203B"
                                                    CornerRadius="7" Padding="7,3" VerticalAlignment="Center">
                                                <TextBlock Text="{Binding Type}" Foreground="#BFA7D1"
                                                           FontSize="10.5"/>
                                            </Border>
                                        </Grid>
                                    </DataTemplate>
                                </ListBox.ItemTemplate>
                            </ListBox>
                            <StackPanel Grid.Row="4">
                                <Border Background="#644A6C" Height="1" Opacity="0.4"
                                        Margin="0,0,0,17"/>
                                <TextBlock Text="CREATE NEW PROFILE" Foreground="#CBB2D8"
                                           FontWeight="SemiBold" FontSize="11" Margin="0,0,0,10"/>
                                <TextBox x:Name="NewNameInput" MaxLength="64"/>
                                <WrapPanel Margin="0,12,0,0">
                                    <CheckBox x:Name="SharedCheck" Content="Shared settings"
                                              Margin="0,4,12,9" />
                                    <Button x:Name="CreateButton" Content="&#x2726;  Create profile"
                                            Style="{StaticResource AccentButton}"
                                            MinWidth="140" Margin="0,0,0,8"/>
                                </WrapPanel>
                            </StackPanel>
                        </Grid>
                    </Border>
                    <Border x:Name="DetailsPanel" Grid.Column="2"
                            BorderThickness="1" BorderBrush="#544068"
                            Background="#DF1B1228" CornerRadius="18" Padding="22">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                                <TextBlock Text="&#x2726;" Foreground="#C6A87D"
                                           FontSize="13" Margin="0,0,8,0"/>
                                <TextBlock Text="SELECTED IDENTITY" Foreground="#D4C2E0"
                                           FontWeight="SemiBold" FontSize="12"/>
                            </StackPanel>
                            <TextBlock x:Name="SelectedName" Text="Select a profile"
                                       TextWrapping="Wrap" Foreground="#E8DAF3"
                                       FontWeight="Light" FontSize="26" Margin="0,5,0,6"/>
                            <TextBlock x:Name="SelectedType" Text="No profile selected"
                                       Foreground="#BD9CC9" FontSize="12"/>
                            <TextBlock x:Name="SelectedPath" TextWrapping="Wrap"
                                       Foreground="#8E81A3" FontSize="11"
                                       Margin="0,12,0,18"/>
                            <Button x:Name="LaunchButton" Content="&#x2726;  Launch Antigravity"
                                    Style="{StaticResource AccentButton}" Margin="0,0,0,12"/>
                            <CheckBox x:Name="IsolatedAuthCheck" Content="Independent login"
                                      Margin="0,0,0,7"/>
                            <TextBlock Text="Store sign-in files separately for this profile. Keep profile folders private."
                                       Foreground="#9786A8" TextWrapping="Wrap"
                                       FontSize="11" Margin="0,0,0,14"/>
                            <Button x:Name="OpenFolderButton" Content="Open profile folder"
                                    Margin="0,0,0,18"/>
                            <Border Background="#644A6C" Height="1" Opacity="0.4"
                                    Margin="0,0,0,17"/>
                            <TextBlock Text="RENAME PROFILE" Foreground="#CBB2D8"
                                       FontSize="11" FontWeight="SemiBold" Margin="0,0,0,10"/>
                            <TextBox x:Name="RenameInput" MaxLength="64" Margin="0,0,0,13"/>
                            <WrapPanel Margin="0,0,0,13">
                                <Button x:Name="RenameButton" Content="Rename"
                                        MinWidth="120" Margin="0,0,8,8"/>
                                <Button x:Name="DeleteButton" Content="Delete profile"
                                        Style="{StaticResource DangerButton}"
                                        MinWidth="133" Margin="0,0,0,8"/>
                            </WrapPanel>
                            <TextBlock Text="Deletion permanently removes this profile and its local settings."
                                       TextWrapping="Wrap" Foreground="#857790" FontSize="11"/>
                        </StackPanel>
                    </Border>
                </Grid>
            </ScrollViewer>
            <Grid Grid.Row="4">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock x:Name="StatusText" Text="Ready."
                           Foreground="#B7A5CB" FontSize="11"
                           TextTrimming="CharacterEllipsis" VerticalAlignment="Center"/>
                <TextBlock Grid.Column="1" Text="&#x2726;   ASTRAL INTERFACE"
                           Foreground="#8A769E" FontSize="10" Margin="12,0,0,0"
                           VerticalAlignment="Center"/>
            </Grid>
        </Grid>
    </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$script:Window = [Windows.Markup.XamlReader]::Load($reader)

# Set the window and taskbar icon from the icon bundled by install.ps1.
$iconPath = Join-Path $PSScriptRoot 'multigravity-gui-icon.png'
if (Test-Path -LiteralPath $iconPath) {
    $iconStream = $null
    try {
        $iconBytes = [System.IO.File]::ReadAllBytes($iconPath)
        $iconStream = New-Object System.IO.MemoryStream (,$iconBytes)
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.StreamSource = $iconStream
        $bitmap.EndInit()
        $bitmap.Freeze()
        $script:Window.Icon = $bitmap
    } catch {
        Write-Warning "Could not load Multigravity window icon: $_"
    } finally {
        if ($null -ne $iconStream) { $iconStream.Dispose() }
    }
}
$script:ProfileList = $script:Window.FindName('ProfileList')
$script:CountText = $script:Window.FindName('CountText')
$script:SelectedName = $script:Window.FindName('SelectedName')
$script:SelectedType = $script:Window.FindName('SelectedType')
$script:SelectedPath = $script:Window.FindName('SelectedPath')
$script:RenameInput = $script:Window.FindName('RenameInput')
$script:NewNameInput = $script:Window.FindName('NewNameInput')
$script:SharedCheck = $script:Window.FindName('SharedCheck')
$script:StatusText = $script:Window.FindName('StatusText')
$script:ProfilesLayout = $script:Window.FindName('ProfilesLayout')
$script:DetailsPanel = $script:Window.FindName('DetailsPanel')
$script:RefreshButton = $script:Window.FindName('RefreshButton')
$script:HeaderLayout = $script:Window.FindName('HeaderLayout')
$script:LayoutIsNarrow = $null

function Update-ResponsiveLayout {
    $narrow = $script:Window.ActualWidth -lt 900
    if ($null -ne $script:LayoutIsNarrow -and $narrow -eq $script:LayoutIsNarrow) {
        return
    }
    $script:LayoutIsNarrow = $narrow
    $cols = $script:ProfilesLayout.ColumnDefinitions
    if ($narrow) {
        $cols[0].Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $cols[1].Width = [System.Windows.GridLength]::new(0)
        $cols[2].Width = [System.Windows.GridLength]::new(0)
        [System.Windows.Controls.Grid]::SetColumn($script:DetailsPanel, 0)
        [System.Windows.Controls.Grid]::SetRow($script:DetailsPanel, 1)
        $script:DetailsPanel.Margin = [System.Windows.Thickness]::new(0, 16, 0, 0)

        [System.Windows.Controls.Grid]::SetColumn($script:RefreshButton, 0)
        [System.Windows.Controls.Grid]::SetRow($script:RefreshButton, 1)
        $script:RefreshButton.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $script:RefreshButton.Margin = [System.Windows.Thickness]::new(0, 12, 0, 0)
    } else {
        $cols[0].Width = [System.Windows.GridLength]::new(1.1, [System.Windows.GridUnitType]::Star)
        $cols[1].Width = [System.Windows.GridLength]::new(18)
        $cols[2].Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        [System.Windows.Controls.Grid]::SetColumn($script:DetailsPanel, 2)
        [System.Windows.Controls.Grid]::SetRow($script:DetailsPanel, 0)
        $script:DetailsPanel.Margin = [System.Windows.Thickness]::new(0)

        [System.Windows.Controls.Grid]::SetColumn($script:RefreshButton, 1)
        [System.Windows.Controls.Grid]::SetRow($script:RefreshButton, 0)
        $script:RefreshButton.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $script:RefreshButton.Margin = [System.Windows.Thickness]::new(0)
    }
}
$script:Window.Add_SizeChanged({ Update-ResponsiveLayout })
$script:Window.Add_Loaded({ Update-ResponsiveLayout })
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
        $launchArguments = @($item.Name)
        if ($script:Window.FindName('IsolatedAuthCheck').IsChecked -eq $true) {
            $launchArguments += '--isolated-auth'
        }
        [void](Invoke-Cli $launchArguments)
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
