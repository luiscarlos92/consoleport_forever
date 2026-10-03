$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & python -m unittest discover -s tests -p 'test_*.py'
    if ($LASTEXITCODE -ne 0) { throw 'Tool guard tests failed' }
    & node tools/test-all.cjs
    if ($LASTEXITCODE -ne 0) { throw 'Test runner failed' }
} finally { Pop-Location }
