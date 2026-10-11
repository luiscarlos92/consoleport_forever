# Setup-WoW-CharacterTemplateLinks.ps1
# PS 5.1 compatible. Replaces every character folder with a junction to the template:
# C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\_retail_\WTF\Account\_template_

# --- Auto-elevate to Administrator ---
$currUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "Elevating to Administrator..."
  $args = @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`"")
  Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $args
  exit
}

# --- Paths ---
$AccountsRoot = "C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\_retail_\WTF\Account"
$TemplateDir  = Join-Path -Path $AccountsRoot -ChildPath "_template_"

# account folder format: some digits, '#', then at least one digit (e.g., 119624169#1)
$AccountNamePattern = '^\d+#\d+'

# --- Helpers ---
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
    try {
      Remove-Item -LiteralPath $path -Force -Recurse -ErrorAction Stop
    } catch {
      # Fallback for stubborn items: mirror an empty dir into it, then remove
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
    cmd /c "mklink /J `"$linkPath`" `"$targetPath`"" | Out-Null
  }
}

# --- Start ---
Write-Host "=== WoW Character Template Linker ===" -ForegroundColor Cyan
Write-Host ("Accounts root : {0}" -f $AccountsRoot)
Write-Host ("Template dir  : {0}" -f $TemplateDir)

Ensure-Directory $AccountsRoot
Ensure-Directory $TemplateDir
Ensure-Directory (Join-Path $TemplateDir "SavedVariables") | Out-Null

Stop-WoWIfRunning

$report = New-Object System.Collections.Generic.List[string]

# Iterate accounts (skip _template_ and non-matching names)
foreach ($acct in (Get-ChildItem -LiteralPath $AccountsRoot -Directory)) {
  if ($acct.Name -eq "_template_") { continue }
  if ($acct.Name -notmatch $AccountNamePattern) { continue }

  Write-Host ("Account: {0}" -f $acct.Name)

  # Realms = directories inside the account EXCEPT SavedVariables
  foreach ($realm in (Get-ChildItem -LiteralPath $acct.FullName -Directory | Where-Object { $_.Name -ne "SavedVariables" })) {
    Write-Host ("  Realm: {0}" -f $realm.Name)

    # Characters = every directory under the realm
    foreach ($char in (Get-ChildItem -LiteralPath $realm.FullName -Directory -Force)) {
      $charName = $char.Name
      $charPath = $char.FullName

      # Safety: never nuke the template directory if someone created such a name
      if ([IO.Path]::GetFullPath($charPath) -eq [IO.Path]::GetFullPath($TemplateDir)) {
        Write-Warning "  SKIP (character path equals template): $charPath"
        continue
      }

      Write-Host ("    Character: {0}  -> linking to template" -f $charName)

      # Delete character folder (or wrong link), then create junction to template
      Remove-Any $charPath
      New-Junction -linkPath $charPath -targetPath $TemplateDir

      $report.Add(("{0}\{1}\{2} -> {3}" -f $acct.Name, $realm.Name, $charName, $TemplateDir))
    } # end foreach char
  } # end foreach realm
} # end foreach account

# Report
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$reportPath = Join-Path $AccountsRoot ("_link_report_" + $stamp + ".txt")
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host ("Done. Characters now link to: {0}" -f $TemplateDir) -ForegroundColor Green
Write-Host ("Report saved to: {0}" -f $reportPath)
