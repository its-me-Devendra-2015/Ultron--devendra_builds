# ULTRON uninstaller (custom dark UI). Removes only the files the installer wrote (install.manifest).
param([string]$Dir = '', [switch]$Relaunched, [switch]$Silent, [switch]$KeepData)
$ErrorActionPreference = 'Stop'
$self = $MyInvocation.MyCommand.Path
if (-not $Dir) { $Dir = Split-Path -Parent $self }
$Dir = $Dir.TrimEnd('\', '/')

# run from a temp copy so the install folder itself can be removed
if (-not $Relaunched) {
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) 'ultron-uninstall.ps1'
  Copy-Item -LiteralPath $self -Destination $tmp -Force
  $a = '-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "{0}" -Dir "{1}" -Relaunched' -f $tmp, $Dir
  if ($Silent) { $a += ' -Silent' }
  if ($KeepData) { $a += ' -KeepData' }
  Start-Process -FilePath 'powershell.exe' -ArgumentList $a
  exit 0
}

function Remove-Ultron([string]$dir, [bool]$wipeData, [scriptblock]$say) {
  $manifest = Join-Path $dir 'install.manifest'
  if (-not (Test-Path -LiteralPath $manifest)) { throw "install.manifest was not found in $dir, so nothing was deleted." }
  $files = @(Get-Content -LiteralPath $manifest | Where-Object { $_ -and -not $_.EndsWith('/') })
  & $say 'Closing ULTRON...' 8
  $root = [System.IO.Path]::GetFullPath($dir)
  foreach ($p in @(Get-Process -Name 'ULTRON' -ErrorAction SilentlyContinue)) {
    try { if ($p.Path -and $p.Path.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) { $p.Kill(); [void]$p.WaitForExit(4000) } } catch {}
  }
  & $say 'Removing shortcuts...' 20
  $links = @()
  $dk = [Environment]::GetFolderPath('Desktop')
  if ($dk) { $links += (Join-Path $dk 'ULTRON.lnk') }
  if ($env:APPDATA) { $links += (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\ULTRON') }
  foreach ($s in $links) {
    try { if (Test-Path -LiteralPath $s) { Remove-Item -LiteralPath $s -Recurse -Force } } catch {}
  }
  & $say 'Removing files...' 40
  $n = 0; $skipSelf = @()
  foreach ($rel in $files) {
    $f = [System.IO.Path]::GetFullPath((Join-Path $root $rel))
    if (-not $f.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
    for ($t = 0; $t -lt 3; $t++) {
      try { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force }; break } catch { Start-Sleep -Milliseconds 500 }
    }
    $n++
    if (($n % 25) -eq 0) { & $say 'Removing files...' ([int](40 + 45 * $n / [math]::Max(1, $files.Count))) }
  }
  # remove folders that are now empty (deepest first); anything you added yourself stays
  $dirs = $files | ForEach-Object { Split-Path -Parent (Join-Path $root $_) } | Sort-Object -Unique | Sort-Object { $_.Length } -Descending
  foreach ($d in $dirs) { try { if ((Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force | Select-Object -First 1)) { Remove-Item -LiteralPath $d -Force } } catch {} }
  try { if ((Test-Path -LiteralPath $root) -and -not (Get-ChildItem -LiteralPath $root -Force | Select-Object -First 1)) { Remove-Item -LiteralPath $root -Force } } catch {}
  & $say 'Cleaning up...' 90
  foreach ($k in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ULTRON', 'HKCU:\Software\ULTRON') { try { Remove-Item -Path $k -Recurse -Force -ErrorAction Stop } catch {} }
  if ($wipeData -and $env:APPDATA) { try { Remove-Item -LiteralPath (Join-Path $env:APPDATA 'ULTRON') -Recurse -Force -ErrorAction Stop } catch {} }
  & $say 'Done' 100
}

if ($Silent) {
  try { Remove-Ultron $Dir (-not $KeepData) { param($t, $p) }; exit 0 } catch { exit 1 }
}

$IconB64 = '@@ICON_B64@@'
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Uninstall ULTRON" Width="560" Height="360" WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI" UseLayoutRounding="True">
  <Window.Resources>
    <Style x:Key="Primary" TargetType="Button">
      <Setter Property="Foreground" Value="#1A0405"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="FontSize" Value="14"/>
      <Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="40"/><Setter Property="MinWidth" Value="120"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="bd" CornerRadius="12" Background="#FF3030" Padding="20,0"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="#FF5757"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter TargetName="bd" Property="Background" Value="#3A1A1C"/></Trigger>
        </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="Ghost" TargetType="Button">
      <Setter Property="Foreground" Value="#E8D4D4"/><Setter Property="FontSize" Value="14"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="40"/><Setter Property="MinWidth" Value="96"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="bd" CornerRadius="12" Background="Transparent" BorderBrush="#4A1519" BorderThickness="1.5" Padding="18,0"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="BorderBrush" Value="#FF3030"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#E8D4D4"/><Setter Property="FontSize" Value="14"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="CheckBox">
        <StackPanel Orientation="Horizontal" Background="Transparent">
          <Border x:Name="box" Width="22" Height="22" CornerRadius="6" BorderThickness="1.5" BorderBrush="#5A2226" Background="#140A0C" VerticalAlignment="Center">
            <Path x:Name="tick" Data="M5,11 L9,15 L17,6" Stroke="#FF3030" StrokeThickness="2.4" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Visibility="Collapsed"/></Border>
          <ContentPresenter Margin="10,0,0,0" VerticalAlignment="Center"/>
        </StackPanel>
        <ControlTemplate.Triggers><Trigger Property="IsChecked" Value="True"><Setter TargetName="tick" Property="Visibility" Value="Visible"/><Setter TargetName="box" Property="BorderBrush" Value="#FF3030"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
  </Window.Resources>
  <Border Margin="14" CornerRadius="18" Background="#0B0607" BorderBrush="#2A1013" BorderThickness="1">
    <Border.Effect><DropShadowEffect BlurRadius="26" ShadowDepth="0" Opacity="0.75" Color="#000000"/></Border.Effect>
    <Grid x:Name="Root" Margin="32,26,32,26">
      <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
      <StackPanel Grid.Row="0" VerticalAlignment="Center">
        <StackPanel Orientation="Horizontal" Margin="0,0,0,18">
          <Image x:Name="Logo" Width="44" Height="44"/>
          <TextBlock Text="ULTRON" FontFamily="Bahnschrift, Segoe UI" FontSize="22" FontWeight="Bold" Foreground="#FF3030" VerticalAlignment="Center" Margin="14,0,0,0"/>
        </StackPanel>
        <TextBlock x:Name="Title" Text="Uninstall ULTRON?" FontSize="26" FontWeight="Bold" Foreground="#F4E1E1"/>
        <TextBlock x:Name="Sub" Text="This removes the app and its shortcuts from this PC." FontSize="14" Foreground="#A58B8D" Margin="0,8,0,18" TextWrapping="Wrap"/>
        <CheckBox x:Name="ChkData" Content="Also delete my saved keys and chat history" IsChecked="False"/>
        <ProgressBar x:Name="Prog" Height="12" Minimum="0" Maximum="100" Value="0" Visibility="Collapsed" Margin="0,6,0,0">
          <ProgressBar.Template><ControlTemplate TargetType="ProgressBar"><Grid>
            <Border x:Name="PART_Track" CornerRadius="6" Background="#1E0F11"/>
            <Border x:Name="PART_Indicator" CornerRadius="6" Background="#FF3030" HorizontalAlignment="Left"/>
          </Grid></ControlTemplate></ProgressBar.Template>
        </ProgressBar>
        <TextBlock x:Name="Err" Visibility="Collapsed" FontSize="12" Foreground="#FF6B6B" TextWrapping="Wrap" Margin="0,14,0,0"/>
      </StackPanel>
      <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
        <Button x:Name="BtnCancel" Style="{StaticResource Ghost}" Content="Cancel" Margin="0,0,10,0"/>
        <Button x:Name="BtnGo" Style="{StaticResource Primary}" Content="Uninstall"/>
      </StackPanel>
    </Grid>
  </Border>
</Window>
'@

try {
  Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml
  $win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$xaml)))
} catch {
  # no UI available: remove silently but keep the user's data
  try { Remove-Ultron $Dir $false { param($t, $p) }; exit 0 } catch { exit 1 }
}
function El([string]$n) { return $win.FindName($n) }
function DoEvents {
  $script:frame = New-Object System.Windows.Threading.DispatcherFrame
  [void][System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [Action]{ $script:frame.Continue = $false })
  [System.Windows.Threading.Dispatcher]::PushFrame($script:frame)
}
try {
  $ms = New-Object System.IO.MemoryStream(, [Convert]::FromBase64String($IconB64))
  $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
  $bmp.BeginInit(); $bmp.StreamSource = $ms; $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad; $bmp.EndInit(); $bmp.Freeze()
  (El 'Logo').Source = $bmp; $win.Icon = $bmp
} catch {}
if ($KeepData) { (El 'ChkData').IsChecked = $false }
$script:busy = $false; $script:finished = $false
(El 'BtnCancel').Add_Click({ if (-not $script:busy) { $win.Close() } })
(El 'Root').Add_MouseLeftButtonDown({ try { $win.DragMove() } catch {} })
(El 'BtnGo').Add_Click({
  if ($script:finished) { $win.Close(); return }
  $script:busy = $true
  $wipe = [bool](El 'ChkData').IsChecked
  (El 'BtnGo').IsEnabled = $false; (El 'BtnCancel').IsEnabled = $false
  (El 'ChkData').Visibility = [System.Windows.Visibility]::Collapsed
  (El 'Prog').Visibility = [System.Windows.Visibility]::Visible
  (El 'Title').Text = 'Removing ULTRON'
  DoEvents
  try {
    Remove-Ultron $Dir $wipe { param($t, $p) (El 'Sub').Text = $t; (El 'Prog').Value = $p; DoEvents }
    (El 'Title').Text = 'ULTRON was removed'
    (El 'Sub').Text = $(if ($wipe) { 'The app and your saved settings are gone.' } else { 'Your keys and chat history were kept, in case you reinstall.' })
    $script:finished = $true
    (El 'BtnGo').Content = 'Close'; (El 'BtnGo').IsEnabled = $true
  } catch {
    (El 'Title').Text = 'Could not finish'
    (El 'Sub').Text = ''
    (El 'Err').Text = $_.Exception.Message; (El 'Err').Visibility = [System.Windows.Visibility]::Visible
    $script:finished = $true
    (El 'BtnGo').Content = 'Close'; (El 'BtnGo').IsEnabled = $true
  } finally { $script:busy = $false }
})
$win.Add_Closing({ param($s, $e) if ($script:busy) { $e.Cancel = $true } })
[void]$win.ShowDialog()
exit 0
