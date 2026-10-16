-- Actual Forever implementation after native ring/controller/zone source.
-- Spell APIs record requests, without inventing follower AI/C toggle semantics.
TEST_SUCCESS=nil
--@FOLLOWER_RUNTIME_SOURCE
--@FOLLOWER_EXTRA_CONTAINER_SOURCE
do
local assertions,named,rawRefreshes=0,0,0
local function verify(value,message) assertions=assertions+1 assert(value,message) end
local Generic,Spell={},{}
local type_meta_map={spell={},custom={},action={},item={},empty={}}
local str_match=string.match
--@FOLLOWER_LAB_STATE_SOURCE
Frame.SetState=Generic.SetState Frame.SetStateFromHandlerInsecure=Generic.SetStateFromHandlerInsecure
function Frame:GetTexture()
    if self:GetStateType()=='spell' then return Spell.GetTexture(self) end
    return Generic.GetTexture(self)
end
-- Retail IsShown is the local flag; IsVisible also includes parent visibility.
-- The earlier gesture-only fixture collapsed these two engine queries.
function Frame:IsShown() return self.shown==true end
function Frame:IsVisible() return self:IsShown() and (not self.parent or self.parent:IsVisible()) end
-- Header propagation is modeled; actual LAB validates/normalizes state keys.
function Frame:ClearStates() self.state_types={} self.state_actions={} self.states={} end
function Frame:Initialize() self:ClearStates() end
function Frame:UpdateState(state) self.states[state]={self.state_types[state],self.state_actions[state]} end
local localized='Dungeon Assistance'
-- Generic table comparison is modeled; native zone refresh decides whether
-- content changed, without a fixture-forced pool rebuild on unchanged input.
tCompare=function(a,b) return Addon.Core.Equal(a,b) end
CastSpellByName=function(...)
    verify(hardware and trusted,'named follower route lost native secure input')
    named=named+1 calls[#calls+1]={name=select(1,...),argc=select('#',...),id=ID}
end
function Frame:SetParent(parent) self.parent=parent end
function Frame:SetShown(value) if value then self:Show() else self:Hide() end end
function Frame:RegisterEvent(name) self.registered=self.registered or {} self.registered[name]=true end
function Frame:RegisterUnitEvent(name,unit) self:RegisterEvent(name) self.registered[name]=unit end
function Frame:UnregisterEvent(name) if self.registered then self.registered[name]=nil end end
function Region:GetAlpha() return self.alpha or 1 end
local eventCallbacks={}
for name,row in pairs(env.callbacks) do eventCallbacks[name]={row} end
function env:RegisterCallback(name,fn,owner)
    eventCallbacks[name]=eventCallbacks[name] or {} table.insert(eventCallbacks[name],{fn,owner})
end
function env:TriggerEvent(name,...)
    for _,row in ipairs(eventCallbacks[name] or {}) do row[1](row[2],...) end
end
local activeAbilities={{spellID=ID,uiPriority=1,textureKit='test'}}
local inside,enabled=true,true
local zoneIcon,override=2222,ID
C_Spell.GetSpellName=function(id) verify(id==ID,'localized name identity changed') return localized end
C_ZoneAbility.GetActiveAbilities=function() return Addon.Core.Copy(activeAbilities) end
C_ZoneAbility.GetZoneAbilityIcon=function(id)
    if id==999001 then return 4444 end
    verify(id==override,'zone icon ignored native override') return zoneIcon
end
C_SpellBook.FindSpellOverrideByID=function(id) return id==ID and override or id end
C_Spell.GetSpellCharges=function() end C_Spell.GetSpellCooldown=function() end C_Spell.GetSpellCastCount=function() return 0 end
GetSpellTexture=function() return 1111 end
ActionButton_ApplyCooldown=function() end
ActionButtonUtil={IsSpellOnAnyActiveActionBar=function() return false end}
PlayerIsTimerunning=function() return false end
C_Texture={GetAtlasInfo=function() end}
HelpTip={HideAll=function() end,IsShowingAny=function() return false end}
local container=CreateFrame('Frame',nil,UIParent)
Mixin(container,ExtraAbilityContainerMixin)
function container:Layout() end function container:MarkDirty() end container:OnLoad()
ExtraAbilityContainer=container
local extra=CreateFrame('Frame',nil,container,'SecureActionButtonTemplate')
container:AddFrame(extra,ExtraActionButtonPriority)
local zone=CreateFrame('Frame',nil,UIParent)
Mixin(zone,ZoneAbilityFrameMixin)
ZoneAbilityFrame=zone zone.Style=zone:CreateTexture()
local pool=CreateFrame('Frame',nil,zone)
zone.SpellButtonContainer=pool pool.buttons={} pool.active={}
function pool:EnumerateActive() local i=0 return function() i=i+1 return self.active[i] end end
function pool:SetContents(contents)
    local previous=self.active self.active={}
    for index,info in ipairs(contents) do
        local button=self.buttons[index]
        if not button then
            button=CreateFrame('Button',nil,self,'PingableActionButtonTemplate')
            Mixin(button,ZoneAbilityFrameSpellButtonMixin)
            button.Icon=button:CreateTexture() button.Count={SetText=function() end}
            self.buttons[index]=button
        end
        button:SetContent(info)
        -- Reused active frames need not emit another OnShow; native content
        -- update posthook must still reconcile a previous cosmetic suppression.
        if not previous[index] then button:Show() end
        self.active[index]=button
    end
    for index=#contents+1,#previous do previous[index]:Hide() end
end
zone:UpdateDisplayedZoneAbilities()
local edit=CreateFrame('Frame',nil,UIParent) edit:Hide()
local registry={callbacks={}}
function registry:RegisterCallback(name,fn,owner) self.callbacks[name]={fn,owner} end
local api={C_PartyInfo={IsPartyInFollowerDungeon=function() return inside end},C_ZoneAbility=C_ZoneAbility,
    C_Spell=C_Spell,C_SpellBook=C_SpellBook,CreateFrame=CreateFrame,InCombatLockdown=InCombatLockdown,
    C_Timer={After=function(_,fn) queue[#queue+1]=fn end},ZoneAbilityFrame=zone,
    EditModeManagerFrame=edit,EventRegistry=registry,ExtraAbilityContainer=container,
    issecretvalue=function(value) return type(value)=='table' and value.opaque end,
    hooksecurefunc=function(object,name,fn)
        local original=object[name]
        object[name]=function(...) local result={original(...)} fn(...) return table.unpack(result) end
    end}
local function blocked() return combat or ring:IsShown() or edit:IsShown() end
local originalRefresh=ring.RefreshAll
ring.RefreshAll=function(...) rawRefreshes=rawRefreshes+1 return originalRefresh(...) end
ring:Hide() ring.Data={[1]={[0]={},Addon.Core.Copy(transient)}} ring.Shared={}
local app={}
-- RunSafe's scheduling boundary is modeled here; existing utility suites
-- execute its native callback implementation and combat deferral separately.
function db:RunSafe(fn,...) verify(not combat,'initialization requested protected combat rebuild') return fn(...) end
local bridge={env=env,frame=ring,api={blocked=blocked},Enabled=function() return enabled end,Owns=function() return true end}
Addon.UtilityIntegration:StartFollower(app,api,bridge)
local follower=assert(app.followerDungeon,'utility initialization did not install follower correction')
local initialMap=env.GetKindAndAction
Addon.UtilityIntegration:StartFollower(app,api,bridge)
verify(app.followerDungeon==follower and env.GetKindAndAction==initialMap,'repeated initialization replaced native follower owner')
ring:RefreshAll() ring.widgets[1]:UpdateLocal() pump()
local slot=ring.secureEnv.DATA['1'][1]
verify(slot.type=='spell' and slot.spell==localized,'follower did not compile native spell-name route')
verify(ring.Data[1][1].spell==ID and ring.Data[1][1].type=='spell' and ring.Data[1][1].autoassigned,
    'runtime changed authoritative temporary entry identity')
verify(ring.widgets[1].states['1'][1]=='spell' and tonumber(ring.widgets[1].states['1'][2])==ID,
    'runtime replaced native LAB spell feedback')
nativeSettings.ringPressAndHold=true ring:OnPressAndHoldChanged()
currentIndex=1 edge('LeftButton',true) ring.widgets[1]:UpdateLocal()
ring.widgets[1].icon:SetTexture(1111)
verify(ring.widgets[1].icon.texture==zoneIcon,'runtime retained stale generic ring icon: kind='..tostring(ring.widgets[1]:GetStateType())
    ..' action='..tostring(ring.widgets[1]:GetStateAction())..' state='..tostring(ring:GetAttribute('state'))
    ..' view='..tostring(follower.views[ring.widgets[1]]~=nil)..' active='..tostring(follower.active)
    ..' matches='..tostring(follower:Matches(ring.widgets[1]))..' value='..tostring(ring.widgets[1].icon.texture))
edge('LeftButton',false)
local primary=pool.buttons[1]
verify(not primary:IsShown() and zone.Style:GetAlpha()==0 and extra:IsShown() and container:IsShown(),
    'selective follower suppression hid or retained wrong native controls')
verify(#container.frames==2 and extra.layoutIndex==1 and zone.layoutIndex==2,
    'follower suppression changed native extra container ownership or ordering')
local gestures=0
for _,adapter in ipairs({false,true}) do
    if adapter then attach() end
    for _,hold in ipairs({true,false}) do
        for _,keyDown in ipairs({'0','1'}) do
            nativeSettings.ringPressAndHold=hold ring:OnPressAndHoldChanged()
            nativeSettings.ringStickySelect=false ring:OnStickySelectChanged()
            cvars.ActionButtonUseKeyDown=keyDown
            for _,inCombat in ipairs({false,true}) do
                combat=inCombat
                for _,modifier in ipairs({'','shift','ctrl','ctrlshift'}) do
                    FOLLOWER_MODIFIERS={shift=modifier:find('shift')~=nil,ctrl=modifier:find('ctrl')~=nil}
                    for repeatIndex=1,2 do
                        currentIndex=1 local before=#calls
                        edge('LeftButton',true) edge('LeftButton',false)
                        if not hold then edge('LeftButton',true) edge('LeftButton',false) end
                        verify(#calls==before+1 and calls[#calls].name==localized and calls[#calls].argc==2,
                            'follower release did not issue one native name request')
                        gestures=gestures+1
                    end
                end
                combat=false
            end
        end
    end
    if adapter then pump() detach() end
end
FOLLOWER_MODIFIERS={} cvars.ActionButtonUseKeyDown='1'
local refreshes,workers=rawRefreshes,follower.counts.workers
for i=1,120 do follower.events:GetScript('OnEvent')(follower.events,'SPELL_UPDATE_COOLDOWN') end
pump()
verify(rawRefreshes==refreshes and follower.counts.workers==workers+1,'routine follower icon events rebuilt native rings or scheduled unbounded work')
zoneIcon=3333 override=ID+1
follower.events:GetScript('OnEvent')(follower.events,'UNIT_AURA','player') pump()
verify(ring.widgets[1].icon.texture==3333,'runtime missed native zone icon change')
override=ID
-- Coexisting zone ability stays visible with its shared style; extra action is
-- a separate actual native container sibling throughout.
activeAbilities={{spellID=ID,uiPriority=1,textureKit='test'},{spellID=999001,uiPriority=2,textureKit='test'}}
zone:UpdateDisplayedZoneAbilities() pump()
verify(not primary:IsShown() and pool.buttons[2]:IsShown() and zone.Style:GetAlpha()==1 and extra:IsShown(),
    'selective suppression removed sibling zone or extra ability')
-- Native pool reuse with only another zone ability must restore an owned hide.
activeAbilities={{spellID=999001,uiPriority=1,textureKit='test'}}
zone:UpdateDisplayedZoneAbilities() pump()
verify(primary:GetSpellID()==999001 and primary:IsShown() and extra:IsShown() and zone.Style:GetAlpha()==1,
    'pooled unrelated zone ability retained follower suppression')
activeAbilities={{spellID=ID,uiPriority=1,textureKit='test'}}
zone:UpdateDisplayedZoneAbilities() pump()
verify(not primary:IsShown(),'follower re-entry did not restore selective suppression')
edit:Show() follower:Queue(false) pump()
verify(primary:IsShown() and zone.Style:GetAlpha()==1,'Edit Mode did not restore native follower control')
edit:Hide() follower:Queue(false) pump()
verify(not primary:IsShown(),'Edit Mode exit retained duplicate follower control')
-- Active abilities can arrive/change after world entry, including while held.
-- The native zone posthook invalidates context; closing resumes compilation.
ring:Show() activeAbilities={}
zone:UpdateDisplayedZoneAbilities() pump()
verify(not follower.active and follower.recompile,'held zone transition bypassed context deferral')
ring:Hide() pump()
verify(not follower.recompile and ring.secureEnv.DATA['1'][1].spell==ID,'closing held ring did not resume deferred native compilation')
activeAbilities={{spellID=ID,uiPriority=1,textureKit='test'}}
zone:UpdateDisplayedZoneAbilities() pump()
verify(follower.active and ring.secureEnv.DATA['1'][1].spell==localized and not primary:IsShown(),
    'late native zone update did not activate follower correction')
-- A name unavailable or a secret context never hides the original fallback.
inside={opaque=true} follower:Queue(true) pump()
verify(primary:IsShown() and zone.Style:GetAlpha()==1,'opaque follower context hid native fallback')
inside=true follower:Queue(true) pump()
localized='Asistencia de mazmorra' follower:Queue(true) pump()
verify(ring.secureEnv.DATA['1'][1].spell==localized,'native localized name refresh did not recompile')
enabled=false follower:Queue(true) pump()
verify(primary:IsShown() and not follower.events.registered.UNIT_AURA,'disabled feature retained suppression or active cosmetic event worker')
local oldMap=env.GetKindAndAction
verify(not Addon.FollowerDungeon.New(env,api,function() return false end,blocked) and env.GetKindAndAction==oldMap,
    'disabled startup installed follower hooks')
enabled=true follower:Queue(true) pump()
-- An already protected stock button is left available; public suppression
-- never gains authority from alpha, a timer or a prior observed spell ID.
primary:Show() primary.protected=true combat=true follower:Queue(false) pump()
verify(primary:IsShown(),'protected stock fallback was hidden in combat')
-- If a frame becomes protected after an owned hide, restoring it waits for
-- regen; public observations never authorize a protected combat write.
primary.protected=false primary:Show() follower:Queue(false) pump()
verify(not primary:IsShown(),'owned follower suppression did not resume')
primary.protected=true combat=true enabled=false follower:Queue(false) pump()
verify(not primary:IsShown() and follower.hidden[primary],'protected restoration lost deferred owner')
combat=false follower.events:GetScript('OnEvent')(follower.events,'PLAYER_REGEN_ENABLED') pump()
verify(primary:IsShown() and not follower.hidden[primary],'protected restoration did not complete after combat')
primary.protected=false enabled=true follower:Queue(false) pump()
local foreign=function(owner,info) return follower.beforeMap(owner,info) end
env.GetKindAndAction=foreign follower:Queue(false) pump()
verify(primary:IsShown() and not follower:Owns(),'lost native mapping owner retained hidden fallback')
env.GetKindAndAction=oldMap
FOLLOWER_RUNTIME_RESULTS={checks=assertions,gestures=gestures,nativeNameRequests=named,
    sourceIdentityPreserved=true,nativeLABStatePreserved=true,selectiveNativeSuppression=true,
    poolReuseEditModeUnknownAndDisableCovered=true,coalescedCooldownBurst=120,
    protectedCombatDispatch='native SECURE_ACTIONS.spell -> CastSpellByName',
    limit='Cast APIs record requests; no invented C/server toggle semantics. Pool, protection, native texture pixels and event delivery are modeled; Retail acceptance remains pending.'}
TEST_SUCCESS=true
end
