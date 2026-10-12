$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & python -B tools/check_documentation.py
    if ($LASTEXITCODE -ne 0) { throw 'Maintained documentation checks failed' }
    & python tools/run_tool_tests.py
    if ($LASTEXITCODE -ne 0) { throw 'Tool guard tests failed' }
    & node tools/test-all.cjs
    if ($LASTEXITCODE -ne 0) { throw 'Test runner failed' }
} finally { Pop-Location }
