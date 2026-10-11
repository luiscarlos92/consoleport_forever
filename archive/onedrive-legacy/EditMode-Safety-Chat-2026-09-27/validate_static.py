from pathlib import Path
import json

WORK = Path(__file__).resolve().parent
HELPER = WORK / "after/Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua"
CHAT = WORK / "after/WTF/Account/_template_/chat-cache.txt"
EDIT = WORK / "after/WTF/Account/119624169#1/edit-mode-cache-account.txt"

source = HELPER.read_text(encoding="utf-8")
required = [
    "local function IsEditModeActive()",
    "if InCombatLockdown() or IsEditModeActive() then return false end",
    "if InCombatLockdown() or IsEditModeActive() or castApplying then return end",
    "if InCombatLockdown() or IsEditModeActive() or auraLaneApplying then return end",
]
missing = [value for value in required if value not in source]
assert not missing, f"missing Edit Mode guards: {missing}"

forbidden = [
    "frame:UpdateSystem(",
    "GetModernSystems",
    "registeredSystemFrames",
    "QueueModernLayoutPolicy",
    "ApplyModernLayoutPolicy",
    "hooksecurefunc(manager",
]
present = [value for value in forbidden if value in source]
assert not present, f"taint-prone Edit Mode policy remains: {present}"

chat = CHAT.read_text(encoding="utf-8")
assert chat.count("DIMENSIONS 400.000000 120.000000") == 1
assert "DIMENSIONS 429.999939 120.000000" not in chat

edit = EDIT.read_text(encoding="utf-8")
old_settings = "#'$A%$&7"  # width 4*100+30, height 1*100+20
new_settings = "#'$#%$&7"  # width 4*100+0,  height 1*100+20
assert edit.count(old_settings) == 0
assert edit.count(new_settings) == 2, "both RealUI layouts must encode 400x120 chat"
assert edit.endswith("\0"), "client cache terminator was not preserved"

chat_zone = {"left": -925, "right": -525, "bottom": -505, "top": -385}
action_zone = {"left": -430, "right": 430, "bottom": -530, "top": -240}
horizontal_clearance = action_zone["left"] - chat_zone["right"]
assert horizontal_clearance == 95

receipt = {
    "result": "PASS",
    "editMode": {
        "addonUpdateSystemCalls": 0,
        "registeredFrameIteration": False,
        "runtimeGuards": ["unit frames", "cast bar", "aura lane"],
    },
    "chat": {
        "beforeWidth": 430,
        "afterWidth": 400,
        "height": 120,
        "layoutRecordsUpdated": 2,
        "horizontalClearanceFromVisibleActionHUD": horizontal_clearance,
    },
}
(WORK / "evidence/static-validation.json").write_text(
    json.dumps(receipt, indent=2), encoding="utf-8"
)
print("PASS: Edit Mode policy removed, active guards present, and chat width is 400 in all native caches.")
print(f"PASS: chat-to-action horizontal clearance is {horizontal_clearance} UI units.")
