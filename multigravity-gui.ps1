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
Add-Type -AssemblyName System.Xaml

Add-Type -AssemblyName System.Drawing

# PowerShell is the host executable, so explicitly separate this app from
# generic PowerShell windows in the taskbar before creating the WPF window.
if (-not ('MultigravityTaskbar' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class MultigravityTaskbar {
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string appID);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hwnd, int message, IntPtr wparam, IntPtr lparam);
}
'@
}
[void][MultigravityTaskbar]::SetCurrentProcessExplicitAppUserModelID(
    'SkrudjReal.Multigravity.ProfileManager')


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
        Width="1060" Height="740" MinWidth="460" MinHeight="420"
        WindowStartupLocation="CenterScreen"
        Background="#111216" Foreground="#ECECF0"
        FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="13" FontWeight="Normal" TextOptions.TextFormattingMode="Display" TextOptions.TextRenderingMode="ClearType" UseLayoutRounding="True"
        SnapsToDevicePixels="True">
    <Window.Resources>
        <SolidColorBrush x:Key="Gold" Color="#E95B9C"/>
        <SolidColorBrush x:Key="Muted" Color="#A2A2AE"/>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#25262B"/>
            <Setter Property="Foreground" Value="#E7E8EC"/>
            <Setter Property="BorderBrush" Value="#3B3E49"/>
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
                        <Grid ClipToBounds="False">
                            <!-- Ambient neon light outside the glass surface. -->
                            <Border x:Name="AmbientGlow" Margin="9,7,9,7"
                                    Background="#B42D74" CornerRadius="22"
                                    Opacity="0" IsHitTestVisible="False">
                                <Border.Effect>
                                    <DropShadowEffect Color="#F3389F" ShadowDepth="0"
                                                      BlurRadius="24" Opacity="0.75"/>
                                </Border.Effect>
                            </Border>
                            <Border x:Name="Chrome" CornerRadius="22"
                                    Background="{TemplateBinding Background}"
                                    BorderBrush="{TemplateBinding BorderBrush}"
                                    BorderThickness="{TemplateBinding BorderThickness}"/>
                            <Grid Margin="1" ClipToBounds="True" IsHitTestVisible="False">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="3*"/>
                                    <ColumnDefinition Width="1*"/>
                                </Grid.ColumnDefinitions>
                                <!-- Satin glass reflection, independent of selection. -->
                                <Border x:Name="GlassSheen" Grid.ColumnSpan="2"
                                        CornerRadius="21" Opacity="0.6">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0.8,1">
                                            <GradientStop Color="#26FFFFFF" Offset="0"/>
                                            <GradientStop Color="#08FFFFFF" Offset="0.4"/>
                                            <GradientStop Color="#00FFFFFF" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                </Border>
                                <!-- Exactly the rightmost 1/4 of the button. -->
                                <Border x:Name="QuarterGlow" Grid.Column="1"
                                        CornerRadius="0,21,21,0" Opacity="0.15">
                                    <Border.Background>
                                        <RadialGradientBrush Center="0.97,0.50"
                                            GradientOrigin="0.97,0.50" RadiusX="1.1" RadiusY="1.1">
                                            <GradientStop Color="#D0FF459F" Offset="0"/>
                                            <GradientStop Color="#86D6378E" Offset="0.4"/>
                                            <GradientStop Color="#00D6378E" Offset="1"/>
                                        </RadialGradientBrush>
                                    </Border.Background>
                                </Border>
                                <Border x:Name="FrostRim" Grid.ColumnSpan="2"
                                        Height="2" VerticalAlignment="Top" Margin="14,1,14,0"
                                        CornerRadius="2" Opacity="0.26">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                            <GradientStop Color="#00EAF5FA" Offset="0"/>
                                            <GradientStop Color="#78EAF5FA" Offset="0.2"/>
                                            <GradientStop Color="#38FFACD7" Offset="0.74"/>
                                            <GradientStop Color="#00EAF5FA" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                </Border>
                                <Border x:Name="AccentEdge" Grid.Column="1"
                                        Width="3" Height="26" Margin="0,0,4,0"
                                        HorizontalAlignment="Right" VerticalAlignment="Center"
                                        CornerRadius="3" Background="#F442A2" Opacity="0"/>
                            </Grid>
                            <ContentPresenter Content="{TemplateBinding Content}"
                                HorizontalAlignment="Center" VerticalAlignment="Center"
                                Margin="{TemplateBinding Padding}"
                                RecognizesAccessKey="True"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="Tag" Value="Accent">
                                <Setter TargetName="QuarterGlow" Property="Opacity" Value="0.75"/>
                                <Setter TargetName="AmbientGlow" Property="Opacity" Value="0.17"/>
                                <Setter TargetName="AccentEdge" Property="Opacity" Value="0.55"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Chrome" Property="BorderBrush" Value="#DE6BAC"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Chrome" Property="Background" Value="#45303B"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Chrome" Property="Background" Value="#1C1D22"/>
                                <Setter TargetName="Chrome" Property="BorderBrush" Value="#303039"/>
                                <Setter TargetName="QuarterGlow" Property="Opacity" Value="0"/>
                                <Setter TargetName="AmbientGlow" Property="Opacity" Value="0"/>
                                <Setter TargetName="AccentEdge" Property="Opacity" Value="0"/>
                                <Setter TargetName="FrostRim" Property="Opacity" Value="0.06"/>
                                <Setter Property="Foreground" Value="#777A84"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                            </Trigger>
                            <EventTrigger RoutedEvent="MouseEnter">
                                <BeginStoryboard><Storyboard>
                                    <DoubleAnimation Storyboard.TargetName="QuarterGlow"
                                        Storyboard.TargetProperty="Opacity" To="0.88"
                                        Duration="0:0:0.22"/>
                                    <DoubleAnimation Storyboard.TargetName="AmbientGlow"
                                        Storyboard.TargetProperty="Opacity" To="0.30"
                                        Duration="0:0:0.23"/>
                                    <DoubleAnimation Storyboard.TargetName="AccentEdge"
                                        Storyboard.TargetProperty="Opacity" To="0.92"
                                        Duration="0:0:0.20"/>
                                    <DoubleAnimation Storyboard.TargetName="FrostRim"
                                        Storyboard.TargetProperty="Opacity" To="0.67"
                                        Duration="0:0:0.20"/>
                                </Storyboard></BeginStoryboard>
                            </EventTrigger>
                            <EventTrigger RoutedEvent="MouseLeave">
                                <BeginStoryboard><Storyboard>
                                    <DoubleAnimation Storyboard.TargetName="QuarterGlow"
                                        Storyboard.TargetProperty="Opacity" To="0.15"
                                        Duration="0:0:0.28"/>
                                    <DoubleAnimation Storyboard.TargetName="AmbientGlow"
                                        Storyboard.TargetProperty="Opacity" To="0"
                                        Duration="0:0:0.30"/>
                                    <DoubleAnimation Storyboard.TargetName="AccentEdge"
                                        Storyboard.TargetProperty="Opacity" To="0"
                                        Duration="0:0:0.28"/>
                                    <DoubleAnimation Storyboard.TargetName="FrostRim"
                                        Storyboard.TargetProperty="Opacity" To="0.26"
                                        Duration="0:0:0.28"/>
                                </Storyboard></BeginStoryboard>
                            </EventTrigger>
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
            <Setter Property="Tag" Value="Accent"/>
            <Setter Property="Background" Value="#54283E"/>
            <Setter Property="BorderBrush" Value="#C74D8A"/>
            <Setter Property="Foreground" Value="#FBE5F0"/>
        </Style>
        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#30272D"/>
            <Setter Property="BorderBrush" Value="#65444E"/>
            <Setter Property="Foreground" Value="#EBB4C8"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#1A1C21"/>
            <Setter Property="Foreground" Value="#E7E8EC"/>
            <Setter Property="CaretBrush" Value="#FF7AB8"/>
            <Setter Property="SelectionBrush" Value="#68334E"/>
            <Setter Property="BorderBrush" Value="#3B3E49"/>
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
                                <Setter TargetName="BoxChrome" Property="BorderBrush" Value="#DF6DA9"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#C8C9D1"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Border x:Name="BoxChrome" Width="17" Height="17"
                                    CornerRadius="4" BorderThickness="1"
                                    BorderBrush="#58445A" Background="#25252C"
                                    VerticalAlignment="Center">
                                <Path x:Name="Tick" Data="M 3,8 L 7,12 L 14,4"
                                      Stroke="#FFE8F1" StrokeThickness="2"
                                      StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                                      Visibility="Collapsed"/>
                            </Border>
                            <ContentPresenter Content="{TemplateBinding Content}"
                                              Margin="9,0,0,0" VerticalAlignment="Center"/>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Tick" Property="Visibility" Value="Visible"/>
                                <Setter TargetName="BoxChrome" Property="Background" Value="#753456"/>
                                <Setter TargetName="BoxChrome" Property="BorderBrush" Value="#E974AE"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="BoxChrome" Property="BorderBrush" Value="#FF9AC6"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.48"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <!-- Thin graphite scrollbar with a rounded, pink-on-hover thumb. -->
        <Style x:Key="FrostThumb" TargetType="Thumb">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Thumb">
                        <Border x:Name="TrackThumb" Background="#4E4E59"
                                CornerRadius="4" Margin="1,3"/>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="TrackThumb" Property="Background" Value="#B84583"/>
                            </Trigger>
                            <Trigger Property="IsDragging" Value="True">
                                <Setter TargetName="TrackThumb" Property="Background" Value="#EB58A5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="10"/>
            <Setter Property="Background" Value="#17181C"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Border Background="#18191F" CornerRadius="5">
                            <Track x:Name="PART_Track" Orientation="Vertical"
                                   Minimum="{TemplateBinding Minimum}"
                                   Maximum="{TemplateBinding Maximum}"
                                   Value="{TemplateBinding Value}"
                                   ViewportSize="{TemplateBinding ViewportSize}"
                                   IsDirectionReversed="True">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Opacity="0" IsTabStop="False"
                                                  Command="ScrollBar.PageUpCommand"/>
                                </Track.DecreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource FrostThumb}"/>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Opacity="0" IsTabStop="False"
                                                  Command="ScrollBar.PageDownCommand"/>
                                </Track.IncreaseRepeatButton>
                            </Track>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ListBoxItem">
            <Setter Property="Background" Value="#232429"/>
            <Setter Property="Foreground" Value="#E7E8EC"/>
            <Setter Property="Margin" Value="0,0,0,9"/>
            <Setter Property="Padding" Value="12"/>
            <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ListBoxItem">
                        <Grid ClipToBounds="False">
                            <Border x:Name="SelectedGlow" Margin="7,5"
                                Background="#A52D70" CornerRadius="18"
                                Opacity="0" IsHitTestVisible="False">
                                <Border.Effect>
                                    <DropShadowEffect Color="#F02E97"
                                        ShadowDepth="0" BlurRadius="20" Opacity="0.7"/>
                                </Border.Effect>
                            </Border>
                            <Border x:Name="RowChrome" CornerRadius="18"
                                Background="{TemplateBinding Background}"
                                BorderBrush="#34353D" BorderThickness="1"/>
                            <Grid Margin="1" ClipToBounds="True" IsHitTestVisible="False">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="3*"/>
                                    <ColumnDefinition Width="1*"/>
                                </Grid.ColumnDefinitions>
                                <Border Grid.ColumnSpan="2" CornerRadius="17" Opacity="0.7">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0.8,1">
                                            <GradientStop Color="#22FFFFFF" Offset="0"/>
                                            <GradientStop Color="#08FFFFFF" Offset="0.4"/>
                                            <GradientStop Color="#00FFFFFF" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                </Border>
                                <Border x:Name="QuarterSegment" Grid.Column="1"
                                        CornerRadius="0,17,17,0" Opacity="0">
                                    <Border.Background>
                                        <RadialGradientBrush Center="0.98,0.5"
                                            GradientOrigin="0.98,0.5" RadiusX="1.0" RadiusY="1.0">
                                            <GradientStop Color="#C9FC3D97" Offset="0"/>
                                            <GradientStop Color="#9CDB3F92" Offset="0.38"/>
                                            <GradientStop Color="#00C72A81" Offset="1"/>
                                        </RadialGradientBrush>
                                    </Border.Background>
                                </Border>
                                <Border x:Name="SelectionNeon" Grid.Column="1"
                                    HorizontalAlignment="Right" VerticalAlignment="Center"
                                    Width="4" Height="32" Margin="0,0,4,0"
                                    Background="#FC51A9" CornerRadius="4" Opacity="0"/>
                                <Border x:Name="TopGlass" Grid.ColumnSpan="2"
                                    Height="1" Margin="16,1,16,0"
                                    VerticalAlignment="Top" CornerRadius="1" Opacity="0.24"
                                    Background="#CBEAF3"/>
                            </Grid>
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="RowChrome" Property="Background" Value="#29272E"/>
                                <Setter TargetName="RowChrome" Property="BorderBrush" Value="#6D4A66"/>
                                <Setter TargetName="TopGlass" Property="Opacity" Value="0.48"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="RowChrome" Property="Background" Value="#31252D"/>
                                <Setter TargetName="RowChrome" Property="BorderBrush" Value="#DF5C9E"/>
                                <Setter TargetName="QuarterSegment" Property="Opacity" Value="0.97"/>
                                <Setter TargetName="SelectedGlow" Property="Opacity" Value="0.18"/>
                                <Setter TargetName="SelectionNeon" Property="Opacity" Value="0.95"/>
                            </Trigger>
                            <EventTrigger RoutedEvent="ListBoxItem.MouseEnter">
                                <BeginStoryboard><Storyboard>
                                    <DoubleAnimation Storyboard.TargetName="TopGlass"
                                        Storyboard.TargetProperty="Opacity" To="0.55"
                                        Duration="0:0:0.18"/>
                                </Storyboard></BeginStoryboard>
                            </EventTrigger>
                            <EventTrigger RoutedEvent="ListBoxItem.MouseLeave">
                                <BeginStoryboard><Storyboard>
                                    <DoubleAnimation Storyboard.TargetName="TopGlass"
                                        Storyboard.TargetProperty="Opacity" To="0.24"
                                        Duration="0:0:0.28"/>
                                </Storyboard></BeginStoryboard>
                            </EventTrigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid ClipToBounds="True">
        <Grid.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#121317" Offset="0"/>
                <GradientStop Color="#1A1B20" Offset="0.53"/>
                <GradientStop Color="#101115" Offset="1"/>
            </LinearGradientBrush>
        </Grid.Background>
        <Canvas x:Name="FxSky" ClipToBounds="True" Panel.ZIndex="0" IsHitTestVisible="False" />
        <!-- Animated low-opacity aurora layers come from FxSky. -->
        <Canvas IsHitTestVisible="False" Opacity="0.55" ClipToBounds="True">
            <Ellipse Canvas.Left="68" Canvas.Top="68" Width="3" Height="3" Fill="#CA9ED9"/>
            <Ellipse Canvas.Left="410" Canvas.Top="115" Width="2" Height="2" Fill="#D7BEC7"/>
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
                        <TextBlock x:Name="OrbitSpark" Text="&#x2726;" Foreground="#EE7FAF" FontSize="17" Margin="0,0,9,0"/>
                        <TextBlock Text="MULTIGRAVITY" Foreground="#EE7FAF"
                                   FontSize="12" FontWeight="SemiBold"/>
                        <TextBlock Text="   /   PROFILE CONSTELLATION" Foreground="#867593"
                                   FontSize="11" VerticalAlignment="Center"/>
                    </StackPanel>
                    <TextBlock Text="Profile Manager" Foreground="#F0EFF2"
                               FontSize="30" FontWeight="SemiBold" Margin="0,0,0,4"/>
                    <TextBlock Text="Every identity, its own orbit."
                               Foreground="#A0A3AC" FontSize="12"/>
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
                            BorderThickness="1" BorderBrush="#393A46"
                            Background="#E31B1C22" CornerRadius="18"
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
                                    <TextBlock Text="&#x2726;" Foreground="#EE7FAF"
                                               Margin="0,0,8,0" FontSize="13"/>
                                    <TextBlock Text="YOUR PROFILES" Foreground="#D6D6DC"
                                               FontWeight="SemiBold" FontSize="12"/>
                                </StackPanel>
                                <TextBlock x:Name="CountText" Grid.Column="1"
                                           Text="0 profiles" Foreground="#B1ABB4" FontSize="12"/>
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
                                                    Background="#372533" VerticalAlignment="Center"
                                                    Margin="0,0,11,0">
                                                <TextBlock Text="&#x2726;" HorizontalAlignment="Center"
                                                           VerticalAlignment="Center" Foreground="#C7A7D4"
                                                           FontSize="16"/>
                                            </Border>
                                            <StackPanel Grid.Column="1">
                                                <TextBlock Text="{Binding Name}" Foreground="#E6DBEF"
                                                           FontSize="15" FontWeight="SemiBold"/>
                                                <TextBlock Text="{Binding LastModified}" Foreground="#92939D"
                                                           FontSize="10.5" Margin="0,4,0,0"/>
                                            </StackPanel>
                                            <Border Grid.Column="2" BorderBrush="#51414D"
                                                    BorderThickness="1" Background="#2D252D"
                                                    CornerRadius="7" Padding="7,3" VerticalAlignment="Center">
                                                <TextBlock Text="{Binding Type}" Foreground="#CEB2C1"
                                                           FontSize="10.5"/>
                                            </Border>
                                        </Grid>
                                    </DataTemplate>
                                </ListBox.ItemTemplate>
                            </ListBox>
                            <StackPanel Grid.Row="4">
                                <Border Background="#644A6C" Height="1" Opacity="0.4"
                                        Margin="0,0,0,17"/>
                                <TextBlock Text="CREATE NEW PROFILE" Foreground="#D2CCD5"
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
                            BorderThickness="1" BorderBrush="#393A46"
                            Background="#E31B1C22" CornerRadius="18" Padding="22">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                                <TextBlock Text="&#x2726;" Foreground="#EE7FAF"
                                           FontSize="13" Margin="0,0,8,0"/>
                                <TextBlock Text="SELECTED IDENTITY" Foreground="#D6D6DC"
                                           FontWeight="SemiBold" FontSize="12"/>
                            </StackPanel>
                            <TextBlock x:Name="SelectedName" Text="Select a profile"
                                       TextWrapping="Wrap" Foreground="#F0EFF2"
                                       FontWeight="SemiBold" FontSize="26" Margin="0,5,0,6"/>
                            <TextBlock x:Name="SelectedType" Text="No profile selected"
                                       Foreground="#C5ADBB" FontSize="12"/>
                            <TextBlock x:Name="SelectedPath" TextWrapping="Wrap"
                                       Foreground="#91939E" FontSize="11"
                                       Margin="0,12,0,18"/>
                            <Button x:Name="LaunchButton" Content="&#x2726;  Launch Antigravity"
                                    Style="{StaticResource AccentButton}" Margin="0,0,0,12"/>
                            <CheckBox x:Name="IsolatedAuthCheck" Content="Independent login" IsChecked="True"
                                      Margin="0,0,0,7"/>
                            <TextBlock Text="Store sign-in files separately for this profile. Keep profile folders private."
                                       Foreground="#9B96A0" TextWrapping="Wrap"
                                       FontSize="11" Margin="0,0,0,14"/>
                            <Button x:Name="OpenFolderButton" Content="Open profile folder"
                                    Margin="0,0,0,18"/>
                            <Border Background="#644A6C" Height="1" Opacity="0.4"
                                    Margin="0,0,0,17"/>
                            <TextBlock Text="RENAME PROFILE" Foreground="#D2CCD5"
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
                                       TextWrapping="Wrap" Foreground="#878892" FontSize="11"/>
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
                           Foreground="#BFC1C8" FontSize="11"
                           TextTrimming="CharacterEllipsis" VerticalAlignment="Center"/>
                <TextBlock Grid.Column="1" Text="&#x2726;   FROST / NEON"
                           Foreground="#92949E" FontSize="10" Margin="12,0,0,0"
                           VerticalAlignment="Center"/>
            </Grid>
        </Grid>
        <Canvas x:Name="FxSparks" ClipToBounds="True" Panel.ZIndex="20" IsHitTestVisible="False"/>
    </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$script:Window = [Windows.Markup.XamlReader]::Load($reader)

# Keep animated visuals in a separate source file and disable them cleanly
# when the runtime cannot compile the optional effect engine.
$script:FxSky = $script:Window.FindName('FxSky')
$script:FxSparks = $script:Window.FindName('FxSparks')
$effectsFile = Join-Path $PSScriptRoot 'multigravity-effects.cs'
if ((Test-Path -LiteralPath $effectsFile) -and ($env:MULTIGRAVITY_DISABLE_FX -ne '1')) {
    try {
        if (-not ('Multigravity.FrostEffects' -as [type])) {
            $references = @(
                [System.Windows.Window].Assembly.Location,
                [System.Windows.Media.Brush].Assembly.Location,
                [System.Windows.DependencyObject].Assembly.Location,
                [System.Windows.Controls.Canvas].Assembly.Location,
                [System.Xaml.XamlObjectWriter].Assembly.Location
            ) | Select-Object -Unique
            Add-Type -Path $effectsFile -ReferencedAssemblies $references -ErrorAction Stop
        }
        $script:FxEngine = [Multigravity.FrostEffects]::Attach(
            $script:Window, $script:FxSky, $script:FxSparks)
    } catch {
        $script:FxLoadError = $_.Exception.Message
        Write-Warning "Decorative effects disabled: $_"
    }
}


# Set the window and taskbar icon from the icon bundled by install.ps1.
$iconPath = Join-Path $PSScriptRoot 'multigravity-gui-icon.png'
if (Test-Path -LiteralPath $iconPath) {
    $iconStream = $null
    try {
        $iconBytes = [System.IO.File]::ReadAllBytes($iconPath)
        $iconStream = [System.IO.MemoryStream]::new($iconBytes)
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

# A shortcut's .IconLocation alone doesn't change the running PowerShell
# process icon. Set the WPF window's native small and large icons explicitly.
$nativeIconPath = Join-Path $PSScriptRoot 'multigravity-gui.ico'
if (Test-Path -LiteralPath $nativeIconPath) {
    try {
        $script:NativeIcon = [System.Drawing.Icon]::new($nativeIconPath)
        $script:Window.Add_SourceInitialized({
            $helper = [System.Windows.Interop.WindowInteropHelper]::new($script:Window)
            $hwnd = $helper.Handle
            if ($hwnd -ne [IntPtr]::Zero) {
                [void][MultigravityTaskbar]::SendMessage($hwnd, 0x80, [IntPtr]1, $script:NativeIcon.Handle)
                [void][MultigravityTaskbar]::SendMessage($hwnd, 0x80, [IntPtr]0, $script:NativeIcon.Handle)
            }
        })
        $script:Window.Add_Closed({
            if ($null -ne $script:NativeIcon) { $script:NativeIcon.Dispose() }
        })
    } catch {
        Write-Warning "Could not set native Multigravity taskbar icon: $_"
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
if ($script:FxLoadError) {
    $script:StatusText.Text = 'Visual effects unavailable: ' + $script:FxLoadError
}

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

# Small entrance and star shimmer animations; intentionally no full-screen motion.
$script:Window.Add_ContentRendered({
    $header = $script:Window.FindName('HeaderLayout')
    $header.Opacity = 0
    $header.RenderTransform = [System.Windows.Media.TranslateTransform]::new(0, 9)

    $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
    $fadeIn.From = 0.0
    $fadeIn.To = 1.0
    $fadeIn.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(360))
    $header.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeIn)

    $slideIn = New-Object System.Windows.Media.Animation.DoubleAnimation
    $slideIn.From = 9.0
    $slideIn.To = 0.0
    $slideIn.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(430))
    $ease = New-Object System.Windows.Media.Animation.CubicEase
    $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
    $slideIn.EasingFunction = $ease
    $header.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $slideIn)

    $spark = $script:Window.FindName('OrbitSpark')
    if ($null -ne $spark) {
        $twinkle = New-Object System.Windows.Media.Animation.DoubleAnimation
        $twinkle.From = 0.45
        $twinkle.To = 0.96
        $twinkle.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds(2.8))
        $twinkle.AutoReverse = $true
        $twinkle.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $spark.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $twinkle)
    }
})

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
        # A light identity fade on selection, without rebuilding the panel.
        $script:SelectedName.BeginAnimation(
            [System.Windows.UIElement]::OpacityProperty,
            [System.Windows.Media.Animation.DoubleAnimation]::new(
                [double]0.28, [double]1.0,
                [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(210))))
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
