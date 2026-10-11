# Setup-WoW-OneDrive.ps1
# Windows PowerShell 5.1 compatible. Deletes local Interface/WTF in Program Files
# and links them to OneDrive. NO local data is moved to OneDrive.

# --- Auto-elevate to Administrator ---
$currUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "Elevating to Administrator..."
  $args = @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`"")
  Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $args
  exit
}

# --- Config ---
$srcRoot = "C:\Program Files (x86)\World of Warcraft\_retail_"
# Scripts live in the repo; this explicit path remains the production destination.
$dstRoot = "C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\_retail_"
$folders = @("Interface","WTF")

# --- Helpers ---
function Is-ReparsePoint([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return $false }
  try {
    $attrs = (Get-Item -LiteralPath $path -Force).Attributes
    return ($attrs -band [IO.FileAttributes]::ReparsePoint) -ne 0
  } catch { return $false }
}

function Ensure-Directory([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) {
    New-Item -ItemType Directory -Path $path | Out-Null
  }
}

function Stop-WoWIfRunning {
  $wowNames = @("Wow","Wow-64","WowClassic","WowClassicT","WowRetail")
  foreach ($n in $wowNames) {
    Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
      Write-Host ("Stopping process: {0}" -f $_.ProcessName)
      Stop-Process -Id $_.Id -Force
    }
  }
}

function Remove-Any([string]$path) {
  if (Test-Path -LiteralPath $path) {
    Write-Host ("Removing existing: {0}" -f $path)
    try {
      Remove-Item -LiteralPath $path -Force -Recurse -ErrorAction Stop
    } catch {
      # Fallback: mirror an empty dir into it, then remove
      $tmp = Join-Path ([IO.Path]::GetTempPath()) ("empty_" + [guid]::NewGuid().ToString())
      New-Item -ItemType Directory -Path $tmp | Out-Null
      robocopy "$tmp" "$path" /MIR | Out-Null
      Remove-Item -LiteralPath $path -Force -Recurse -ErrorAction SilentlyContinue
      Remove-Item -LiteralPath $tmp -Force -Recurse -ErrorAction SilentlyContinue
    }
  }
}

function New-Junction([string]$linkPath, [string]$targetPath) {
  try {
    New-Item -ItemType Junction -Path $linkPath -Target $targetPath -ErrorAction Stop | Out-Null
  } catch {
    # Fallback for older environments
    cmd /c "mklink /J `"$linkPath`" `"$targetPath`"" | Out-Null
  }
}

function Link-Dir([string]$linkPath, [string]$targetPath) {
  Ensure-Directory (Split-Path -Path $linkPath -Parent)
  Ensure-Directory (Split-Path -Path $targetPath -Parent)
  Ensure-Directory $targetPath

  if (Test-Path -LiteralPath $linkPath) {
    # Replace whatever is there (folder or wrong link)
    Remove-Any $linkPath
  }

  New-Junction -linkPath $linkPath -targetPath $targetPath
  Write-Host ("Linked: {0} -> {1}" -f $linkPath, $targetPath)
}

# --- Start ---
Write-Host "=== WoW OneDrive Link Setup (no local migration) ===" -ForegroundColor Cyan
Write-Host ("Source root: {0}" -f $srcRoot)
Write-Host ("OneDrive root: {0}" -f $dstRoot)

Stop-WoWIfRunning
Ensure-Directory $dstRoot

foreach ($name in $folders) {
  $src = Join-Path -Path $srcRoot -ChildPath $name
  $dst = Join-Path -Path $dstRoot -ChildPath $name

  Write-Host ""
  Write-Host ("--- Processing {0} ---" -f $name)
  Remove-Any $src
  Ensure-Directory $dst
  Link-Dir -linkPath $src -targetPath $dst
}

Write-Host ""
Write-Host "Verifying..."
foreach ($name in $folders) {
  $src = Join-Path -Path $srcRoot -ChildPath $name
  if (Is-ReparsePoint $src) {
    Write-Host ("{0,-12}: LINK" -f $name)
  } else {
    Write-Host ("{0,-12}: NOT A LINK (check manually)" -f $name)
  }
}

Write-Host ""
Write-Host "Done. Local copies under '_retail_' are removed and now point to OneDrive." -ForegroundColor Green
