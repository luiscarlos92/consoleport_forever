$ErrorActionPreference = 'Stop'
$researchRoot = $PSScriptRoot
$sourceRoot = Join-Path $researchRoot 'source\wow-ui-source'
$commit = (git -C $sourceRoot rev-parse HEAD).Trim()
$version = (git -C $sourceRoot log -1 --format='%cI %s').Trim()
$sourceFiles = Get-ChildItem -LiteralPath (Join-Path $sourceRoot 'Interface\AddOns') -Recurse -File | Where-Object { $_.Extension -in '.lua', '.xml', '.toc' }
$inventory = foreach ($sourceFile in $sourceFiles) {
    $relativePath = $sourceFile.FullName.Substring($sourceRoot.Length + 1).Replace('\', '/')
    $entryMatches = @(Select-String -LiteralPath $sourceFile.FullName -Pattern 'GamepadSharedUtility.Create.*PromptedBinding|RegisterGamepadSetup|function .*SetupGamepad|function .*SetUpGamepad|function .*InitializeGamepad')
    if ($relativePath -match '/Blizzard_Gamepad' -or $entryMatches.Count) {
        [ordered]@{
            path = $relativePath
            sha256 = (Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash
            sourceUrl = "https://github.com/Gethe/wow-ui-source/blob/$commit/$relativePath"
            entryPoints = @($entryMatches | ForEach-Object { [ordered]@{ line = $_.LineNumber; text = $_.Line.Trim() } })
        }
    }
}
$settingsPath = Join-Path $sourceRoot 'Interface\AddOns\Blizzard_SettingsDefinitions_Shared\Gamepad.lua'
$settingsText = Get-Content -LiteralPath $settingsPath -Raw
$settingNames = @([regex]::Matches($settingsText, '"((?:[Gg]ame[Pp]ad)[A-Za-z0-9]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
$baselinePaths = @(
    'C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Config.wtf',
    'C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\_template_\bindings-cache.wtf',
    'C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\_template_\SavedVariables\ConsolePort_Bar.lua'
) + @(Get-ChildItem -LiteralPath 'C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\ConsolePort_Forever' -Recurse -File | ForEach-Object { $_.FullName })
$baseline = @($baselinePaths | ForEach-Object {
    [ordered]@{ path = $_; sha256 = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash }
})
$masterPath = Join-Path (Split-Path $researchRoot -Parent) 'ConsolePort-Forever-Phased-Plan-2026-10-03.md'
$masterText = Get-Content -LiteralPath $masterPath -Raw
$referenceFiles = @([regex]::Matches($masterText, '(?m)^\[F-[^\]]+\]: (https://github.com/Gethe/wow-ui-source/blob/[^/]+/(.+))$') | ForEach-Object {
    $referencePath = $_.Groups[2].Value.Trim()
    [ordered]@{
        path = $referencePath
        sha256 = (Get-FileHash -LiteralPath (Join-Path $sourceRoot $referencePath) -Algorithm SHA256).Hash
        sourceUrl = $_.Groups[1].Value.Trim()
    }
})
$evidence = [ordered]@{
    investigationDate = '2026-10-03'
    evidenceType = 'Static source inspection and saved disk configuration; no client runtime tests'
    repository = 'https://github.com/Gethe/wow-ui-source'
    branch = 'forever'
    commit = $commit
    commitVersion = $version
    sourceWorkingTreeStatus = @(git -C $sourceRoot status --short)
    files = @($inventory)
    reportReferenceFiles = $referenceFiles
    settingsNames = $settingNames
    baselineReadOnlyFiles = $baseline
}
$evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $researchRoot 'evidence-manifest.json') -Encoding utf8
Write-Output "Source build: $version"
Write-Output "Pinned commit: $commit"
Write-Output "Indexed source files: $($inventory.Count)"
Write-Output "Gamepad settings/CVar names in settings definition: $($settingNames.Count)"
Write-Output "Read-only baseline hashes: $($baseline.Count)"
