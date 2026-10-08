-- Keep the SAME frames through modifier/secure-scale changes during combat.
rootScale=1 screenW,screenH=1920,1080 UIParent:SetSize(screenW,screenH) BOUNDS.z=1
layout(270,5,160,'Base') assert(HUD.LayoutGuard())
local hints={L2=HUD.Rect(ConsolePortGroupL2.__cpfBankPrompt),R2=HUD.Rect(ConsolePortGroupR2.__cpfBankPrompt)}
local locked=true
function InCombatLockdown() return locked end
for iteration=1,8 do
    for _,selected in ipairs({'L2','R2','L2R2','Base'}) do
        for _,id in ipairs({'L2','R2','L2R2','Base'}) do _G['ConsolePortGroup'..id]:SetScale(id==selected and 1.06 or .94) end
        for _,id in ipairs({'L2','R2'}) do
            local rect=HUD.Rect(_G['ConsolePortGroup'..id].__cpfBankPrompt)
            assert(math.abs(rect.x-hints[id].x)<.001 and math.abs(rect.y-hints[id].y)<.001,'combat selection moved '..id..' prompt')
        end
    end
end
locked=false
for _,id in ipairs({'L2','R2'}) do HUD.BankPrompt(_G['ConsolePortGroup'..id],id) end
assert(HUD.LayoutGuard())
for _,id in ipairs({'L2','R2'}) do
    local rect=HUD.Rect(_G['ConsolePortGroup'..id].__cpfBankPrompt)
    assert(math.abs(rect.x-hints[id].x)<.001 and math.abs(rect.y-hints[id].y)<.001,'post-combat refresh moved trigger prompt')
end
TEST_SUCCESS=true
