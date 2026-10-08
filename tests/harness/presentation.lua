local installed,combat=false,false
function Addon:IsCharacterInstalled() return installed end
function InCombatLockdown() return combat end
local timers,frames,eventFrames={},{},{}
C_Timer={After=function(_,callback) timers[#timers+1]=callback end}
local function flush()
    local count=0
    while #timers>0 do count=count+1 assert(count<100,'skin refresh loop') table.remove(timers,1)() end
end
local function fire(event)
    for _,frame in ipairs(eventFrames) do if frame.events[event] then frame.OnEvent(frame,event) end end
end
function hooksecurefunc(object,key,callback)
    local native=object[key]
    object[key]=function(...) local result=native(...) callback(...) return result end
end
local function region(parent)
    local r={maskCalls=0,parent=parent}
    for _,method in ipairs({'SetTexCoord','ClearAllPoints','SetPoint','SetSize','SetColorTexture','SetAllPoints','SetSwipeTexture','SetUseCircularEdge'}) do
        r[method]=function(self,...)
            if method=='ClearAllPoints' or method=='SetPoint' or method=='SetSize' or method=='SetAllPoints' then assert(not combat,'combat geometry mutation') end
            self[method..'Args']={...}
        end
    end
    function r:SetTexture(value) self.texture=value self.atlas=nil end
    function r:GetAtlas() return self.atlas end
    function r:GetParent() return self.parent end
    function r:SetAtlas(value)
        self.atlas=value self.texture='atlas-sheet'
        self:SetTexCoord(.125,.25,.375,.5)
    end
    function r:AddMaskTexture(mask) assert(self.parent==mask.parent,'cross-parent mask') self.mask=mask self.maskCalls=self.maskCalls+1 end
    function r:RemoveMaskTexture(mask) assert(self.mask==mask) self.mask=nil self.removals=(self.removals or 0)+1 end
    function r:Show() self.shown=true end function r:Hide() self.shown=false end
    function r:SetVertexColor(...) self.tint={...} end
    function r:SetDesaturated(value) self.desaturated=value end
    function r:SetSwipeColor(...) self.swipe={...} end
function r:SetAlpha(value) self.alpha=value end
    function r:SetBlendMode(value) self.blend=value end
    function r:SetDrawLayer(...) self.layer={...} end
    function r:SetText(value) self.text=value end
    function r:SetTextColor(...) self.textColor={...} end
    return r
end
local Frame={}
local locked=false
C_LevelLink={IsActionLocked=function() return locked end}
local WoWMainline=true
unpack=table.unpack
local function SpellVFX_ClearReticle() end
local function UpdateCooldown(button) button.cooldownUpdates=(button.cooldownUpdates or 0)+1 end
--@NATIVE_AVAILABILITY
local UNBOUND_GLYPH_ALPHA=0.5
local db=setmetatable({Gamepad={UseAtlasIcons=false}},{__call=function() return 'native-pad-glyph' end})
CPAPI=CPAPI or {}
CPAPI.SetTextureOrAtlas=function(obj,data) obj:SetTexture(data[1]) end
--@NATIVE_UNBOUND_GLYPH
C_EventUtils={IsEventValid=function(event) return event~='PLAYER_EQUIPMENT_CHANGED' end}
function Frame:RegisterEvent(event)
    assert(self.OnEvent,'skin handler must precede registration')
    assert(not event:find('PARTY_SYNC',1,true),'obsolete event')
    assert(event~='PLAYER_EQUIPMENT_CHANGED','invalid event was not filtered')
    if event=='PLAYER_TARGET_CHANGED' then error('simulated unavailable event') end
    self.events=self.events or {} self.events[event]=true
end
function Frame:SetScript(key,fn) self[key]=fn end
function Frame:SetSize(w,h) self.width=w self.height=h end function Frame:SetPoint(...) self.point={...} end function Frame:ClearAllPoints() self.point=nil end
function Frame:SetParent(parent) self.parent=parent end function Frame:GetParent() return self.parent end
function Frame:GetName() return self.name end function Frame:GetWidth() return self.width or 45 end function Frame:GetHeight() return self.height or 45 end
function Frame:CreateTexture() return region(self) end
function Frame:CreateFontString() return region() end
function Frame:CreateMaskTexture() assert(not combat) self.maskCount=(self.maskCount or 0)+1 return region(self) end
function Frame:HookScript(key,fn) self.hooks=self.hooks or {} self.hooks[key]=fn end
function Frame:Show() self.shown=true end function Frame:Hide() self.shown=false end
function CreateFrame(_,name,parent)
    if name then assert(not frames[name],'duplicate named prompt/frame') end
    local f=setmetatable({name=name,parent=parent},{__index=Frame})
    if name then frames[name]=f _G[name]=f else f.events={} eventFrames[#eventFrames+1]=f end return f
end
function wipe(t) for key in pairs(t) do t[key]=nil end end
local GMT,Group={},{}
local removals=0
local Core={}
local BASE_TEXTURE='native-square-frame'
local BASE_BLEND,BASE_LAYER,BASE_LEVEL,BASE_SIZE='BLEND','ARTWORK',0,50
local STR_SETATLAS,STR_SETTEXTURE='SetNormalAtlas','SetNormalTexture'
local random=math.random
local function GetTexCoords() return 0,1,0,1 end
local function GetColor() return 1,1,1,1 end
local function SetSkinPoint(region,button) region:SetAllPoints(button) end
--@NATIVE_MASQUE_NORMAL
local function SkinButton(button,regions,skin)
    assert(skin==false) removals=removals+1 button.icon:SetTexture('native-default')
    button._MSQ_CFG=button._MSQ_CFG or {
        GetTypeSkin=function(_,_,value) return value end,GetSize=function(_,w,h) return w,h end,
    }
    Core.Skin_Normal(nil,button,{Texture=BASE_TEXTURE,Width=50,Height=50,UseStates=false})
end
--@NATIVE_MASQUE_REMOVE
local CPGroupBar={}
local GROUP,GROUP_BUTTON='Group','GroupButton'
GROUP='Action Group' YELLOW_FONT_COLOR={WrapTextInColorCode=function(_,value) return value end}
local env={}
function env.MakeID(format,...) return string.format(format,...) end
local function makeButton(id,bank)
    local button=setmetatable({id=id,parent=bank,_state_type='custom',attributes={state=''},icon=region()},{__index=Frame})
    button.icon.parent=button
    for _,key in ipairs({'NormalTexture','PushedTexture','HighlightTexture','CheckedTexture','Flash','Border','NewActionTexture','SpellHighlightTexture','cooldown','chargeCooldown','lossOfControlCooldown'}) do button[key]=region(button) end
    function button:GetNormalTexture() return self.NormalTexture end
    button.SpellCastAnimFrame={Fill={FillMask=region(),InnerGlowTexture=region(),CastFill=region()},EndBurst={EndMask=region(),GlowRing=region()}}
    local fxParent=setmetatable({},{__index=Frame})
    for _,part in pairs(button.SpellCastAnimFrame) do for _,tex in pairs(part) do tex.parent=fxParent end end
    button.InterruptDisplay={Base={Base=region(fxParent)},Highlight={Mask=region(fxParent)}}
    button.TargetReticleAnimFrame={Base=region(fxParent),Mask=region(fxParent)}
    function button:GetAttribute(key) return self.attributes[key] end
    function button:SetProps() end function button:UpdateLocal() end function button:UpdateButtonArt() end
    function button:AddToMasque(group) group:AddButton(self) end
    return button
end
function env:Acquire(kind,name,id,bank) assert(kind==GROUP_BUTTON) return makeButton(id,bank) end
--@NATIVE_GROUP_SKIN_LIFECYCLE
local Manager={bindingSnapshot={PADDUP={['']=''},PADDLEFT={['']=''},PADDRIGHT={['']=''},PADDDOWN={['']=''},PAD1={['']='JUMP',['SHIFT-']='INTERACTTARGET'},PAD2={['']=''},PAD3={['']='INTERACTTARGET'},PAD4={['']='TURNORACTION'}}}
--@NATIVE_MANAGER_BINDINGS
local family='SHP'
local device={Label=family,GetIconForButton=function(_,id) return family..'/'..id,false end}
local callbacks={}
local presentationDB={Gamepad={Index={Modifier={Key={SHIFT='PADLTRIGGER',CTRL='PADRTRIGGER'}}},GetActiveDevice=function() return device end},
    RegisterCallback=function(_,event,fn) callbacks[event]=fn end}
Addon.adapters={consoleport={api={version='3.3.10'},bar={Manager=Manager},db=presentationDB}}
C_Spell={GetSpellTexture=function(id) return id end}
local classBinding='CLICK NativeClassRing:Auras'
local classChord=classBinding
function GetBindingAction(key) assert(key=='CTRL-PADRSHOULDER' or key=='SHIFT-PADLSHOULDER') return classChord end
local classRings={Data={Auras={{type='spell',spell=71},{type='spell',spell=2457}}},GetBindingForSet=function(_,id) assert(id=='Auras') return classBinding end}
Addon.adapters.rings={rings=classRings,api={classSet='Auras'}}
function GetNumShapeshiftForms() return 2 end
function GetShapeshiftFormInfo(slot) return 1,slot==2,true,slot==2 and 2457 or 71 end
function UnitExists() return false end
local function makeBank(id,name)
    local bank=setmetatable({id=id,name=name,buttons={},width=277.5,height=140,props={pos={point='BOTTOM',relPoint='BOTTOM',x=0,y=id=='Base' and 160 or id=='L2R2' and 5 or 80}}},{__index=Frame})
    bank.UpdateButtons=CPGroupBar.UpdateButtons bank.OnMasqueLoaded=CPGroupBar.OnMasqueLoaded
    function bank:OnRelease() wipe(self.buttons) end
    local group=setmetatable({Buttons={},db={Disabled=false}},{__index=GMT})
    function group:AddButton(button) self.Buttons[button]={} Group[button]=self end
    bank.msqGroup=group
    bank:UpdateButtons({PAD1={},PAD2={},PAD3={},PAD4={},PADDUP={},PADDDOWN={},PADDLEFT={},PADDRIGHT={}})
    return bank
end
for _,id in ipairs({'Base','L2','R2','L2R2'}) do _G['ConsolePortGroup'..id]=makeBank(id,'ConsolePortGroup'..id) end
--@PRODUCT_SKIN
fire('PLAYER_ENTERING_WORLD') flush()
assert(removals==0,'unaccepted configuration acquired skin ownership')
installed=true
Addon:RequestSkinRefresh() Addon:RequestSkinRefresh()
assert(#timers==1,'readiness refresh did not coalesce')
flush()
assert(removals==16)
for _,id in ipairs({'Base','L2','R2','L2R2'}) do
    local bank=_G['ConsolePortGroup'..id]
    assert(bank.msqGroup.Buttons[bank.buttons.PADDUP] and bank.buttons.PADDUP.IconMask==nil,'D-pad was detached/skinned')
    for _,key in ipairs({'PAD1','PAD2','PAD3','PAD4'}) do
        local b=bank.buttons[key]
        assert(b.maskCount==1 and b.icon.maskCalls==1 and b.SlotBackground.maskCalls==1 and not bank.msqGroup.Buttons[b])
        assert(b._MSQ_CFG.Normal_Custom and not b._MSQ_CFG.Normal_Custom.shown and b._MSQ_CFG.Normal_Custom.alpha==0,'Masque private square normal remains visible')
        assert(b.NormalTexture.shown and b.NormalTexture.alpha==1,'native round normal stays hidden after Masque reset')
        assert(b.__cpfEmptyArt.shown==(key=='PAD2' and id~='Base') and not b.__cpfEmptyArt.mask and not b.__cpfEmptyArt.desaturated)
        assert(b.Flash.mask==b.IconMask and b.__cpfRoundShadow.texture:find('ForeverInGame',1,true),'square flash or shadow survived')
        assert(b.SpellCastAnimFrame.Fill.CastFill.mask==b.SpellCastAnimFrame.Fill.CastFill.__cpfLocalMask and b.SpellCastAnimFrame.EndBurst.GlowRing.mask==b.SpellCastAnimFrame.EndBurst.GlowRing.__cpfLocalMask)
        assert(b.InterruptDisplay.Base.Base.mask==b.InterruptDisplay.Base.Base.__cpfLocalMask and b.TargetReticleAnimFrame.Base.mask==b.TargetReticleAnimFrame.Base.__cpfLocalMask)
    end
    for _,key in ipairs({'PADDUP','PADDDOWN','PADDLEFT','PADDRIGHT'}) do assert(bank.buttons[key].__cpfEmptyArt.shown and bank.buttons[key].__cpfEmptyArt.texture:find('ForeverInGame',1,true)) end
    if id~='Base' then assert(bank.__cpfBankPrompt.shown and bank.__cpfBankPrompt.icons[1].texture=='SHP/PADLTRIGGER' or id=='R2') end
end
for _,id in ipairs({'Base','L2','R2','L2R2'}) do
    local bank=_G['ConsolePortGroup'..id]
    assert(bank.point[5]==bank.props.pos.y,'bank did not return to original position')
    Addon:RefreshConsolePortSkin()
    assert(bank.point[5]==bank.props.pos.y,'bank refresh moved the original position')
    if id~='Base' then
        if id=='L2R2' then assert(bank.__cpfBankPrompt.point[5]==16 and bank.__cpfBankPrompt.point[1]=='BOTTOM')
        else assert(bank.__cpfBankPrompt.point[2]==bank.buttons.PADDRIGHT and bank.__cpfBankPrompt.point[5]==-4,'trigger label not beside D-pad') end
    end
end
local base=ConsolePortGroupBase
local bottom=ConsolePortGroupL2R2
local badge=base.__cpfClassShortcut
assert(badge.parent~=base,'class shortcut inherits the fading base bank')
assert(badge.width==26 and badge.prompt.height==18 and badge.point[2]==ConsolePortGroupR2.buttons.PADDDOWN,'class shortcut not fitted under R2')
assert(base.__cpfClassShortcut.shown and base.__cpfClassShortcut.icon.texture==2457,'class badge did not follow active stance')
assert(base.__cpfClassShortcut.prompt.icons[1].texture=='SHP/PADRSHOULDER' and base.__cpfClassShortcut.prompt.icons[2].texture=='SHP/PADRTRIGGER','class prompt shows a different chord')
assert(ConsolePortGroupL2R2.__cpfBankPrompt.plus[1].shown and not ConsolePortGroupL2R2.__cpfBankPrompt.plus[2].shown)
family='LTR' device.Label=family callbacks.OnIconsChanged() flush()
assert(ConsolePortGroupR2.__cpfBankPrompt.icons[1].texture=='LTR/PADRTRIGGER' and base.buttons.PAD1.__cpfEmptyArt.SetTexCoordArgs[1]==455/2048)
assert(frames.ConsolePortForeverFriendlyPrompt.glyph.texture=='LTR/PADLSHOULDER','target prompt retained PlayStation glyph')
family='REV' device.Label=family callbacks.OnIconsChanged() flush()
assert(base.buttons.PAD3.__cpfEmptyArt.SetTexCoordArgs[1]==463/2048)
family='SHP' device.Label=family callbacks.OnIconsChanged() flush()
C_Texture={GetAtlasInfo=function(name) return name:find('gamepad-actionbar-',1,true) and {} or nil end}
Addon:RefreshConsolePortSkin()
assert(base.buttons.PAD1.__cpfEmptyArt.atlas=='gamepad-actionbar-circleslot-ps-cross-normal')
assert(base.buttons.PADDLEFT.__cpfEmptyArt.atlas=='gamepad-actionbar-squareslot-generic-dpadleft-normal')
assert(base.buttons.PAD1.NormalTexture.atlas=='gamepad-actionbar-circleslot-border-normal')
assert(base.buttons.PAD1.NormalTexture.SetTexCoordArgs[1]==.125,'atlas UV was reset to its entire sheet')
-- The glyph atlas has its own subregion too.
local originalIcon=device.GetIconForButton
function device:GetIconForButton(id) return 'test-controller-atlas',true end
local glyph=region() Addon.HUDPresentation.Glyph(glyph,'PADRTRIGGER')
assert(glyph.SetTexCoordArgs[1]==.125 and glyph.SetTexCoordArgs[3]==.375,'prompt atlas UV reset')
device.GetIconForButton=originalIcon
assert(base.buttons.PAD1.PushedTexture.atlas=='gamepad-actionbar-circleslot-border-pressed')
assert(base.buttons.PAD1.__cpfRoundShadow.atlas=='gamepad-actionbar-circleslot-dropshadow')
family='REV' device.Label=family callbacks.OnIconsChanged() flush()
assert(base.buttons.PAD3.__cpfEmptyArt.atlas=='gamepad-actionbar-circleslot-xbox-y-normal','reversed face layout was labelled as Xbox')
C_Texture=nil family='SHP' device.Label=family callbacks.OnIconsChanged() flush()
classChord='TARGETSCANENEMY' Addon:RefreshConsolePortSkin()
assert(not base.__cpfClassShortcut.shown,'badge advertised an unbound class opener')
classChord=classBinding Addon:RefreshConsolePortSkin()
Addon.adapters.rings.api.classChord='SHIFT-PADLSHOULDER' Addon:RefreshConsolePortSkin()
assert(base.__cpfClassShortcut.prompt.icons[1].texture=='SHP/PADLSHOULDER' and base.__cpfClassShortcut.prompt.icons[2].texture=='SHP/PADLTRIGGER','left class prompt did not match L1+L2')
Addon.adapters.rings.api.classChord=nil Addon:RefreshConsolePortSkin()
local unbound=base.buttons.PAD4
Manager.bindingSnapshot.PAD4={['']=''}
local reset=ProxyButtonTextureProvider('PAD4',true)(unbound.icon)
unbound:UpdateLocal()
assert(unbound.__cpfEmptyArt.shown and not unbound.icon.shown,'legitimate unbound glyph state erased')
reset(unbound.icon) assert(unbound.icon.desaturated==false and unbound.icon.alpha==1)
Manager.bindingSnapshot.PAD4={['']='TURNORACTION'}
local exit=base.buttons.PAD2
ProxyButtonTextureProvider('PAD2',true)(exit.icon) exit:UpdateLocal()
assert(exit.icon.atlas=='128-redbutton-exit' and exit.icon.desaturated==false and exit.icon.alpha==1,'decorated Exit retained native unbound dimming')
local jump=base.buttons.PAD1
assert(jump.icon.texture:find('ForeverInGame',1,true))
jump.attributes.state='SHIFT-' jump:UpdateLocal() assert(jump.icon.texture==6603,'display ignored the resolved native state')
jump._state_type='action' jump.icon:SetTexture('native-spell') jump:UpdateLocal() assert(jump.icon.texture=='native-spell','style replaced a native spell icon')
assert(not jump.__cpfEmptyArt.shown,'assigned spell has a background glyph')
for _,kind in ipairs({'spell','item','macro','flyout'}) do
    jump._state_type=kind jump:UpdateLocal()
    assert(not jump.__cpfEmptyArt.shown,'assigned '..kind..' has a background glyph')
end
jump._state_type='action'
local actualNormal=region(jump) actualNormal:SetTexture('square-normal')
function jump:GetNormalTexture() return actualNormal end
jump:UpdateLocal()
assert(actualNormal.texture:find('ForeverInGame',1,true) and actualNormal.SetTexCoordArgs[1]==1093/2048,'native normal getter still has a square border')
combat=true jump._state_type='empty' jump:UpdateLocal()
assert(jump.__cpfEmptyArt.shown and not jump.icon.shown,'combat slot clear kept spell artwork')
jump._state_type='action' jump:UpdateLocal()
assert(not jump.__cpfEmptyArt.shown,'combat spell assignment kept an empty symbol')
combat=false
jump._state_type='custom' jump.attributes['cpf-held']=true jump.icon:SetTexture('held-native') jump:UpdateLocal() assert(jump.icon.texture=='held-native')
jump.attributes['cpf-held']=nil
Addon:RefreshConsolePortSkin() assert(removals==16 and jump.maskCount==1 and jump.icon.maskCalls==1)
local oldIcon=jump.icon
jump.icon=region(jump) jump:UpdateLocal()
assert(jump.icon.maskCalls==1 and oldIcon.mask==nil and oldIcon.removals==1)
local previousMask=jump.IconMask
jump.IconMask=region(jump) jump:UpdateLocal()
assert(jump.icon.mask==previousMask and jump.IconMask==previousMask and jump.icon.maskCalls==1,'native mask field replaced the owned circle')
jump.icon:RemoveMaskTexture(previousMask)
assert(jump.__cpfConnectedMask==nil and #timers==1,'removed mask was still cached as attached')
flush()
assert(jump.icon.mask==previousMask and jump.icon.maskCalls==2 and jump.icon.removals==1,'removed mask was not restored')
local sparse=base.buttons.PAD3
sparse.NormalTexture=nil sparse.PushedTexture=nil
sparse.Border:SetTexture('native-square') sparse:UpdateButtonArt()
assert(sparse.Border.texture:find('ForeverInGame',1,true),'optional region hole skipped later borders')
local width=sparse.GetWidth
sparse.GetWidth=function() error('simulated one-face skin failure') end
Addon:RequestSkinRefresh() flush()
assert(Addon.Diagnostics.features.faceSkin.status=='pending','individual skin failure was reported as ready')
sparse.GetWidth=width
fire('ACTIONBAR_SLOT_CHANGED') flush()
assert(Addon.Diagnostics.features.faceSkin.status=='offline-verified','later native refresh did not recover failed face')
local msq={Group=function(_,addon,name) assert(addon=='ConsolePort' and name) return base.msqGroup end}
base:OnMasqueLoaded(msq) flush() assert(removals==20 and base.msqGroup.Buttons[base.buttons.PADDUP])
base:UpdateButtons({PAD1={},PAD2={},PAD3={},PAD4={},PADDUP={}}) flush()
assert(removals==24 and base.buttons.PAD1.maskCount==1)
combat=true base:OnMasqueLoaded(msq)
local combatFace=base.buttons.PAD3
combatFace.NormalTexture:SetAtlas('native-square')
combatFace.SlotArt=region(combatFace) combatFace.SlotArt:Show()
combatFace:UpdateButtonArt()
assert(combatFace.NormalTexture.texture:find('ForeverInGame',1,true) and not combatFace.SlotArt.shown,'combat art refresh restores a square face')
local combatIcon=base.buttons.PAD4.icon
local combatMask=base.buttons.PAD4.IconMask
combatIcon:RemoveMaskTexture(combatMask)
fire('PLAYER_REGEN_DISABLED') flush()
assert(removals==24 and Addon.skinRefreshPending,'combat setup modified group membership or lost deferred work')
assert(combatIcon.mask==nil,'combat removal triggered protected mask repair')
base.buttons.PAD2.icon:SetTexture('native-ring') base.buttons.PAD2:UpdateLocal()
assert(base.buttons.PAD2.icon.atlas=='128-redbutton-exit','combat native update lost Exit art')
combat=false fire('PLAYER_REGEN_ENABLED') flush() assert(removals==28 and not Addon.skinRefreshPending)
assert(combatIcon.mask==combatMask,'deferred mask repair was lost')
base.buttons.PAD4.icon:SetTexture('native-mouse')
fire('PLAYER_ENTERING_WORLD') flush()
assert(base.buttons.PAD4.icon.atlas=='crosshair_unableinspect_32' and removals==28,'zone refresh lost look art or re-detached unchanged faces')
local face=base.buttons.PAD1
face._state_type='action' face._state_action=1
face.config={outOfRangeColoring='button',colors={range={1,.1,.1},mana={.1,.1,1}}}
function face:IsUsable() return true,false end
combat=true locked=true UpdateUsable(face) assert(face.icon.desaturated==true)
locked=false UpdateUsable(face) assert(face.icon.desaturated==false,'party-sync unlock retained stale desaturation')
UpdateUsable(face,false,false) assert(face.icon.tint[1]==.4,'unusable native tint was erased')
UpdateUsable(face,false,true) assert(face.icon.tint[3]==1 and face.icon.tint[1]==.1,'resource tint was erased')
face.outOfRange=true UpdateUsable(face) assert(face.icon.tint[1]==1 and face.icon.tint[2]==.1,'range tint was erased')
face.zoneAbilityDisabled=true UpdateUsable(face) assert(face.icon.desaturated==true,'disabled zone action desaturation was erased')
face.zoneAbilityDisabled=false Addon:RefreshFaceAvailability() assert(face.icon.desaturated==false)
face.cooldown:SetSwipeColor(0,0,0,0) assert(face.cooldown.swipe[4]==0,'casting animation transparency was erased')
SpellVFX_CastingAnim_OnHide({GetParent=function() return face end})
assert(face.cooldown.swipe[4]==.65 and face.cooldownUpdates==1,'native cast finish made swipe opaque')
face.lossOfControlCooldown:SetSwipeColor(.17,0,0,1)
assert(face.lossOfControlCooldown.swipe[1]==.17 and face.lossOfControlCooldown.swipe[4]==.65)
local dpad=base.buttons.PADDUP dpad.cooldown:SetSwipeColor(0,0,0,1) assert(dpad.cooldown.swipe[4]==1,'unowned D-pad cooldown was changed')
combat=false
installed=false base.buttons.PAD1.icon:SetTexture('manual-after-restore') base.buttons.PAD1:UpdateLocal()
assert(base.buttons.PAD1.icon.texture=='manual-after-restore','inactive hook reapplied owned skin')
base.buttons.PAD1.cooldown:SetSwipeColor(0,0,0,1) assert(base.buttons.PAD1.cooldown.swipe[4]==1,'inactive visual hook still owned cooldown color')
installed=true
local friendly=frames.ConsolePortForeverFriendlyPrompt
ConsolePortGroupBase=makeBank('Base','ReplacementBase') Addon:RefreshConsolePortSkin()
assert(frames.ConsolePortForeverFriendlyPrompt==friendly and friendly.parent==ConsolePortGroupBase,'replaced bank duplicated targeting prompt')
TEST_SUCCESS=true
