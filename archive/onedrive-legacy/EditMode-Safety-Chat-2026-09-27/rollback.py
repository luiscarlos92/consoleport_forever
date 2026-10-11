from pathlib import Path
import hashlib
import os
import shutil
import subprocess

WORK = Path(__file__).resolve().parent
ROOT = Path(r"C:\Program Files (x86)\World of Warcraft\_retail_")
FILES = {
    Path("Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua"): (
        "71c36ab2293a350098ee2396d5259efbf5dd3f74596aac05814601f399abf21c",
        "d84b21c490e0c9013379aadbcB6f8e00d3816292b4cd81d88321c7be281d5838".lower(),
    ),
    Path("WTF/Account/_template_/chat-cache.txt"): (
        "41ed0fb1bca0d8f19e8f0f1b2b961e6abb3c601532f286532c23a9260d841810",
        "37dec9d5c90400e3ebf9746f32019ac39c3bb0c200c7dd1e6421c54883b3495e",
    ),
    Path("WTF/Account/119624169#1/edit-mode-cache-account.txt"): (
        "17eae01a2a169138f9e9abb36a4bd11fbd0cbaf73de3f4b19989094271f39554",
        "6ec4b884f95771e1030012b0c4b4fca41348942307b90b71ee42207c73d52f39",
    ),
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


command = "@(Get-Process -Name Wow,WowT,WowClassic,WowClassicT,WorldOfWarcraft -ErrorAction SilentlyContinue).Count"
result = subprocess.run(
    ["powershell", "-NoProfile", "-Command", command],
    capture_output=True, text=True, check=True,
)
assert int(result.stdout.strip() or "0") == 0, "WoW is running; close it normally before rollback."

for relative, (current_hash, backup_hash) in FILES.items():
    live = ROOT / relative
    backup = WORK / "before" / relative
    assert digest(live) == current_hash, f"Refusing to overwrite changed file: {relative}"
    assert digest(backup) == backup_hash, f"Backup hash mismatch: {relative}"

for relative in FILES:
    live = ROOT / relative
    backup = WORK / "before" / relative
    temporary = live.with_suffix(live.suffix + ".codex-rollback")
    shutil.copy2(backup, temporary)
    os.replace(temporary, live)

print("Restored the pre-fix helper and chat/Edit Mode caches.")
