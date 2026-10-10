"""Explicit, pinned Blizzard-authored source import for contract audits."""
import base64
import json
from pathlib import Path
import subprocess
from repository_paths import ROOT, output, sha

REV='09b9db7948abc9b9648dedaab51eb0cf3ee67b31'
FILES=[
    'Blizzard_ChatFrameBase/Mainline/SlashCommandsOverrides.lua',
    'Blizzard_PingUI/Bindings.xml',
    'Blizzard_PingUI/Blizzard_PingManager.lua',
    'Blizzard_PingUI/Blizzard_PingUI.lua',
    'Blizzard_PingUI/Blizzard_PingUtil.lua',
    'Blizzard_APIDocumentationGenerated/PingManagerDocumentation.lua',
    'Blizzard_APIDocumentationGenerated/PingManagerSecureDocumentation.lua',
    'Blizzard_UIPanels_Game/Shared/VehicleSeatIndicator.lua',
    'Blizzard_UIPanels_Game/Shared/VehicleSeatIndicator.xml',
    'Blizzard_Collections/Blizzard_Collections_Mainline.toc',
    'Blizzard_Transmog/Blizzard_Transmog.toc',
    'Blizzard_APIDocumentationGenerated/AddOnsDocumentation.lua',
    'Blizzard_APIDocumentationGenerated/EditModeManagerDocumentation.lua',
    'Blizzard_APIDocumentationGenerated/KeyBindingsDocumentation.lua',
    'Blizzard_APIDocumentationGenerated/EventUtilsDocumentation.lua',
    'Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua',
    'Blizzard_RestrictedAddOnEnvironment/RestrictedExecution.lua',
    'Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua',
    'Blizzard_FrameXML/SecureTemplates.lua',
    'Blizzard_ActionBarController/ActionBarController.lua',
    'Blizzard_ActionBar/Shared/StanceBar.lua',
    'Blizzard_ActionBar/Shared/PetActionBar.lua',
    'Blizzard_StaticPopup/StaticPopup.lua',
    'Blizzard_StaticPopup/SharedTemplates.lua',
    'Blizzard_StaticPopup_Game/GameDialog.lua',
    'Blizzard_StaticPopup_Game/GameDialog.xml',
    'Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua',
    'Blizzard_FrameXML/Mainline/StackSplitFrame.lua',
    'Blizzard_FrameXML/Mainline/StackSplitFrame.xml',
    'Blizzard_FrameXML/Shared/CinematicFrame.lua',
    'Blizzard_FrameXML/MovieFrame.lua',
    'Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua',
    'Blizzard_APIDocumentationGenerated/PetInfoDocumentation.lua',
    'Blizzard_APIDocumentationGenerated/SpellDocumentation.lua',
    'Blizzard_SharedXML/Shared/TabSystem/TabSystemOwner.lua',
    'Blizzard_SharedXML/Shared/TabSystem/TabSystemTemplates.lua',
    'Blizzard_UIPanelTemplates/Shared/UIPanelTemplatesShared.lua',
    'Blizzard_SharedXML/Shared/Scroll/ScrollController.lua',
    'Blizzard_MapCanvas/MapCanvas_ScrollContainerMixin.lua',
    'Blizzard_WorldMap/Blizzard_WorldMap.lua',
    'Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua',
    'Blizzard_UIPanels_Game/Mainline/MerchantFrame.lua',
    'Blizzard_UIPanels_Game/Mainline/MerchantFrame.xml',
    'Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua',
    'Blizzard_SharedMapDataProviders/WaypointLocationDataProvider.lua',
    'Blizzard_APIDocumentationGenerated/MapDocumentation.lua',
    'Blizzard_MapCanvasSecureUtil/Blizzard_MapCanvasSecureUtil.lua',
    'Blizzard_MapCanvas/Blizzard_MapCanvas.lua',
    'Blizzard_WorldMap/QuestLogOwnerMixin.lua',
    'Blizzard_UIPanels_Game/Mainline/QuestMapFrame.lua',
    'Blizzard_FrameXML/Shared/CinematicFrame.xml',
    'Blizzard_FrameXML/MovieFrame.xml',
    'Blizzard_FrameXML/Mainline/CinematicFrameButton.xml',
    'Blizzard_EditMode/Shared/EditModeSystemTemplates.lua',
    'Blizzard_EditMode/Shared/EditModeSystemTemplates.xml',
    'Blizzard_EditMode/Shared/EditModeManager.lua',
    'Blizzard_UnitFrame/Shared/PartyFrame.xml',
    'Blizzard_UnitFrame/Shared/CompactPartyFrame.lua',
    'Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameContainer.xml',
    'Blizzard_ActionBar/Shared/MultiActionBars.lua',
    'Blizzard_ActionBar/Shared/MultiActionBars.xml',
    'Blizzard_ActionBar/Shared/ActionBar.lua',
    'Blizzard_ActionBar/Shared/ExtraActionBar.lua',
    'Blizzard_ActionBar/Shared/ExtraActionBar.xml',
]

if __name__=='__main__':
    records=[]
    manifest=ROOT/'evidence/native/manifest.json'
    retained={r['path']:r for r in json.loads(manifest.read_text(encoding='utf-8'))} if manifest.exists() else {}
    for name in FILES:
        prior=retained.get(name)
        if prior and prior.get('commit')==REV and prior.get('sha256') and (ROOT/'evidence/native'/name).exists():
            if sha(ROOT/'evidence/native'/name)!=prior['sha256']:
                raise ValueError('Retained pinned native source drift: '+name)
            records.append(prior)
            continue
        endpoint='repos/Gethe/wow-ui-source/contents/Interface/AddOns/'+name+'?ref='+REV
        try:
            result=json.loads(subprocess.check_output(['gh','api',endpoint],stderr=subprocess.PIPE,timeout=40))
            target=output(ROOT/'evidence/native'/name)
            target.parent.mkdir(parents=True,exist_ok=True)
            target.write_bytes(base64.b64decode(result['content']))
            records.append({'path':name,'commit':REV,'gitBlob':result['sha'],'sha256':sha(target),'url':result['html_url']})
        except Exception as error:
            records.append({'path':name,'commit':REV,'error':str(error)})
    output(ROOT/'evidence/native/manifest.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
    print(json.dumps(records,indent=2))
