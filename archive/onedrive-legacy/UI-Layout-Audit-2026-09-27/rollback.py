from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess

WORK = Path(__file__).resolve().parent
ROOT = Path(r"C:\Program Files (x86)\World of Warcraft\_retail_")
REL = Path("Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua")
LIVE = ROOT / REL
BEFORE = WORK / "before" / REL
BEFORE_HASH = "B77AD851A602CF1230A96724B043D1127B322F72A938EBB9F3AA90E356D1F6CB".lower()
DEPLOYED_HASH = "6B2B3FE9E60F6677F4D74F6FD83A696DECD4C2C9498FCBAB93C6036E4FDC0267".lower()

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def wow_process_count() -> int:
    command = "@(Get-Process -Name Wow,WowT,WowClassic,WowClassicT,WorldOfWarcraft -ErrorAction SilentlyContinue).Count"
    result = subprocess.run(["powershell", "-NoProfile", "-Command", command],
                            capture_output=True, text=True, check=True)
    return int(result.stdout.strip() or "0")

assert wow_process_count() == 0, "WoW is running. Close it normally; rollback made no changes."
assert sha(BEFORE) == BEFORE_HASH, "Backup does not match the pre-task manifest."

current = sha(LIVE)
if current == BEFORE_HASH:
    print("Already rolled back to the pre-task hash.")
else:
    assert current == DEPLOYED_HASH, "Live helper changed after deployment; rollback refused."
    temporary = LIVE.with_suffix(LIVE.suffix + ".codex-rollback")
    shutil.copy2(BEFORE, temporary)
    assert sha(temporary) == BEFORE_HASH
    os.replace(temporary, LIVE)
    assert sha(LIVE) == BEFORE_HASH
    print("Restored the pre-task ConsolePort_Forever helper.")

receipt = {
    "timestampUtc": datetime.now(timezone.utc).isoformat(),
    "operation": "rollback",
    "wowProcessCount": 0,
    "relativePath": REL.as_posix(),
    "replacedSha256": DEPLOYED_HASH,
    "installedSha256": sha(LIVE),
}
(WORK / "evidence/rollback-receipt.json").write_text(json.dumps(receipt, indent=2), encoding="utf-8")
