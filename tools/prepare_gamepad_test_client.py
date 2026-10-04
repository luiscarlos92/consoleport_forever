import hashlib,io,json,sys,tarfile,urllib.request
from pathlib import Path,PurePosixPath
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from repository_paths import ROOT,output
base=output(ROOT/'scratch/controller-emulation')
base.mkdir(exist_ok=True)
with urllib.request.urlopen('https://pypi.org/pypi/vgamepad/0.1.0/json',timeout=30) as response:
    metadata=json.load(response)
package=next(file for file in metadata['urls'] if file['packagetype']=='sdist')
with urllib.request.urlopen(package['url'],timeout=30) as response:
    data=response.read()
digest=hashlib.sha256(data).hexdigest()
assert digest==package['digests']['sha256']
output(base/package['filename']).write_bytes(data)
files=[]
with tarfile.open(fileobj=io.BytesIO(data),mode='r:gz') as archive:
    for member in archive.getmembers():
        relative=PurePosixPath(member.name)
        assert '..' not in relative.parts and not relative.is_absolute()
        if not member.isfile() or len(relative.parts)<3 or relative.parts[1]!='vgamepad':
            continue
        # Import only the client package; never run setup.py or a driver installer.
        if relative.suffix.lower() not in ('.py','.dll'):
            continue
        target=output(base/'client'/Path(*relative.parts[1:]))
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(archive.extractfile(member).read())
        files.append(str(target.relative_to(base)))
provenance={'package':'vgamepad','version':'0.1.0','url':package['url'],'sha256':digest,'driverInstalled':False,'setupExecuted':False,'files':files}
output(base/'provenance.json').write_text(json.dumps(provenance,indent=2),encoding='utf-8')
print(json.dumps(provenance,indent=2))
