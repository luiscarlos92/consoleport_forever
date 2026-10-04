[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RetailRoot,
    [Parameter(Mandatory)][string]$Pack,
    [Parameter(Mandatory)][string]$ExpectedSHA256,
    [string]$BackupRoot,
    [string]$Python = 'python',
    [switch]$Simulation,
    [switch]$UserInstall,
    [switch]$Execute
)
$ErrorActionPreference = 'Stop'
$cpfArguments = @((Join-Path $PSScriptRoot 'install_pack.py'), 'install', '--retail-root', $RetailRoot, '--pack', $Pack, '--sha256', $ExpectedSHA256)
if ($BackupRoot) { $cpfArguments += @('--backup-root', $BackupRoot) }
if ($Simulation) { $cpfArguments += '--simulation' }
if ($UserInstall) { $cpfArguments += '--user-install' }
if ($Execute) { $cpfArguments += '--execute' }
& $Python @cpfArguments
if ($LASTEXITCODE -ne 0) { throw 'Pack installation/preview refused or failed; retained receipts identify recovery state.' }
