local callbacks={}
local cursor={visible=false,isCombatPaused=false}
function cursor:IsShown() return self.visible end
function cursor:SetBasicControls() end
local function region(alpha)
    return {alpha=alpha,GetAlpha=function(self) return self.alpha end,SetAlpha=function(self,value) self.alpha=value end}
end
local icon,highlight=region(1),region(0.7)
local bank={buttons={PAD1={icon=icon,HighlightTexture=highlight}}}
local api={ConsolePortGroupBase=bank,InCombatLockdown=function() return false end,
    hooksecurefunc=function(object,name,callback)
        local native=object[name]
        object[name]=function(self,...) local result=native(self,...) callback(self,...) return result end
    end}
local bridge={db={Cursor=cursor,RegisterCallback=function(_,name,callback) callbacks[name]=callback end},
    bar={RegisterSafeCallback=function(_,name,callback) callbacks[name]=callback end}}
local visuals=Addon.FocusVisuals
assert(visuals:Enable(bridge,api,false) and icon.alpha==1)
assert(visuals:Enable(bridge,api,true))
cursor.visible=true callbacks.OnCursorShow()
assert(icon.alpha==1 and highlight.alpha==0,'UI focus hid action identity')
icon:SetAlpha(0.4) highlight:SetAlpha(0.25)
assert(icon.alpha==0.4 and highlight.alpha==0,'native icon update was hidden or highlights escaped suppression')
cursor.visible=false callbacks.OnCursorHide()
assert(icon.alpha==0.4 and highlight.alpha==0.25,'did not restore latest gameplay appearance')
cursor.visible=true cursor:SetBasicControls()
local newIcon=region(0.6)
bank.buttons.PAD2={icon=newIcon}
callbacks.OnLayoutChanged()
assert(newIcon.alpha==0.6,'pooled/rebuilt icon disappeared under UI focus')
assert(visuals:Enable(bridge,api,false) and newIcon.alpha==0.6 and icon.alpha==0.4)
Addon.VERSION,Addon.CONFIG_REVISION='test',2
Addon.Diagnostics:SetFeature('exactStickCommit','pending','ordinary axis callbacks have no protected commit authority')
local text=Addon.Proof:Text({GetCurrentBindingSet=function() return 2 end,GetBindingAction=function(key,effective) return effective and 'OVERRIDE' or 'SAVED' end})
assert(text:find('PAD1: SAVED -> OVERRIDE',1,true) and text:find('exactStickCommit: pending',1,true))
TEST_SUCCESS=true
