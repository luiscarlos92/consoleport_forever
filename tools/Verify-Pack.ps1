[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Pack,
    [Parameter(Mandatory)][string]$ExpectedSHA256,
    [string]$Python = 'python',
    [switch]$RequireComplete
)
$ErrorActionPreference = 'Stop'
$cpfArguments = @((Join-Path $PSScriptRoot 'verify_pack.py'), '--pack', $Pack, '--sha256', $ExpectedSHA256)
if ($RequireComplete) { $cpfArguments += '--require-complete' }
& $Python @cpfArguments
if ($LASTEXITCODE -ne 0) { throw 'Pack verification failed.' }
