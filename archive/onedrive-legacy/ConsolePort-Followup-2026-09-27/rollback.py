from pathlib import Path
import hashlib, shutil, subprocess
root=Path(r"C:\Program Files (x86)\World of Warcraft\_retail_")
work=Path(r"C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\ConsolePort-Followup-2026-09-27")
target=root/r"Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua"
before=work/'before/ConsolePort_Forever.lua'
expected="37036890e6c7f70f606779e90389d0388457c1f3f4efb74ffea4cb100f1af931"
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
processes=subprocess.run(['powershell','-NoProfile','-Command',"@(Get-Process -Name Wow,WowClassic,WowClassicT -ErrorAction SilentlyContinue).Count"],capture_output=True,text=True,check=True).stdout.strip()
assert processes=='0', 'WoW is running; close it normally before rollback.'
assert sha(target)==expected, 'Live helper changed after this follow-up; compare before restoring.'
shutil.copy2(before,target)
print('Restored the approved pre-follow-up helper (2-pixel cast gap, higher prompts, right-side auras).')
