local function texture()
    local t={}
    for _, method in ipairs({"SetTexture","SetTexCoord","ClearAllPoints","SetPoint","SetSize","SetColorTexture","SetAllPoints","AddMaskTexture","Show","Hide"}) do
        t[method]=function(self, ...)
            self[method]=self[method]
            self.lastMethod=method
            if method=="SetTexture" then self.texture=(...) end
            if method=="AddMaskTexture" then self.mask=(...) end
            if method=="Hide" then self.hidden=true end
        end
    end
    return t
end

local parent={id="L2"}
local button={id="PAD1", _state_type="custom", icon=texture(), width=50}
function button:GetParent() return parent end
function button:GetWidth() return self.width end
function button:CreateMaskTexture() self.createdMask=texture() return self.createdMask end
function button:CreateTexture() self.createdBackground=texture() return self.createdBackground end
function button:HookScript(kind, callback) self[kind]=callback end
button.NormalTexture=texture()
button.PushedTexture=texture()
button.HighlightTexture=texture()
button.CheckedTexture=texture()
button.Flash=texture()
button.Border=texture()
button.NewActionTexture=texture()
button.SpellHighlightTexture=texture()

local removals=0
local masque={Buttons={[button]=true}}
function masque:RemoveButton(target) removals=removals+1 self.Buttons[target]=nil end
local bank={buttons={PAD1=button}, msqGroup=masque}
function bank:UpdateButtons() end
function bank:OnMasqueLoaded() self.msqGroup.Buttons[button]=true end
ConsolePortGroupL2=bank

ConsolePortForeverDB={installedSchema=2}
C_Timer={After=function(_, callback) callback() end}
C_Spell={GetSpellTexture=function() return 1 end}
function GetBindingAction() return "ACTIONBUTTON1" end
function UnitExists() return false end
function InCombatLockdown() return false end
function hooksecurefunc(object, method, callback)
    local original=object[method]
    object[method]=function(self, ...)
        local results={original(self,...)}
        callback(self,...)
        return table.unpack(results)
    end
end
function CreateFrame()
    local frame={events={}}
    function frame:RegisterEvent(event) self.events[event]=true end
    function frame:SetScript(kind, script) self[kind]=script end
    return frame
end

local Addon={SCHEMA=2}
assert(loadfile("_retail_/Interface/AddOns/ConsolePort_Forever/Skin.lua"))("ConsolePort_Forever",Addon)
Addon:RefreshConsolePortSkin()
assert(removals==1 and not masque.Buttons[button], "face button remained enrolled in Masque")
assert(button.IconMask and button.IconMask.texture=="Interface\\Masks\\CircleMaskScalable", "circle mask was not installed")
assert(button.NormalTexture.texture=="Interface\\AddOns\\ConsolePort\\Assets\\Textures\\Cursor\\RoundBorderHighlight", "round ring was not installed")
assert(button.isForeverFaceButton and button.__cpfInstalled, "face skin flags were not installed")

bank:OnMasqueLoaded()
assert(removals==2 and not masque.Buttons[button], "Masque re-enrollment was not removed")

print("PASS detach Masque -> round skin -> survive Masque reload")
