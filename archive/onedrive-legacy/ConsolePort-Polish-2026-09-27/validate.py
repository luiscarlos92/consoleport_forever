from pathlib import Path
import subprocess, sys, json, hashlib
from datetime import datetime, timezone
work=Path(__file__).resolve().parent
root=Path(r'C:\Program Files (x86)\World of Warcraft\_retail_')
target=root if '--live' in sys.argv else work/'staged'
subprocess.run([sys.executable,str(work/'extract-lab.py')],check=True)
logs=[]
for command,expected in [
    (['node',str(work/'verify-data.js'),str(target)],1),
    (['node',str(work/'tools/node_modules/fengari-node-cli/src/lua-cli.js'),str(work/'harness.lua'),target.as_posix()+'/'],4),
]:
    result=subprocess.run(command,cwd=work.parent,capture_output=True,text=True,encoding='utf8')
    print(result.stdout,end='');print(result.stderr,end='',file=sys.stderr)
    assert result.returncode==0 and not result.stderr.strip(), 'Validation failed'
    assert sum(line.startswith('PASS:') for line in result.stdout.splitlines())==expected,'Incomplete harness (Fengari can exit zero on a Lua error)'
    logs.append(result.stdout)
manifest=json.loads((work/'manifest.json').read_text(encoding='utf8'))
hashes={rel:hashlib.sha256((target/rel).read_bytes()).hexdigest() for rel in manifest['originals']}
stamp=datetime.now(timezone.utc).isoformat()
name='live' if target==root else 'staged'
(work/'evidence'/f'validation-{name}.txt').write_text(stamp+'\n'+''.join(logs),encoding='utf8')
(work/'evidence'/f'validated-{name}-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf8')
print('PASS: complete validation recorded with hashes for '+name+' files.')
