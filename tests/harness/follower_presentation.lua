-- Executes actual locked LAB spell getters, native ConsolePort texture
-- composition and Blizzard zone Refresh; all texture pixels/C APIs are doubles.
TEST_SUCCESS=nil
--@FOLLOWER_PRESENTATION_SOURCE
do
local total,zoneReads,textureWrites=0,0,0
local function expect(value,message) total=total+1 assert(value,message) end
local Spell={}
--@FOLLOWER_NATIVE_LAB_SPELL_PRESENTATION
local button=CreateFrame('Button',nil,ring,'SecureActionButtonTemplate')
button.icon=button:CreateTexture() button.icon.parent=button
button.icon.SetTexture=env.ActionButton.SkinUtility.SetTexture
button.GetTexture=Spell.GetTexture button.GetCooldownInfo=Spell.GetCooldownInfo
button.GetChargeInfo=Spell.GetChargeInfo
button._state_type='spell' button._state_action=ID
local defaultContext=true
local zoneIcon,override=1111,ID
GetSpellTexture=function() return 1000 end
local cooldown={startTime=3,duration=10,isEnabled=true}
local charges={currentCharges=1,maxCharges=2}
C_Spell.GetSpellCooldown=function(id) expect(tonumber(id)==ID,'native cooldown identity changed') return cooldown end
C_Spell.GetSpellCharges=function(id) expect(tonumber(id)==ID,'native charge identity changed') return charges end
C_ZoneAbility.GetZoneAbilityIcon=function(id) zoneReads=zoneReads+1 expect(id==override,'zone icon did not follow native override') return zoneIcon end
C_SpellBook.FindSpellOverrideByID=function() return override end
local nativeButton={spellID=ID,GetSpellID=ZoneAbilityFrameSpellButtonMixin.GetSpellID,
    GetOverrideSpellID=ZoneAbilityFrameSpellButtonMixin.GetOverrideSpellID,
    Icon={SetTexture=function(self,value) self.texture=value end},Count={SetText=function() end}}
C_Spell.GetSpellCastCount=function() return 0 end
ActionButton_ApplyCooldown=function() end
local available=true
local view=Addon.FollowerPresentationPrototype.New(button,{
    matches=function(widget) return available and defaultContext and widget._state_type=='spell' and tonumber(widget._state_action)==ID end,
    public=function(value) return type(value)~='table' end,
    zoneIcon=function(id)
        -- Match Blizzard's override resolution before its zone-icon API.
        return C_ZoneAbility.GetZoneAbilityIcon(C_SpellBook.FindSpellOverrideByID(id) or id)
    end})
local function nativeWrite()
    button.icon:SetTexture(button:GetTexture()) textureWrites=textureWrites+1
end
for _,value in ipairs({1111,2222,1111,2222}) do
    zoneIcon=value
    ZoneAbilityFrameSpellButtonMixin.Refresh(nativeButton)
    nativeWrite() nativeWrite() -- later LAB redraw must not restore fixed icon.
    expect(button.icon.texture==nativeButton.Icon.texture,'later native texture update restored stale follower icon')
    expect(button:GetCooldownInfo()==cooldown and button:GetChargeInfo()==charges,
        'cosmetic view changed native cooldown or charge feedback')
end
override=ID+1 zoneIcon=3333 nativeWrite()
expect(button.icon.texture==3333,'presentation failed native spell override transition')
override=ID
-- Pool reuse and other contexts share widget instances. They must immediately
-- return to the original native texture path, not a remembered follower icon.
button._state_action=999002 nativeWrite()
expect(button.icon.texture==1000,'reused widget retained follower icon')
button._state_action=ID defaultContext=false nativeWrite()
expect(button.icon.texture==1000,'follower view escaped active default ring scope')
defaultContext=true button._state_type='item' nativeWrite()
expect(button.icon.texture==1000,'follower view escaped native spell type')
button._state_type='spell' available=false nativeWrite()
expect(button.icon.texture==1000,'unready view overwrote native fallback')
available=true
zoneIcon={opaque=true} nativeWrite()
expect(button.icon.texture==1000,'opaque icon was manufactured into public artwork')
zoneIcon=2222 expect(view:Refresh() and button.icon.texture==2222,'event-sized cosmetic refresh failed')
-- Preserve native atlas/function composition and its unmount before numeric
-- spell artwork. Do not replace the ConsolePort texture setter with a raw C call.
button.icon:SetTexture(function(region)
    region:SetTexCoord(.1,.2,.3,.4)
    return function(icon) icon:SetTexCoord(0,1,0,1) end
end)
nativeWrite()
expect(Addon.Core.Equal(button.icon.uv,{0,1,0,1}), 'follower texture bypassed native function unmount')
local original=view.before
expect(view:Abort() and button.icon.SetTexture==original,'cosmetic abort lost native texture owner')
nativeWrite() expect(button.icon.texture==1000,'aborted view retained follower artwork')
view=Addon.FollowerPresentationPrototype.New(button,{matches=function() return true end,public=function() return true end,zoneIcon=function() return 2222 end})
local foreign=function() end button.icon.SetTexture=foreign
expect(not view:Refresh() and not view:Abort() and button.icon.SetTexture==foreign,
    'cosmetic detach overwrote foreign texture owner')
FOLLOWER_PRESENTATION_RESULTS={checks=total,zoneReads=zoneReads,nativeTextureWrites=textureWrites,
    staleIconRejected=true,overrideAndReuseCovered=true,nativeFeedbackGettersPreserved=true,
    actualPixelsQualified=false,
    limit='Actual LAB getters, ConsolePort setter and Blizzard Refresh execute; C textures/metadata are doubles. No event-registration integration, actual pixels, secure dispatch or hidden-control qualification.'}
TEST_SUCCESS=true
end
