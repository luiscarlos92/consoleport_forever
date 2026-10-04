[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RetailRoot,
    [Parameter(Mandatory)][string]$Backup,
    [string]$Python = 'python',
    [switch]$Simulation,
    [switch]$UserInstall,
    [switch]$Execute,
    [switch]$RecoverInterrupted,
    [switch]$RestoreConfiguration,
    [switch]$AcceptCurrentConfigurationLoss
)
$ErrorActionPreference = 'Stop'
$cpfOperation = if ($RecoverInterrupted) { 'recover' } else { 'restore' }
$cpfArguments = @((Join-Path $PSScriptRoot 'install_pack.py'), $cpfOperation, '--retail-root', $RetailRoot, '--backup', $Backup)
if ($Simulation) { $cpfArguments += '--simulation' }
if ($UserInstall) { $cpfArguments += '--user-install' }
if ($Execute) { $cpfArguments += '--execute' }
if ($RestoreConfiguration) { $cpfArguments += '--restore-config' }
if ($AcceptCurrentConfigurationLoss) { $cpfArguments += '--accept-current-config-loss' }
& $Python @cpfArguments
if ($LASTEXITCODE -ne 0) { throw 'Pack restore/preview refused or failed; all backups are retained.' }
