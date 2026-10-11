from pathlib import Path
import subprocess, sys, json
from datetime import datetime, timezone
from prepare import WORK, ROOT, digest
target=ROOT if '--live' in sys.argv else WORK/'staged'
source=(ROOT/'Interface/AddOns/ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua').read_text(encoding='utf8')
start=source.index('function Update(self)');end=source.index('function Generic:UpdateLocal()',start)
(WORK/'evidence/lab-update.lua').write_text(source[start:end],encoding='utf8')
logs=[]
for command,expected in [
    (['node',str(WORK/'verify-data.js'),str(target)],1),
    (['node',str(WORK.parent/'ConsolePort-Polish-2026-09-27/tools/node_modules/fengari-node-cli/src/lua-cli.js'),str(WORK/'harness.lua'),target.as_posix()+'/'],4),
]:
    r=subprocess.run(command,cwd=WORK.parent,capture_output=True,text=True,encoding='utf8')
    print(r.stdout,end='');print(r.stderr,end='',file=sys.stderr)
    assert r.returncode==0 and not r.stderr.strip(), 'Validation failed'
    assert sum(l.startswith('PASS:') for l in r.stdout.splitlines())==expected,'Incomplete harness'
    logs.append(r.stdout)
m=json.loads((WORK/'manifest.json').read_text())
hashes={rel:digest(target/rel) for rel in list(m['originals'])+m['new']}
name='live' if target==ROOT else 'staged'
(WORK/'evidence'/f'validation-{name}.txt').write_text(datetime.now(timezone.utc).isoformat()+'\n'+''.join(logs))
(WORK/'evidence'/f'validated-{name}-hashes.json').write_text(json.dumps(hashes,indent=2))
print('PASS: validation completed and file hashes recorded for '+name)
