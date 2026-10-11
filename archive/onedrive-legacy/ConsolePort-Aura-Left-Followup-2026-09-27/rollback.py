from pathlib import Path
import hashlib, shutil, subprocess
root=Path(r"C:\Program Files (x86)\World of Warcraft\_retail_")
work=Path(r"C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\ConsolePort-Aura-Left-Followup-2026-09-27")
target=root/r"Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua"
before=work/'before/ConsolePort_Forever.lua'
expected="b77ad851a602cf1230a96724b043d1127b322f72a938ebb9f3aa90e356d1f6cb"
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
processes=subprocess.run(['powershell','-NoProfile','-Command',"@(Get-Process -Name Wow,WowClassic,WowClassicT -ErrorAction SilentlyContinue).Count"],capture_output=True,text=True,check=True).stdout.strip()
assert processes=='0', 'WoW is running; close it normally before rollback.'
assert sha(target)==expected, 'Live helper changed after this correction; compare before restoring.'
shutil.copy2(before,target)
print('Restored the prior health-container-left aura anchor.')
