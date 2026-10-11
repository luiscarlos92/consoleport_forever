param([switch]$Verify)
$ErrorActionPreference = 'Stop'
$taskEvidenceRoot = $PSScriptRoot
$taskAddons = 'C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns'
$taskMaster = Join-Path (Split-Path $taskEvidenceRoot -Parent) 'ConsolePort-Forever-Phased-Plan-2026-10-03.md'
if ($Verify) {
    $taskBefore = Get-Content (Join-Path $taskEvidenceRoot 'preservation-before.json') -Raw | ConvertFrom-Json
    $taskChanged = @(@($taskBefore.addonFiles) + @($taskBefore.baselineConfigs) | Where-Object {
        -not (Test-Path -LiteralPath $_.path) -or (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256
    })
    $taskAdded = @(Get-ChildItem -LiteralPath $taskAddons -Recurse -File | Where-Object { $_.FullName -notin $taskBefore.addonFiles.path })
    $taskOld = [IO.File]::ReadAllText((Join-Path $taskEvidenceRoot 'master-before-phase2.txt'))
    $taskNew = [IO.File]::ReadAllText($taskMaster)
    $taskMarker = '## Historical source records — complete consolidated text'
    $taskHistorySame = $taskOld.Substring($taskOld.IndexOf($taskMarker)) -ceq $taskNew.Substring($taskNew.IndexOf($taskMarker))
    $taskUndefined = @([regex]::Matches($taskNew, '\]\[(D-[^\]]+)\]') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique | Where-Object {
        $taskNew -notmatch ('(?m)^\[' + [regex]::Escape($_) + '\]: ')
    })
    $taskResult = [ordered]@{
        verifiedAtUTC = (Get-Date).ToUniversalTime().ToString('o')
        preservedAddonFiles = $taskBefore.addonFiles.Count
        preservedBaselineFiles = $taskBefore.baselineConfigs.Count
        changedLivePaths = @($taskChanged | ForEach-Object { $_.path })
        addedAddonPaths = @($taskAdded | ForEach-Object { $_.FullName })
        historicalAppendixUnchanged = $taskHistorySame
        undefinedDesignReferences = $taskUndefined
        runtimeTestsPerformed = $false
    }
    $taskResult | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $taskEvidenceRoot 'verification.json') -Encoding utf8
    $taskResult | ConvertTo-Json -Depth 4
    if ($taskChanged.Count -or $taskAdded.Count -or -not $taskHistorySame -or $taskUndefined.Count) { throw 'Preservation or reference verification failed.' }
    return
}
$taskPaths = @(
    'ConsolePort/ConsolePort.toc', 'ConsolePort/Controller/Pager.lua', 'ConsolePort/Controller/Bindings.lua',
    'ConsolePort/Controller/Mouse.lua', 'ConsolePort/Controller/Interact.lua', 'ConsolePort/Model/Data/Variables.lua',
    'ConsolePort/Model/Game/Bindings.lua', 'ConsolePort/Model/Gamepad/PlayStation/PlayStation5.lua', 'ConsolePort/Utils/Utils.lua',
    'ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua',
    'ConsolePort_Bar/ConsolePort_Bar.toc', 'ConsolePort_Bar/Model/Utils.lua', 'ConsolePort_Bar/Widget/Group/Group.lua',
    'ConsolePort_Bar/Widget/Bar/Bar.lua', 'ConsolePort_Bar/Widget/Page/Page.lua', 'ConsolePort_Bar/Widget/Button/Button.lua',
    'ConsolePort_Bar/Controller/Manager/Manager.lua', 'ConsolePort_Bar/Controller/Blizzard/Mainline.lua',
    'ConsolePort_Bar/View/Toolbar/Toolbar.lua', 'ConsolePort_Bar/View/Pet/Petring.lua',
    'ConsolePort_Rings/ConsolePort_Rings.toc', 'ConsolePort_Rings/Model/Container.lua', 'ConsolePort_Rings/Model/Map.lua',
    'ConsolePort_Rings/Model/Collection.lua', 'ConsolePort_Rings/Controller/Secure.lua', 'ConsolePort_Rings/Controller/Events.lua',
    'ConsolePort_Rings/Controller/Auto.lua', 'ConsolePort_Rings/Controller/Context.lua', 'ConsolePort_Rings/Database.lua',
    'ConsolePort_Cursor/Database.lua', 'ConsolePort_Cursor/View/Cursor.lua', 'ConsolePort_Cursor/Controller/Hooks.lua',
    'ConsolePort_Forever/ConsolePort_Forever.toc', 'ConsolePort_Forever/ConsolePort_Forever.lua',
    'ConsolePort_Forever/Bindings.lua', 'ConsolePort_Forever/Layout.lua', 'ConsolePort_Forever/Runtime.lua', 'ConsolePort_Forever/Skin.lua',
    'BetterBags/BetterBags.toc', 'BetterBags/integrations/consoleport.lua', 'BetterBags/integrations/masque.lua', 'BetterBags/frames/item.lua',
    'DynamicCam/DynamicCam.toc', 'DynamicCam/Core.lua', 'DynamicCam/Libs/AceDB-3.0/AceDB-3.0.lua',
    'Immersion/Immersion.toc', 'Immersion/Config.lua', 'Immersion/Settings.lua',
    'Immersion_ExtraFade/Immersion_ExtraFade.toc', 'Immersion_ExtraFade/main.lua', 'Immersion_ExtraFade/options.lua',
    'LiteMount/LiteMount.toc', 'LiteMount/ActionButton.lua'
)
$taskSnapshots = @(foreach ($taskRelative in $taskPaths) {
    $taskSource = Join-Path $taskAddons $taskRelative
    $taskDest = Join-Path (Join-Path $taskEvidenceRoot 'installed-source') $taskRelative
    New-Item -ItemType Directory -Path (Split-Path $taskDest -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $taskSource -Destination $taskDest
    [pscustomobject]@{ relativePath = $taskRelative; sourcePath = $taskSource; snapshotPath = $taskDest; sha256 = (Get-FileHash -LiteralPath $taskSource -Algorithm SHA256).Hash }
})
$taskStockRoot = Join-Path $taskEvidenceRoot 'source/ConsolePort-3.2.6'
$taskRetail = Get-Content (Join-Path $taskEvidenceRoot 'retail-source-version.json') -Raw | ConvertFrom-Json
$taskRetailFiles = @(Get-ChildItem (Join-Path $taskEvidenceRoot 'source/Retail-12.1.0') -Recurse -File | ForEach-Object {
    [pscustomobject]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
})
[ordered]@{ evidenceType='Static source and saved-disk inspection; no runtime validation'; capturedAtUTC=(Get-Date).ToUniversalTime().ToString('o');
    consolePortVersion='3.2.6'; consolePortStockCommit=(git -C $taskStockRoot rev-parse HEAD).Trim(); retailSource=$taskRetail;
    installedSourceSnapshots=$taskSnapshots; retailSourceFiles=$taskRetailFiles
} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $taskEvidenceRoot 'evidence-manifest.json') -Encoding utf8
[pscustomobject]@{installedSourceSnapshots=$taskSnapshots.Count;retailSourceFiles=$taskRetailFiles.Count} | ConvertTo-Json
