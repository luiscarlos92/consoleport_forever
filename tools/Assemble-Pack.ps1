[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Recipe,
    [Parameter(Mandatory)][string]$ExpectedSHA256,
    [Parameter(Mandatory)][string]$Output,
    [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
& $Python (Join-Path $PSScriptRoot 'assemble_pack.py') --recipe $Recipe --sha256 $ExpectedSHA256 --output $Output
if ($LASTEXITCODE -ne 0) { throw 'Official-source assembly failed; no game files were changed.' }
