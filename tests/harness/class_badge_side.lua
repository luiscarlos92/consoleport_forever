-- The class chord selects BOTH the badge bank and its continuous fade source.
rootScale=1 screenW,screenH=1920,1080 UIParent:SetSize(screenW,screenH) BOUNDS.z=1
layout(270,5,160,'Base')
local badge=ConsolePortGroupBase.__cpfClassShortcut
local rightPoint
for _,side in ipairs({'R2','L2'}) do
    Addon.adapters.rings.api.classChord=side=='L2' and Addon.ClassActions.LEFT_CHORD or Addon.ClassActions.CHORD
    HUD.ClassShortcut(ConsolePortGroupBase)
    local bank=_G['ConsolePortGroup'..side]
    assert(badge.point[2]==bank.buttons.PADDDOWN,'class badge placed under wrong bank')
    assert(badge:GetWidth()==26 and badge.prompt:GetHeight()==18,'approved class group size changed')
    for _,alpha in ipairs({.45,.7,1,.8,.45}) do
        bank:SetAlpha(alpha) badge.OnUpdate(badge,.016)
        assert(math.abs(badge:GetEffectiveAlpha()-bank:GetEffectiveAlpha())<.001,'class icon opacity does not follow its bank')
        assert(math.abs(badge.prompt:GetEffectiveAlpha()-bank:GetEffectiveAlpha())<.001,'class chord opacity does not follow its bank')
    end
    local rect=HUD.Rect(badge)
    if side=='R2' then rightPoint=rect
    else assert(math.abs(rect.y-rightPoint.y)<.001 and math.abs(rightPoint.x-rect.x-540*.94)<.001,'left class placement not proportional to approved right placement') end
end
-- Old bank hide callbacks must not hide a badge reassigned to the other side.
ConsolePortGroupR2.OnHide()
assert(badge:IsShown(),'old class bank hid reassigned badge')
ConsolePortGroupL2:Hide() ConsolePortGroupL2.OnHide()
assert(not badge:IsVisible(),'class badge survived hidden owning bank')
ConsolePortGroupL2:Show() ConsolePortGroupL2.OnShow()
assert(badge:IsVisible(),'class badge failed to return with its bank')
TEST_SUCCESS=true
