[CmdletBinding()]
param([switch]$RecipeOnly, [string]$Python = 'python')
$ErrorActionPreference = 'Stop'
$cpfArguments = @((Join-Path $PSScriptRoot 'build_pack.py'))
if ($RecipeOnly) { $cpfArguments += '--recipe-only' }
& $Python @cpfArguments
if ($LASTEXITCODE -ne 0) { throw 'Pack build refused or failed; source/evidence must be current, tested, clean and pushed.' }
