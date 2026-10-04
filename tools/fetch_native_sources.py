"""Explicit, pinned Blizzard-authored source import for contract audits."""
import base64
import json
from pathlib import Path
import subprocess
from repository_paths import ROOT, contained, sha

REV='09b9db7948abc9b9648dedaab51eb0cf3ee67b31'
FILES=[
    'Blizzard_APIDocumentationGenerated/AddOnsDocumentation.lua',
    'Blizzard_APIDocumentationGenerated/EditModeManagerDocumentation.lua',
    'Blizzard_APIDocumentationGenerated/KeyBindingsDocumentation.lua',
    'Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua',
    'Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua',
    'Blizzard_FrameXML/SecureTemplates.lua',
    'Blizzard_ActionBarController/ActionBarController.lua',
    'Blizzard_StaticPopup/StaticPopup.lua',
    'Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua',
    'Blizzard_FrameXML/Mainline/StackSplitFrame.lua',
    'Blizzard_FrameXML/Shared/CinematicFrame.lua',
    'Blizzard_FrameXML/MovieFrame.lua',
    'Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua',
    'Blizzard_APIDocumentationGenerated/PetInfoDocumentation.lua',
    'Blizzard_APIDocumentationGenerated/SpellDocumentation.lua',
]

if __name__=='__main__':
    records=[]
    for name in FILES:
        endpoint='repos/Gethe/wow-ui-source/contents/Interface/AddOns/'+name+'?ref='+REV
        try:
            result=json.loads(subprocess.check_output(['gh','api',endpoint],stderr=subprocess.PIPE,timeout=40))
            target=contained(ROOT/'evidence/native'/name)
            target.parent.mkdir(parents=True,exist_ok=True)
            target.write_bytes(base64.b64decode(result['content']))
            records.append({'path':name,'commit':REV,'gitBlob':result['sha'],'sha256':sha(target),'url':result['html_url']})
        except Exception as error:
            records.append({'path':name,'commit':REV,'error':str(error)})
    (ROOT/'evidence/native/manifest.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
    print(json.dumps(records,indent=2))
