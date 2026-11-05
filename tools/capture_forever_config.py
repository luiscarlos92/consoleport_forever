"""Reconstruct the pinned native bag-dispatch input in ignored checkout scratch."""
import hashlib
import urllib.request
from repository_paths import ROOT, output

URL = 'https://raw.githubusercontent.com/Gethe/wow-ui-source/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua'
SHA256 = '9af2c76d16ebff607dd8b983722f36f98e819b35bc77395232bb2f960d15e3d3'

def capture():
    target = output(ROOT/'scratch/forever-config-inputs/ContainerFrame.lua')
    request = urllib.request.Request(URL, headers={'User-Agent':'Forever-config-source-qualification'})
    with urllib.request.urlopen(request,timeout=40) as response:
        data = response.read()
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise ValueError('Pinned native bag source drift')
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(data)
    return {'path':str(target),'sha256':SHA256}

if __name__ == '__main__':
    import json
    print(json.dumps(capture()))
