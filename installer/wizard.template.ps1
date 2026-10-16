# ULTRON setup wizard (custom dark UI, Windows PowerShell 5.1 + WPF).
# Run by the ULTRON-Setup exe. Can also run headless:  -Silent [-InstallDir <path>]
# Exit codes: 0 installed, 1 failed (already shown to the user), 2 cancelled, 3 UI could not start.
param(
  [string]$Payload = '',
  [switch]$Silent,
  [string]$InstallDir = '',
  [string]$Gemini = '',
  [string]$Fish = '',
  [string]$Voice = ''
)
$ErrorActionPreference = 'Stop'
$script:Version = '1.3.3'
$script:IsWin = ($env:OS -eq 'Windows_NT')
$script:LogFile = Join-Path ([System.IO.Path]::GetTempPath()) 'ultron-setup.log'
function Write-Log([string]$m) { try { Add-Content -Path $script:LogFile -Value ("{0} {1}" -f (Get-Date -Format s), $m) } catch {} }
Write-Log "Setup started. Silent=$Silent Payload=$Payload"

# ------------------------------------------------------------------ install logic (no UI)
function Get-DefaultDir {
  if ($script:IsWin) {
    try { $p = (Get-ItemProperty -Path 'HKCU:\Software\ULTRON' -Name InstallDir -ErrorAction Stop).InstallDir; if ($p) { return [string]$p } } catch {}
    return (Join-Path $env:LOCALAPPDATA 'Programs\ULTRON')
  }
  return (Join-Path ([System.IO.Path]::GetTempPath()) 'ultron-test-install')
}

function Test-Dir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return 'Please choose a folder.' }
  if (-not [System.IO.Path]::IsPathRooted($p)) { return 'Please enter a full path, for example C:\Users\you\ULTRON.' }
  try { $full = [System.IO.Path]::GetFullPath($p) } catch { return 'That folder path is not valid.' }
  $r = [System.IO.Path]::GetPathRoot($full)
  if ($full.TrimEnd('\', '/') -eq $r.TrimEnd('\', '/')) { return 'Please choose a folder, not a whole drive.' }
  return $null
}

function Get-FreeMB([string]$p) {
  try {
    $r = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($p))
    $d = New-Object System.IO.DriveInfo($r)
    return [int]($d.AvailableFreeSpace / 1MB)
  } catch { return 99999 }
}

function Test-KeyText([string]$s) {
  if ([string]::IsNullOrEmpty($s)) { return $true }
  return ($s -match '^[A-Za-z0-9_.:\-/@+=]{1,300}$')
}

function Stop-Ultron([string]$dir) {
  if (-not $script:IsWin) { return }
  $root = [System.IO.Path]::GetFullPath($dir)
  foreach ($p in @(Get-Process -Name 'ULTRON' -ErrorAction SilentlyContinue)) {
    try {
      if ($p.Path -and $p.Path.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        $p.Kill(); [void]$p.WaitForExit(4000)
      }
    } catch {}
  }
}

function Install-Files([string]$zip, [string]$dir, [scriptblock]$onProgress) {
  if (-not (Test-Path -LiteralPath $zip)) { throw "The setup package is missing: $zip" }
  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $root = [System.IO.Path]::GetFullPath($dir)
  if (-not $root.EndsWith([string][System.IO.Path]::DirectorySeparatorChar)) { $root += [System.IO.Path]::DirectorySeparatorChar }
  [void][System.IO.Directory]::CreateDirectory($root)
  $za = [System.IO.Compression.ZipFile]::OpenRead($zip)
  try {
    $total = [long]0
    foreach ($e in $za.Entries) { $total += $e.Length }
    if ($total -lt 1) { $total = 1 }
    $done = [long]0; $i = 0; $written = New-Object System.Collections.Generic.List[string]
    foreach ($e in $za.Entries) {
      $i++
      $dest = [System.IO.Path]::GetFullPath((Join-Path $root $e.FullName))
      if (-not $dest.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) { continue }   # never write outside the install folder
      if ($e.FullName.EndsWith('/')) { [void][System.IO.Directory]::CreateDirectory($dest); continue }
      [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($dest))
      try { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dest, $true) }
      catch { Start-Sleep -Milliseconds 700; [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dest, $true) }
      $done += $e.Length
      $written.Add($e.FullName)
      if ($onProgress -and (($i % 6) -eq 0 -or $e.Length -gt 4MB)) { & $onProgress ([int](100 * $done / $total)) $e.Name }
    }
    # the uninstaller removes exactly these files and nothing else
    $written.Add('install.manifest')
    [System.IO.File]::WriteAllLines((Join-Path $root 'install.manifest'), $written.ToArray())
  } finally { $za.Dispose() }
  if ($onProgress) { & $onProgress 100 '' }
}

function New-Shortcut([string]$path, [string]$target, [string]$arguments, [string]$icon, [string]$work) {
  $sh = New-Object -ComObject WScript.Shell
  $s = $sh.CreateShortcut($path)
  $s.TargetPath = $target
  if ($arguments) { $s.Arguments = $arguments }
  $s.WorkingDirectory = $work
  if ($icon) { $s.IconLocation = $icon }
  $s.Description = 'ULTRON desktop AI assistant'
  $s.Save()
}

function Save-Keys([string]$gem, [string]$fish, [string]$voice) {
  $d = if ($script:IsWin) { Join-Path $env:APPDATA 'ULTRON' } else { Join-Path ([System.IO.Path]::GetTempPath()) 'ultron-test-appdata' }
  $f = Join-Path $d '.env'
  if (Test-Path -LiteralPath $f) { return 'kept' }
  if (-not ($gem -or $fish -or $voice)) { return 'none' }
  [void][System.IO.Directory]::CreateDirectory($d)
  $lines = @('# Written by the ULTRON installer. You can change these in ULTRON > Settings.')
  if ($gem) { $lines += "GEMINI_API_KEY=$gem" }
  if ($fish) { $lines += "FISH_API_KEY=$fish" }
  if ($voice) { $lines += "FISH_VOICE_ID=$voice" }
  [System.IO.File]::WriteAllText($f, (($lines -join "`r`n") + "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
  return 'written'
}

function Test-ExistingEnv {
  if (-not $script:IsWin) { return $false }
  return (Test-Path -LiteralPath (Join-Path $env:APPDATA 'ULTRON\.env'))
}

function Complete-Install([string]$dir, [bool]$desktop, [string]$gem, [string]$fish, [string]$voice) {
  $exe = Join-Path $dir 'ULTRON.exe'
  $ico = Join-Path $dir 'icon.ico'
  $psArgs = '-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' + (Join-Path $dir 'uninstall.ps1') + '"'
  if ($script:IsWin) {
    $sm = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\ULTRON'
    [void][System.IO.Directory]::CreateDirectory($sm)
    New-Shortcut (Join-Path $sm 'ULTRON.lnk') $exe '' $ico $dir
    New-Shortcut (Join-Path $sm 'Uninstall ULTRON.lnk') 'powershell.exe' $psArgs $ico $dir
    $dk = [Environment]::GetFolderPath('Desktop')
    if ($desktop -and $dk) { New-Shortcut (Join-Path $dk 'ULTRON.lnk') $exe '' $ico $dir }
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ULTRON'
    [void](New-Item -Path $key -Force)
    $vals = @{
      DisplayName = 'ULTRON'; DisplayVersion = $script:Version; Publisher = 'ULTRON'
      DisplayIcon = $ico; InstallLocation = $dir
      UninstallString = ('powershell.exe ' + $psArgs)
    }
    foreach ($k in $vals.Keys) { [void](New-ItemProperty -Path $key -Name $k -Value $vals[$k] -PropertyType String -Force) }
    foreach ($k in 'NoModify', 'NoRepair') { [void](New-ItemProperty -Path $key -Name $k -Value 1 -PropertyType DWord -Force) }
    [void](New-ItemProperty -Path $key -Name 'EstimatedSize' -Value 400000 -PropertyType DWord -Force)
    [void](New-Item -Path 'HKCU:\Software\ULTRON' -Force)
    [void](New-ItemProperty -Path 'HKCU:\Software\ULTRON' -Name 'InstallDir' -Value $dir -PropertyType String -Force)
  }
  return (Save-Keys $gem $fish $voice)
}

function Test-Ollama {
  if (-not $script:IsWin) { return $true }
  if (Get-Command ollama -ErrorAction SilentlyContinue) { return $true }
  return (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'))
}

# ------------------------------------------------------------------ silent mode
if ($Silent) {
  try {
    $dir = if ($InstallDir) { $InstallDir } else { Get-DefaultDir }
    $err = Test-Dir $dir
    if ($err) { throw $err }
    Stop-Ultron $dir
    Install-Files $Payload $dir $null
    [void](Complete-Install $dir $true $Gemini $Fish $Voice)
    Write-Log "Silent install finished: $dir"
    exit 0
  } catch {
    Write-Log "Silent install failed: $($_.Exception.Message)"
    exit 1
  }
}

# ------------------------------------------------------------------ the custom UI
$IconB64 = '@@ICON_B64@@'

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ULTRON Setup" Width="820" Height="540" WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" ResizeMode="NoResize" WindowStartupLocation="CenterScreen"
        FontFamily="Segoe UI" TextOptions.TextFormattingMode="Display" UseLayoutRounding="True">
  <Window.Resources>
    <Style x:Key="Primary" TargetType="Button">
      <Setter Property="Foreground" Value="#1A0405"/><Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="FontSize" Value="14"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="40"/><Setter Property="MinWidth" Value="120"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="bd" CornerRadius="12" Background="#FF3030" Padding="20,0">
          <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="#FF5757"/></Trigger>
          <Trigger Property="IsPressed" Value="True"><Setter TargetName="bd" Property="Background" Value="#D82020"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter TargetName="bd" Property="Background" Value="#3A1A1C"/><Setter Property="Foreground" Value="#7A5A5C"/></Trigger>
        </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="Ghost" TargetType="Button">
      <Setter Property="Foreground" Value="#E8D4D4"/><Setter Property="FontSize" Value="14"/>
      <Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="40"/><Setter Property="MinWidth" Value="96"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="bd" CornerRadius="12" Background="Transparent" BorderBrush="#4A1519" BorderThickness="1.5" Padding="18,0">
          <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="BorderBrush" Value="#FF3030"/><Setter TargetName="bd" Property="Background" Value="#1C0B0D"/></Trigger>
        </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="CloseBtn" TargetType="Button">
      <Setter Property="Foreground" Value="#A58B8D"/><Setter Property="FontSize" Value="15"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Width" Value="36"/><Setter Property="Height" Value="32"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="bd" CornerRadius="8" Background="Transparent">
          <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="#3A1214"/><Setter Property="Foreground" Value="#FFFFFF"/></Trigger>
        </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="TextBox">
      <Setter Property="Foreground" Value="#F4E1E1"/><Setter Property="CaretBrush" Value="#FF3030"/>
      <Setter Property="SelectionBrush" Value="#FF3030"/><Setter Property="FontSize" Value="14"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="TextBox">
        <Border x:Name="bd" Background="#140A0C" BorderBrush="#4A1519" BorderThickness="1.5" CornerRadius="10" Padding="12,0" Height="40">
          <ScrollViewer x:Name="PART_ContentHost" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="bd" Property="BorderBrush" Value="#FF3030"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/></Trigger>
        </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="PasswordBox">
      <Setter Property="Foreground" Value="#F4E1E1"/><Setter Property="CaretBrush" Value="#FF3030"/>
      <Setter Property="SelectionBrush" Value="#FF3030"/><Setter Property="FontSize" Value="14"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="PasswordBox">
        <Border x:Name="bd" Background="#140A0C" BorderBrush="#4A1519" BorderThickness="1.5" CornerRadius="10" Padding="12,0" Height="40">
          <ScrollViewer x:Name="PART_ContentHost" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="bd" Property="BorderBrush" Value="#FF3030"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/></Trigger>
        </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#E8D4D4"/><Setter Property="FontSize" Value="14"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="CheckBox">
        <StackPanel Orientation="Horizontal" Background="Transparent">
          <Border x:Name="box" Width="22" Height="22" CornerRadius="6" BorderThickness="1.5" BorderBrush="#5A2226" Background="#140A0C" VerticalAlignment="Center">
            <Path x:Name="tick" Data="M5,11 L9,15 L17,6" Stroke="#FF3030" StrokeThickness="2.4" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Visibility="Collapsed"/>
          </Border>
          <ContentPresenter Margin="10,0,0,0" VerticalAlignment="Center"/>
        </StackPanel>
        <ControlTemplate.Triggers>
          <Trigger Property="IsChecked" Value="True"><Setter TargetName="tick" Property="Visibility" Value="Visible"/><Setter TargetName="box" Property="BorderBrush" Value="#FF3030"/></Trigger>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="box" Property="BorderBrush" Value="#FF3030"/></Trigger>
        </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
  </Window.Resources>

  <Grid>
    <Border Margin="14" CornerRadius="18" Background="#0B0607" BorderBrush="#2A1013" BorderThickness="1">
      <Border.Effect><DropShadowEffect BlurRadius="26" ShadowDepth="0" Opacity="0.75" Color="#000000"/></Border.Effect>
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="232"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>

        <!-- left rail -->
        <Border Grid.Column="0" CornerRadius="18,0,0,18">
          <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#1D080B" Offset="0"/><GradientStop Color="#0D0506" Offset="1"/></LinearGradientBrush>
          </Border.Background>
          <Grid Margin="28,36,20,22">
            <StackPanel>
              <Image x:Name="Logo" Width="68" Height="68" HorizontalAlignment="Left"/>
              <TextBlock Text="ULTRON" FontFamily="Bahnschrift, Segoe UI" FontSize="28" FontWeight="Bold" Foreground="#FF3030" Margin="0,16,0,0"/>
              <TextBlock Text="Desktop AI assistant" FontSize="12" Foreground="#A58B8D" Margin="0,2,0,40"/>
              <StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,18"><Ellipse x:Name="Dot1" Width="12" Height="12" Fill="#FF3030"/><TextBlock x:Name="Lbl1" Text="Welcome" FontSize="14" Foreground="#FFFFFF" Margin="14,-2,0,0"/></StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,18"><Ellipse x:Name="Dot2" Width="12" Height="12" Fill="#3A1A1C"/><TextBlock x:Name="Lbl2" Text="Location" FontSize="14" Foreground="#7A5A5C" Margin="14,-2,0,0"/></StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,18"><Ellipse x:Name="Dot3" Width="12" Height="12" Fill="#3A1A1C"/><TextBlock x:Name="Lbl3" Text="Services" FontSize="14" Foreground="#7A5A5C" Margin="14,-2,0,0"/></StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,18"><Ellipse x:Name="Dot4" Width="12" Height="12" Fill="#3A1A1C"/><TextBlock x:Name="Lbl4" Text="Install" FontSize="14" Foreground="#7A5A5C" Margin="14,-2,0,0"/></StackPanel>
                <StackPanel Orientation="Horizontal"><Ellipse x:Name="Dot5" Width="12" Height="12" Fill="#3A1A1C"/><TextBlock x:Name="Lbl5" Text="Done" FontSize="14" Foreground="#7A5A5C" Margin="14,-2,0,0"/></StackPanel>
              </StackPanel>
            </StackPanel>
            <TextBlock x:Name="VerText" VerticalAlignment="Bottom" FontSize="11" Foreground="#6E5557"/>
          </Grid>
        </Border>

        <!-- right side -->
        <Grid Grid.Column="1" Margin="36,0,30,26">
          <Grid.RowDefinitions><RowDefinition Height="52"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>

          <Grid x:Name="TitleBar" Grid.Row="0" Background="Transparent">
            <TextBlock Text="SETUP" FontSize="11" Foreground="#6E5557" VerticalAlignment="Center" FontWeight="SemiBold"/>
            <Button x:Name="BtnClose" Style="{StaticResource CloseBtn}" Content="&#x2715;" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,-12,0"/>
          </Grid>

          <Grid Grid.Row="1">
            <!-- 1 welcome -->
            <StackPanel x:Name="PageWelcome" VerticalAlignment="Center">
              <TextBlock Text="Welcome to ULTRON" FontSize="30" FontWeight="Bold" Foreground="#F4E1E1"/>
              <TextBlock Text="Your voice-first desktop AI assistant. Setup takes about a minute." FontSize="14" Foreground="#A58B8D" Margin="0,8,0,22" TextWrapping="Wrap"/>
              <Border Background="#120A0C" CornerRadius="10" Padding="0" Margin="0,0,0,10"><Grid><Border Width="4" CornerRadius="10,0,0,10" Background="#FF3030" HorizontalAlignment="Left"/>
                <StackPanel Margin="20,10,12,10"><TextBlock Text="Online and offline" FontSize="14" FontWeight="SemiBold" Foreground="#F4E1E1"/><TextBlock Text="Gemini when you are connected, a local Gemma model when you are not." FontSize="12" Foreground="#A58B8D" TextWrapping="Wrap"/></StackPanel></Grid></Border>
              <Border Background="#120A0C" CornerRadius="10" Padding="0" Margin="0,0,0,10"><Grid><Border Width="4" CornerRadius="10,0,0,10" Background="#FF3030" HorizontalAlignment="Left"/>
                <StackPanel Margin="20,10,12,10"><TextBlock Text="A real voice" FontSize="14" FontWeight="SemiBold" Foreground="#F4E1E1"/><TextBlock Text="Fish Audio voice, with an automatic fallback to the built-in Windows voice." FontSize="12" Foreground="#A58B8D" TextWrapping="Wrap"/></StackPanel></Grid></Border>
              <Border Background="#120A0C" CornerRadius="10" Padding="0"><Grid><Border Width="4" CornerRadius="10,0,0,10" Background="#FF3030" HorizontalAlignment="Left"/>
                <StackPanel Margin="20,10,12,10"><TextBlock Text="Briefings and tools" FontSize="14" FontWeight="SemiBold" Foreground="#F4E1E1"/><TextBlock Text="World and market news, app launching, and screen reading." FontSize="12" Foreground="#A58B8D" TextWrapping="Wrap"/></StackPanel></Grid></Border>
              <CheckBox x:Name="ChkDesktop" Content="Create a desktop shortcut" IsChecked="True" Margin="0,22,0,0"/>
            </StackPanel>

            <!-- 2 location -->
            <StackPanel x:Name="PageLocation" VerticalAlignment="Center" Visibility="Collapsed">
              <TextBlock Text="Where should ULTRON live?" FontSize="28" FontWeight="Bold" Foreground="#F4E1E1"/>
              <TextBlock Text="Installs for your account only. No administrator rights needed." FontSize="14" Foreground="#A58B8D" Margin="0,8,0,26" TextWrapping="Wrap"/>
              <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBox x:Name="TxtDir" Grid.Column="0"/>
                <Button x:Name="BtnBrowse" Grid.Column="1" Style="{StaticResource Ghost}" Content="Browse" Margin="10,0,0,0"/></Grid>
              <TextBlock x:Name="SpaceNote" Text="Needs about 400 MB of free space." FontSize="12" Foreground="#7A5A5C" Margin="2,10,0,0"/>
            </StackPanel>

            <!-- 3 services -->
            <StackPanel x:Name="PageKeys" VerticalAlignment="Center" Visibility="Collapsed">
              <TextBlock Text="Connect your services" FontSize="28" FontWeight="Bold" Foreground="#F4E1E1"/>
              <TextBlock Text="All optional. You can add or change these later in ULTRON, under Settings." FontSize="14" Foreground="#A58B8D" Margin="0,8,0,20" TextWrapping="Wrap"/>
              <TextBlock Text="Gemini API key (online AI)" FontSize="12" Foreground="#C9AEB0" Margin="2,0,0,5"/>
              <PasswordBox x:Name="PwGem" Margin="0,0,0,12"/>
              <TextBlock Text="Fish Audio API key (voice)" FontSize="12" Foreground="#C9AEB0" Margin="2,0,0,5"/>
              <PasswordBox x:Name="PwFish" Margin="0,0,0,12"/>
              <TextBlock Text="Fish voice ID (optional)" FontSize="12" Foreground="#C9AEB0" Margin="2,0,0,5"/>
              <TextBox x:Name="TxtVoice"/>
              <TextBlock x:Name="KeysNote" Text="Keys stay on this PC, in your private ULTRON settings file." FontSize="12" Foreground="#7A5A5C" Margin="2,12,0,0" TextWrapping="Wrap"/>
            </StackPanel>

            <!-- 4 install -->
            <StackPanel x:Name="PageInstall" VerticalAlignment="Center" Visibility="Collapsed">
              <TextBlock Text="Installing ULTRON" FontSize="28" FontWeight="Bold" Foreground="#F4E1E1"/>
              <TextBlock x:Name="InstStatus" Text="Preparing..." FontSize="14" Foreground="#A58B8D" Margin="0,8,0,28"/>
              <ProgressBar x:Name="Prog" Height="12" Minimum="0" Maximum="100" Value="0">
                <ProgressBar.Template><ControlTemplate TargetType="ProgressBar"><Grid>
                  <Border x:Name="PART_Track" CornerRadius="6" Background="#1E0F11"/>
                  <Border x:Name="PART_Indicator" CornerRadius="6" Background="#FF3030" HorizontalAlignment="Left"/>
                </Grid></ControlTemplate></ProgressBar.Template>
              </ProgressBar>
              <Grid Margin="0,10,0,0"><TextBlock x:Name="InstFile" FontSize="11" Foreground="#7A5A5C" TextTrimming="CharacterEllipsis" Margin="0,0,60,0"/>
                <TextBlock x:Name="InstPct" Text="0%" FontSize="12" Foreground="#C9AEB0" HorizontalAlignment="Right"/></Grid>
              <TextBlock x:Name="InstError" Visibility="Collapsed" FontSize="12" Foreground="#FF6B6B" TextWrapping="Wrap" Margin="0,20,0,0"/>
            </StackPanel>

            <!-- 5 done -->
            <StackPanel x:Name="PageDone" VerticalAlignment="Center" Visibility="Collapsed">
              <Grid Width="54" Height="54" HorizontalAlignment="Left" Margin="0,0,0,16">
                <Ellipse Fill="#FF3030"/>
                <Path Data="M15,28 L24,37 L40,18" Stroke="#1A0405" StrokeThickness="4.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"/>
              </Grid>
              <TextBlock Text="You're all set" FontSize="30" FontWeight="Bold" Foreground="#F4E1E1"/>
              <TextBlock x:Name="DoneInfo" FontSize="14" Foreground="#A58B8D" Margin="0,8,0,18" TextWrapping="Wrap"/>
              <Border x:Name="OllamaCard" Background="#120A0C" CornerRadius="10" Padding="16,12" Margin="0,0,0,18">
                <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <StackPanel><TextBlock Text="Want offline mode?" FontSize="14" FontWeight="SemiBold" Foreground="#F4E1E1"/>
                    <TextBlock Text="Install Ollama, then run:  ollama pull gemma4:e2b" FontSize="12" Foreground="#A58B8D" Margin="0,3,0,0" TextWrapping="Wrap"/></StackPanel>
                  <Button x:Name="BtnOllama" Grid.Column="1" Style="{StaticResource Ghost}" Content="Get Ollama" Height="34" Margin="12,0,0,0"/></Grid>
              </Border>
              <CheckBox x:Name="ChkLaunch" Content="Launch ULTRON now" IsChecked="True"/>
            </StackPanel>
          </Grid>

          <Grid Grid.Row="2">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <TextBlock x:Name="Hint" Grid.Column="0" FontSize="12" Foreground="#FF6B6B" VerticalAlignment="Center" TextWrapping="Wrap" Margin="0,0,16,0"/>
            <StackPanel Grid.Column="1" Orientation="Horizontal">
              <Button x:Name="BtnBack" Style="{StaticResource Ghost}" Content="Back" Margin="0,0,10,0"/>
              <Button x:Name="BtnNext" Style="{StaticResource Primary}" Content="Get started"/>
            </StackPanel>
          </Grid>
        </Grid>
      </Grid>
    </Border>

    <!-- confirm overlay -->
    <Border x:Name="Overlay" Margin="14" CornerRadius="18" Background="#CC000000" Visibility="Collapsed">
      <Border Width="360" Padding="26" CornerRadius="16" Background="#140A0C" BorderBrush="#4A1519" BorderThickness="1.5" HorizontalAlignment="Center" VerticalAlignment="Center">
        <StackPanel>
          <TextBlock Text="Cancel setup?" FontSize="20" FontWeight="Bold" Foreground="#F4E1E1"/>
          <TextBlock Text="ULTRON has not been installed yet." FontSize="13" Foreground="#A58B8D" Margin="0,6,0,22"/>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
            <Button x:Name="BtnStay" Style="{StaticResource Ghost}" Content="Keep going" Margin="0,0,10,0"/>
            <Button x:Name="BtnQuit" Style="{StaticResource Primary}" Content="Quit setup" MinWidth="100"/>
          </StackPanel>
        </StackPanel>
      </Border>
    </Border>
  </Grid>
</Window>
'@

try {
  Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml
  Add-Type -AssemblyName System.Windows.Forms
  $win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$xaml)))
} catch {
  Write-Log "UI could not start: $($_.Exception.Message)"
  exit 3
}

function El([string]$n) { return $win.FindName($n) }
function Brush([string]$hex) { return (New-Object System.Windows.Media.BrushConverter).ConvertFromString($hex) }
function DoEvents {
  $script:frame = New-Object System.Windows.Threading.DispatcherFrame
  [void][System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
    [System.Windows.Threading.DispatcherPriority]::Background, [Action]{ $script:frame.Continue = $false })
  [System.Windows.Threading.Dispatcher]::PushFrame($script:frame)
}

try {
  $bytes = [Convert]::FromBase64String($IconB64)
  $ms = New-Object System.IO.MemoryStream(, $bytes)
  $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
  $bmp.BeginInit(); $bmp.StreamSource = $ms; $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad; $bmp.EndInit(); $bmp.Freeze()
  (El 'Logo').Source = $bmp
  $win.Icon = $bmp
} catch { Write-Log "Logo failed: $($_.Exception.Message)" }

(El 'VerText').Text = "v$script:Version"
(El 'TxtDir').Text = Get-DefaultDir
$script:page = 1; $script:busy = $false; $script:failed = $false; $script:exitCode = 2
$script:installDir = ''
$pages = 'PageWelcome', 'PageLocation', 'PageKeys', 'PageInstall', 'PageDone'

function Show-Hint([string]$t) { (El 'Hint').Text = $t }

function Show-Page([int]$n) {
  $script:page = $n
  Show-Hint ''
  for ($i = 1; $i -le 5; $i++) {
    (El $pages[$i - 1]).Visibility = $(if ($i -eq $n) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed })
    $dot = El "Dot$i"; $lbl = El "Lbl$i"
    if ($i -lt $n) { $dot.Fill = Brush '#FF3030'; $lbl.Foreground = Brush '#C9AEB0'; $lbl.FontWeight = [System.Windows.FontWeights]::Normal }
    elseif ($i -eq $n) { $dot.Fill = Brush '#FF3030'; $lbl.Foreground = Brush '#FFFFFF'; $lbl.FontWeight = [System.Windows.FontWeights]::SemiBold }
    else { $dot.Fill = Brush '#3A1A1C'; $lbl.Foreground = Brush '#7A5A5C'; $lbl.FontWeight = [System.Windows.FontWeights]::Normal }
  }
  $back = El 'BtnBack'; $next = El 'BtnNext'
  $vis = [System.Windows.Visibility]::Visible; $col = [System.Windows.Visibility]::Collapsed
  switch ($n) {
    1 { $back.Visibility = $col; $next.Visibility = $vis; $next.Content = 'Get started' }
    2 { $back.Visibility = $vis; $next.Visibility = $vis; $next.Content = 'Continue' }
    3 { $back.Visibility = $vis; $next.Visibility = $vis; $next.Content = 'Install' }
    4 { $back.Visibility = $col; $next.Visibility = $col }
    5 { $back.Visibility = $col; $next.Visibility = $vis; $next.Content = 'Finish' }
  }
}

function Set-Status([string]$text, [int]$pct, [string]$file) {
  (El 'InstStatus').Text = $text
  (El 'Prog').Value = $pct
  (El 'InstPct').Text = "$pct%"
  (El 'InstFile').Text = $file
  DoEvents
}

function Start-Install {
  $script:busy = $true
  $dir = (El 'TxtDir').Text.Trim()
  $gem = (El 'PwGem').Password.Trim(); $fish = (El 'PwFish').Password.Trim(); $voice = (El 'TxtVoice').Text.Trim()
  $desk = [bool](El 'ChkDesktop').IsChecked
  DoEvents
  try {
    Set-Status 'Closing any running copy of ULTRON...' 0 ''
    Stop-Ultron $dir
    Set-Status 'Copying files...' 0 ''
    Install-Files $Payload $dir { param($pct, $name) Set-Status 'Copying files...' $pct $name }
    Set-Status 'Creating shortcuts...' 100 ''
    $state = Complete-Install $dir $desk $gem $fish $voice
    $script:installDir = $dir
    $info = "ULTRON is installed in $dir. "
    if ($state -eq 'written') { $info += 'Your keys were saved.' }
    elseif ($state -eq 'kept') { $info += 'Your existing settings were kept.' }
    else { $info += 'Add your API keys any time in ULTRON, under Settings.' }
    (El 'DoneInfo').Text = $info
    (El 'OllamaCard').Visibility = $(if (Test-Ollama) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible })
    $script:exitCode = 0
    Write-Log "Install finished: $dir"
    Show-Page 5
  } catch {
    $script:failed = $true; $script:exitCode = 1
    Write-Log "ERROR: $($_.Exception.Message)"
    (El 'InstStatus').Text = 'Setup could not finish.'
    (El 'InstError').Text = "$($_.Exception.Message)`nDetails: $script:LogFile"
    (El 'InstError').Visibility = [System.Windows.Visibility]::Visible
    $n = El 'BtnNext'; $n.Visibility = [System.Windows.Visibility]::Visible; $n.Content = 'Close'
  } finally { $script:busy = $false }
}

function Invoke-Next {
  if ($script:busy) { return }
  Show-Hint ''
  switch ($script:page) {
    1 { Show-Page 2 }
    2 {
      $dir = (El 'TxtDir').Text.Trim()
      $e = Test-Dir $dir
      if ($e) { Show-Hint $e; return }
      $mb = Get-FreeMB $dir
      if ($mb -lt 600) { Show-Hint "Only $mb MB free on that drive. ULTRON needs about 600 MB."; return }
      $has = Test-ExistingEnv
      foreach ($n in 'PwGem', 'PwFish', 'TxtVoice') { (El $n).IsEnabled = (-not $has) }
      (El 'KeysNote').Text = $(if ($has) { 'Existing ULTRON settings were found and will be kept. Change them later in ULTRON, under Settings.' } else { 'Keys stay on this PC, in your private ULTRON settings file.' })
      Show-Page 3
    }
    3 {
      $g = (El 'PwGem').Password.Trim(); $f = (El 'PwFish').Password.Trim(); $v = (El 'TxtVoice').Text.Trim()
      if (-not (Test-KeyText $g)) { Show-Hint 'The Gemini key has characters that keys never contain. Check for stray spaces or quotes.'; return }
      if (-not (Test-KeyText $f)) { Show-Hint 'The Fish key has characters that keys never contain. Check for stray spaces or quotes.'; return }
      if (-not (Test-KeyText $v)) { Show-Hint 'The voice ID has characters that are not allowed.'; return }
      Show-Page 4
      DoEvents
      Start-Install
    }
    4 { if ($script:failed) { $win.Close() } }
    5 {
      if ((El 'ChkLaunch').IsChecked -and $script:installDir) {
        try { Start-Process -FilePath (Join-Path $script:installDir 'ULTRON.exe') -WorkingDirectory $script:installDir } catch { Write-Log "Launch failed: $($_.Exception.Message)" }
      }
      $win.Close()
    }
  }
}

(El 'BtnNext').Add_Click({ Invoke-Next })
(El 'BtnBack').Add_Click({ if (-not $script:busy -and $script:page -gt 1 -and $script:page -lt 4) { Show-Page ($script:page - 1) } })
(El 'BtnBrowse').Add_Click({
  $d = New-Object System.Windows.Forms.FolderBrowserDialog
  $d.Description = 'Choose where to install ULTRON'
  if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $p = $d.SelectedPath
    if ((Split-Path -Leaf $p) -ne 'ULTRON') { $p = Join-Path $p 'ULTRON' }
    (El 'TxtDir').Text = $p
  }
})
(El 'BtnOllama').Add_Click({ try { Start-Process 'https://ollama.com/download' } catch {} })
(El 'TitleBar').Add_MouseLeftButtonDown({ try { $win.DragMove() } catch {} })
(El 'BtnClose').Add_Click({
  if ($script:busy) { return }
  if ($script:page -ge 5 -or $script:failed) { $win.Close() } else { (El 'Overlay').Visibility = [System.Windows.Visibility]::Visible }
})
(El 'BtnStay').Add_Click({ (El 'Overlay').Visibility = [System.Windows.Visibility]::Collapsed })
(El 'BtnQuit').Add_Click({ $script:exitCode = 2; $win.Close() })
$win.Add_Closing({ param($s, $e) if ($script:busy) { $e.Cancel = $true } })

Show-Page 1
try { [void]$win.ShowDialog() } catch { Write-Log "UI error: $($_.Exception.Message)"; exit 1 }
Write-Log "Setup closed with code $script:exitCode"
exit $script:exitCode
