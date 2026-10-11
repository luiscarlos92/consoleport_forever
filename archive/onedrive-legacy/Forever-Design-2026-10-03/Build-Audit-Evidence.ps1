param([switch]$Verify)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskAudit = Join-Path $PSScriptRoot 'controller-audit'
$taskMaster = Join-Path $taskRoot 'ConsolePort-Forever-Phased-Plan-2026-10-03.md'
$taskSource = Join-Path $taskRoot 'Forever-Investigation-2026-10-03/source/wow-ui-source'
if ($Verify) {
    $taskManifest = Get-Content (Join-Path $taskAudit 'evidence-manifest.json') -Raw | ConvertFrom-Json
    $taskPreserve = Get-Content (Join-Path $PSScriptRoot 'preservation-before.json') -Raw | ConvertFrom-Json
    $taskChanged = @(@($taskPreserve.addonFiles) + @($taskPreserve.baselineConfigs) | Where-Object {
        -not (Test-Path -LiteralPath $_.path) -or (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256
    })
    $taskEvidenceChanged = @($taskManifest.files | Where-Object {
        (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256
    })
    $taskOld = [IO.File]::ReadAllText((Join-Path $taskAudit 'master-before-audit.txt'))
    $taskNew = [IO.File]::ReadAllText($taskMaster)
    $taskMarker = '## Historical source records — complete consolidated text'
    $taskHistorySame = $taskOld.Substring($taskOld.IndexOf($taskMarker)) -ceq $taskNew.Substring($taskNew.IndexOf($taskMarker))
    $taskUndefined = @([regex]::Matches($taskNew, '\]\[((?:A|D|F)-[^\]]+)\]') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique | Where-Object {
        $taskNew -notmatch ('(?m)^\[' + [regex]::Escape($_) + '\]: ')
    })
    $taskResult = [ordered]@{
        verifiedAtUTC = (Get-Date).ToUniversalTime().ToString('o')
        preservedAddonFiles = $taskPreserve.addonFiles.Count
        preservedBaselineFiles = $taskPreserve.baselineConfigs.Count
        changedLivePaths = @($taskChanged | ForEach-Object { $_.path })
        evidenceFilesVerified = $taskManifest.files.Count
        changedEvidencePaths = @($taskEvidenceChanged | ForEach-Object { $_.path })
        historicalAppendixUnchanged = $taskHistorySame
        undefinedReferences = $taskUndefined
        sourceWorkingTreeStatus = @(git -C $taskSource status --short)
        runtimeTestsPerformed = $false
    }
    $taskResult | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $taskAudit 'verification.json') -Encoding utf8
    $taskResult | ConvertTo-Json -Depth 5
    if ($taskChanged.Count -or $taskEvidenceChanged.Count -or -not $taskHistorySame -or $taskUndefined.Count -or $taskResult.sourceWorkingTreeStatus.Count) { throw 'Audit preservation verification failed.' }
    return
}
New-Item -ItemType Directory -Path $taskAudit -Force | Out-Null
$taskBefore = Join-Path $taskAudit 'master-before-audit.txt'
if (Test-Path -LiteralPath $taskBefore) { throw 'Audit baseline already exists; do not replace it.' }
Copy-Item -LiteralPath $taskMaster -Destination $taskBefore
$taskHead = Invoke-RestMethod -Uri 'https://api.github.com/repos/Gethe/wow-ui-source/branches/forever'
$taskCommit = (git -C $taskSource rev-parse HEAD).Trim()
$taskFiles = @(
 'Blizzard_GamepadSharedUtility/FrameControlsManager.lua',
 'Blizzard_StaticPopup/StaticPopupGamepad.lua',
 'Blizzard_GamepadSharedUtility/Tab/TabIndicators.lua',
 'Blizzard_GamepadSmartNavigation/SmartNavigation.lua',
 'Blizzard_GamepadSharedUtility/PromptedBindings/PromptedBindingFooter.lua',
 'Blizzard_GamepadSharedUtility/InputBindingStack/InputBindingManager.lua',
 'Blizzard_GamepadSharedUtility/InputHandlers/InputButtonUtility.lua',
 'Blizzard_GamepadActionBars/FlyoutRadial.lua',
 'Blizzard_GamepadActionBars/ClassActionFlyout.lua',
 'Blizzard_GamepadActionBars/MainActionBarFrame.lua',
 'Blizzard_GamepadActionBars/Camelot/PetActionFlyoutButton.lua',
 'Blizzard_GamepadActionBars/Camelot/PetActionFlyout.lua',
 'Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua',
 'Blizzard_UIPanels_Game/Blizzard_UIPanels_Game.toc',
 'Blizzard_FrameXML/Mainline/StackSplitFrame.lua',
 'Blizzard_WorldMap/Blizzard_WorldMap.lua',
 'Blizzard_WorldMap/Camelot/Blizzard_WorldMap.lua',
 'Blizzard_Gamepad/UI/CinematicMovie.lua',
 'Blizzard_Gamepad/UI/HUDMode/GamepadHudMode.lua',
 'Blizzard_SharedXML/InputUtil.lua',
 'Blizzard_APIDocumentationGenerated/GamePadDocumentation.lua'
) | ForEach-Object {
    $taskRel = 'Interface/AddOns/' + $_
    $taskPath = Join-Path $taskSource $taskRel
    [ordered]@{path=$taskPath; sha256=(Get-FileHash -LiteralPath $taskPath -Algorithm SHA256).Hash; sourceUrl="https://github.com/Gethe/wow-ui-source/blob/$taskCommit/$taskRel"}
}
$taskAdditional = @(
 'ConsolePort/Controller/Radial.lua',
 'ConsolePort_Keyboard/Database.lua',
 'ConsolePort_Keyboard/View/Keyboard.lua',
 'ConsolePort_Keyboard/Core/Observer.lua'
)
foreach ($taskRel in $taskAdditional) {
    $taskLive = Join-Path $taskRoot ('_retail_/Interface/AddOns/' + $taskRel)
    $taskCopy = Join-Path $taskAudit ('installed-source/' + $taskRel)
    New-Item -ItemType Directory -Path (Split-Path $taskCopy -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $taskLive -Destination $taskCopy
    $taskFiles += [ordered]@{path=$taskCopy; sourcePath=$taskLive; sha256=(Get-FileHash -LiteralPath $taskCopy -Algorithm SHA256).Hash}
}
$taskManifest = [ordered]@{
 capturedAtUTC=(Get-Date).ToUniversalTime().ToString('o')
 scope='Controller play in Retail; local versus streaming excluded by user clarification'
 sourceCommit=$taskCommit
 publishedForeverHead=$taskHead.commit.sha
 publishedForeverVersion=$taskHead.commit.commit.message
 publishedHeadMatchesSnapshot=($taskCommit -eq $taskHead.commit.sha)
 installedRetailBuild='12.1.0.69933 (installation .build.info); active client not queried'
 installedConsolePortVersion='3.2.6 (installed TOC); enabled runtime modules not queried'
 files=$taskFiles
 runtimeTestsPerformed=$false
}
$taskManifest | ConvertTo-Json -Depth 7 | Set-Content (Join-Path $taskAudit 'evidence-manifest.json') -Encoding utf8
[pscustomobject]@{sourceCommit=$taskCommit; publishedHeadMatchesSnapshot=$taskManifest.publishedHeadMatchesSnapshot; evidenceFiles=$taskFiles.Count; masterBackup=$taskBefore} | ConvertTo-Json
