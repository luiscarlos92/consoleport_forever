-- Blizzard's native Update may Show the row again after a spell/form event.
function Frame:Show() self.shown=true end
function Frame:SetShown(value) self.shown=value end
function GetNumShapeshiftForms() return 3 end
function ActionBarBusy() return false end
function bar:UpdateBackgroundArt() end
function bar:UpdateState() self.stateUpdates=(self.stateUpdates or 0)+1 end
--@NATIVE_STANCE_UPDATE
bar.Update=StanceBarMixin.Update
bar:SetParent(UIParent)
assert(Class.UpdateNativeBar(addon,api,false))
for iteration=1,8 do
    combat=iteration%2==0
    bar:Update()
    assert(bar.shown and bar.stateUpdates==iteration and not bar:IsVisible(),'native aura refresh leaked duplicate row')
    if combat then assert(not Class.UpdateNativeBar(addon,api,false),'combat attempted protected reparent') end
end
combat=false
assert(not Class.UpdateNativeBar(addon,api,true) and bar:IsVisible(),'editor did not restore native aura access')
assert(Class.UpdateNativeBar(addon,api,false) and not bar:IsVisible())
TEST_SUCCESS=true
