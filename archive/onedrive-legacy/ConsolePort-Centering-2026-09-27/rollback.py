from pathlib import Path
import hashlib
import os
import shutil
import subprocess

WORK = Path(__file__).resolve().parent
ROOT = Path(r"C:\Program Files (x86)\World of Warcraft\_retail_")
FILES = {
    Path("Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua"): (
        "d84b21c490e0c9013379aadbcb6f8e00d3816292b4cd81d88321c7be281d5838",
        "6b2b3fe9e60f6677f4d74f6fd83a696decd4c2c9498fcbab93c6036e4fdc0267",
    ),
    Path("WTF/Account/_template_/SavedVariables/ConsolePort_Bar.lua"): (
        "261d556b15a9a0368128a2c9fc08663ad1a54766b75140d046549e4a79904cf1",
        "1a3fbdecaec98fd53ec729694f363b67789b7d994cd619259b74ff8d7ce37279",
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

print("Restored the pre-centering helper and ConsolePort layout.")
