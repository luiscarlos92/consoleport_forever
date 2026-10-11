from dataclasses import dataclass
from pathlib import Path
import json

WORK = Path(__file__).resolve().parent
HELPER = WORK / "staged/Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua"

@dataclass(frozen=True)
class Rect:
    left: float
    right: float
    bottom: float
    top: float

    def overlaps(self, other: "Rect") -> bool:
        return (min(self.right, other.right) > max(self.left, other.left)
                and min(self.top, other.top) > max(self.bottom, other.bottom))

# UIParent-centered conservative envelopes at 1920x1080. These use the
# approved anchors, full Modern aura limits (32 buffs/16 debuffs), 30px icons,
# 5px padding, and larger-than-template transient-frame boxes.
zones = {
    "console_action_hud": Rect(-430, 430, -530, -240),
    "player_frame": Rect(-430, -190, -205, -145),
    "target_frame": Rect(190, 430, -205, -145),
    "chat": Rect(-925, -495, -505, -335),
    "buff_lane_32": Rect(-842, -442, -245, -140),
    "debuff_lane_16": Rect(-722, -442, -321, -251),
    "extra_ability": Rect(-40, 40, -80, 0),
    "vehicle_leave": Rect(69.5, 114.5, -80, -35),
    "encounter_bar": Rect(-115, 115, 0, 30),
    "cooldown_utility": Rect(-157.5, 157.5, 55, 100),
    "cooldown_essential": Rect(-270, 270, 110, 155),
    "cooldown_buff_icon": Rect(-22.5, 22.5, 165, 210),
    "cooldown_buff_bar": Rect(-700, -460, -40, 10),
    "talking_head": Rect(-705, -135, 165, 320),
    "archaeology": Rect(150, 450, 285, 315),
}

approved = {"console_action_hud", "player_frame", "target_frame", "chat"}
managed = set(zones) - approved
unexpected = []
for a in sorted(managed):
    for b in sorted(approved | (managed - {a})):
        if a >= b:
            continue
        if zones[a].overlaps(zones[b]):
            unexpected.append((a, b))

assert not unexpected, f"conservative collision model found: {unexpected}"

source = HELPER.read_text(encoding="utf-8")
required = [
    "point(frame, 'TOPRIGHT', player, 'TOPLEFT', -12, 5)",
    "point(frame, 'TOPRIGHT', buffs, 'BOTTOMRIGHT', 0, -6)",
    "container.addIconsToRight = false",
    "container.addIconsToTop = false",
    "if system == systems.UnitFrame then return true end",
    "SetAnchor(info, 'BOTTOM', 'CENTER', 0, -80)",
    "SetAnchor(info, 'BOTTOM', 'CENTER', 0, 0)",
    "SetAnchor(info, 'TOP', 'TOP', -420, -220)",
    "SetAnchor(info, 'BOTTOM', 'CENTER', 92, -80)",
    "SetAnchor(info, 'TOP', 'TOP', 300, -225)",
    "SetAnchor(info, 'BOTTOM', 'CENTER', 0, 110)",
    "SetAnchor(info, 'BOTTOM', 'CENTER', 0, 55)",
    "SetAnchor(info, 'BOTTOM', 'CENTER', 0, 165)",
    "SetAnchor(info, 'BOTTOMRIGHT', 'CENTER', -460, -40)",
]
missing = [needle for needle in required if needle not in source]
assert not missing, f"staged helper is missing policy anchors: {missing}"

forbidden = [
    "TargetFrame.buffsOnTop",
    "TargetFrame:UpdateAuras(",
    "TargetFrame:UpdateAuraContainerAnchors(",
    "HookUnitFrame",
    "UpdateSystemSettingBuffsOnTop",
]
present = [needle for needle in forbidden if needle in source]
assert not present, f"staged helper contains taint-prone unit-frame writes/hooks: {present}"
assert source.index("if system == systems.UnitFrame then return true end") < source.index("frame:UpdateSystem(info)"), \
    "the all-unit-frame guard must precede every addon-driven UpdateSystem call"

receipt = {
    "referenceCanvas": "1920x1080 UIParent-centered conservative model",
    "assumptions": {
        "buffs": "32 icons, 11 per row, 30 size, 5 padding, plus collapse control",
        "debuffs": "16 icons, 8 per row, 30 size, 5 padding",
        "transients": "boxes intentionally larger than their Blizzard templates",
    },
    "zones": {name: rect.__dict__ for name, rect in zones.items()},
    "unexpectedOverlaps": unexpected,
    "result": "PASS",
}
(WORK / "evidence/layout-collision-model.json").write_text(
    json.dumps(receipt, indent=2), encoding="utf-8")
print("PASS: conservative expansion envelopes do not intersect approved or managed zones.")
