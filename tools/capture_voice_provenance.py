"""Pin the maintainer tree behind the voice pack already in official DBM core."""
import base64
import json
import subprocess
from repository_paths import ROOT, output

REV = '99e0c336444fd7105e1414c46f9d6a4e0cf99bc6'
REPO = 'DeadlyBossMods/DBM-Voicepack-VEM'


if __name__ == '__main__':
    tree = json.loads(subprocess.check_output(['gh','api',f'repos/{REPO}/git/trees/{REV}?recursive=1'],timeout=45))
    if tree['truncated'] or tree['sha'] != REV:
        raise ValueError('Incomplete pinned voice tree')
    toc = json.loads(subprocess.check_output(['gh','api',f'repos/{REPO}/contents/DBM-VPVEM/DBM-VPVEM.toc?ref={REV}'],timeout=45))
    record = {'repo': REPO, 'commit': REV, 'url': f'https://github.com/{REPO}/tree/{REV}',
              'files': {p['path']:p['sha'] for p in tree['tree'] if p['type']=='blob' and p['path'].startswith('DBM-VPVEM/')},
              'sourceTOC': base64.b64decode(toc['content']).decode('utf-8-sig'),
              'qualification': 'Official core package owns this folder; no second voice folder/package is assembled.'}
    target = output(ROOT/'evidence/dependencies/voice-provenance.json')
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(record,indent=2),encoding='utf-8')
    print('Captured pinned voice provenance:',len(record['files']),'files')
