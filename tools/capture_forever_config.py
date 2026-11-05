"""Reconstruct the pinned native bag-dispatch input in ignored checkout scratch."""
import hashlib
import urllib.request
from repository_paths import ROOT, output

URL = 'https://raw.githubusercontent.com/Gethe/wow-ui-source/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua'
SHA256 = '9af2c76d16ebff607dd8b983722f36f98e819b35bc77395232bb2f960d15e3d3'
NAVIGATION = {
    'FrameControlsManager.lua': ('Blizzard_GamepadSharedUtility/FrameControlsManager.lua', 'd1b1f6e21e9f103806c67c6274b4cb2ad947da99ee8315143ea9f37e1d13416f'),
    'SmartNavigation.lua': ('Blizzard_GamepadSmartNavigation/SmartNavigation.lua', '6907e694572194b8bb01aa73f035c75f04c02b33d7c14d0cd6bb98bfd85545d2'),
    'Utility.lua': ('Blizzard_GamepadSmartNavigation/Utility.lua', 'a00c0086b9c24de2770ccfe7de992b991f3c4aab942f32fd9f52471553ef09f8'),
    'PromptedBinding.lua': ('Blizzard_GamepadSharedUtility/PromptedBindings/PromptedBinding.lua', '6966073a5c98149389f793d95e3b9f5e7237153f263b1a2216b652e23782c6f9'),
    'PromptedBindingFooter.lua': ('Blizzard_GamepadSharedUtility/PromptedBindings/PromptedBindingFooter.lua', 'dea94417a2672882d2bfa5e12be23cad8476c731e6e13a357ba779b292c78c1b'),
}


def capture_navigation():
    base = URL.split('Interface/AddOns/')[0] + 'Interface/AddOns/'
    for name, (relative, expected) in NAVIGATION.items():
        request = urllib.request.Request(base+relative, headers={'User-Agent':'Forever-config-source-qualification'})
        with urllib.request.urlopen(request, timeout=40) as response:
            data = response.read()
        if hashlib.sha256(data).hexdigest() != expected:
            raise ValueError('Pinned native navigation drift: '+name)
        target = output(ROOT/'scratch/forever-config-inputs/navigation'/name)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)

def capture():
    target = output(ROOT/'scratch/forever-config-inputs/ContainerFrame.lua')
    request = urllib.request.Request(URL, headers={'User-Agent':'Forever-config-source-qualification'})
    with urllib.request.urlopen(request,timeout=40) as response:
        data = response.read()
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise ValueError('Pinned native bag source drift')
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(data)
    capture_navigation()
    return {'path':str(target),'sha256':SHA256}

if __name__ == '__main__':
    import json
    print(json.dumps(capture()))
