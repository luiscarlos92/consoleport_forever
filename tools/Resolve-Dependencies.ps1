param([switch]$Refresh)
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    if ($Refresh) { & python tools/resolve_dependencies.py --refresh }
    else { & python tools/resolve_dependencies.py }
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution/verification failed' }
} finally { Pop-Location }
