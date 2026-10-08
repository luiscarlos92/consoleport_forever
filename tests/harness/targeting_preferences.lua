local combat=false
local Prefs=Addon.TargetingPreferences
local account={}
assert(Addon.Store.EnsureSchema(account,'A'))
local api={InCombatLockdown=function() return combat end,C_Spell={GetSpellInfo=function(id) return {name=Addon.GroundSpells[id] or 'Quest reticle',spellID=id} end},UnitClass=function() return 'Demon Hunter','DEMONHUNTER' end}
local prefs=Prefs.Read(account)
local registered={}
for _,ids in pairs(Prefs.Classes) do for _,id in ipairs(ids) do assert(Addon.GroundSpells[id] and not registered[id]) registered[id]=true end end
for id in pairs(Addon.GroundSpells) do assert(registered[id],'qualified spell missing from class options') end
assert(Prefs.Resolve(prefs,43265)=='player' and Prefs.Resolve(prefs,121536)=='player')
assert(Prefs.Resolve(prefs,204596)=='cursor' and Prefs.Resolve(prefs,204596,'vehicle')=='cursor')
local draft={spells={[204596]='player'},contexts={vehicle='manual',override='player'}}
assert(Prefs.Apply(account,draft,api))
Addon.Store.GetCharacter(account,'A',{spec=1}) Addon.Store.GetCharacter(account,'B',{spec=3})
assert(Prefs.Resolve(Prefs.Read(account),204596)=='player' and not account.characters.A.groundTargeting and not account.characters.B.groundTargeting)
draft.spells[204596]='manual' assert(Prefs.Read(account).spells[204596]=='player','draft mutated saved account settings')
combat=true assert(not Prefs.Apply(account,draft,api)) assert(Prefs.Read(account).spells[204596]=='player') combat=false
assert(#account.shared.groundTargetingHistory==1)
assert(not Prefs.Validate({spells='bad'})) assert(not Prefs.Validate({spells={[1]='target'}}))
assert(not Prefs.Validate({contexts={fake='cursor'}}))
local malformed={shared={groundTargeting={spells='bad'}}}
assert(not Prefs.Validate(Prefs.Read(malformed)),'malformed saved preferences silently became defaults')
local rows=Prefs.Rows('DEMONHUNTER',api,{[999001]=true})
assert(#rows==#Prefs.Classes.DEMONHUNTER+1)
for _,row in ipairs(rows) do assert(row.id~=43265 and row.id~=121536,'another class leaked into the panel') end
assert(not Prefs.Qualified(prefs,999001))
prefs={spells={[999001]='cursor'},contexts={}}
assert(Prefs.Qualified(prefs,999001))
prefs.spells[999001]='default' assert(not Prefs.Qualified(prefs,999001))
-- Use the exact native panel registration/mixin lifecycle, including deferred
-- configuration loading, nav creation and its first OnPanelLoad/OnPanelShow.
local env={callbacks={}}
local Frame={}
function Frame:Hide() self.shown=false end
function Frame:Show() local changed=not self.shown self.shown=true if changed and self.scripts.OnShow then self.scripts.OnShow(self) end end
function Frame:SetScript(key,fn) self.scripts[key]=fn end
function Frame:RegisterEvent() end
function Frame:SetAutoFocus() end function Frame:SetNumeric() end
function Frame:GetText() return self.text end
function Frame:SetText(text) self.text=text end
function Frame:SetPoint() end function Frame:ClearAllPoints() end function Frame:SetSize(w,h) self.w,self.h=w,h end
function Frame:SetHeight(h) self.h=h end function Frame:SetParent(p) self.parent=p end function Frame:SetID(id) self.id=id end
function Frame:SetVerticalScroll(v) self.offset=v end function Frame:SetScrollChild(c) self.child=c end
function Frame:CreateFontString() return setmetatable({scripts={}},{__index=Frame}) end
function CreateFrame() return setmetatable({scripts={}},{__index=Frame}) end
function Mixin(frame,...) for i=1,select('#',...) do for key,value in pairs(select(i,...)) do frame[key]=value end end return frame end
function CreateCounter(value) return function() value=value+1 return value end end
CPAPI={GetEnv=function() return env end}
function env:RegisterCallback(event,fn,owner,...)
    local args={...} self.callbacks[event]=self.callbacks[event] or {} self.callbacks[event][owner]={fn=fn,args=args}
end
function env:UnregisterCallback(event,owner) self.callbacks[event][owner]=nil end
function env:TriggerEvent(event,...)
    local queued={} for owner,call in pairs(self.callbacks[event] or {}) do queued[#queued+1]={owner,call} end
    for _,entry in ipairs(queued) do local args=Addon.Core.Copy(entry[2].args) for i=1,select('#',...) do args[#args+1]=select(i,...) end entry[2].fn(entry[1],table.unpack(args)) end
end
--@NATIVE_PANEL_LIFECYCLE
env:CreatePanel({name='About',nav=false})
ConsolePortConfig={CreatePanel=function(_,info) return env:CreatePanel(info) end}
Addon.adapters={consoleport={api={version='3.3.10'}}}
Addon.db=account
local refreshes=0 function Addon:RefreshModes() refreshes=refreshes+1 end
Addon.GroundTargeting.observed={[999001]=true}
for key,value in pairs(api) do _G[key]=value end
api=_G
--@PRODUCT_TARGETING_UI
combat=true Addon.TargetingUI:Initialize(api) assert(not Addon.TargetingUI.panel,'configuration panel created during combat') combat=false
Addon.TargetingUI:Initialize(api)
local panel=Addon.TargetingUI.panel
assert(panel and not panel.parent,'panel registered outside native deferred initialization')
local canvas=CreateFrame()
local pool={Flush=function(self) return self end,GetContainer=function() return canvas,not canvas.__cpfTargeting end}
local container={GetCanvas=function() return pool end}
local navCount=0
local config={Nav={AddButton=function(_,name) navCount=navCount+1 assert(name=='Targeting') return CreateFrame() end,SetButtonVisuals=function() end},Container=container}
env.Frame=config env:TriggerEvent('OnConfigLoad',config)
assert(panel.parent==container and navCount==1)
env:TriggerEvent('OnPanelLoad',panel.id)
assert(panel.shown and canvas.shown and #canvas.rows==#Prefs.Classes.DEMONHUNTER+5)
local flame
for _,row in ipairs(canvas.rows) do if row.title.text==Addon.GroundSpells[204596]..' (204596)' then flame=row end end
assert(flame and flame.choice.text=='At player')
flame.choice.scripts.OnClick() assert(flame.choice.text=='Manual placement')
assert(Prefs.Read(account).spells[204596]=='player','click saved before Apply')
combat=true canvas.apply.scripts.OnClick()
assert(Prefs.Read(account).spells[204596]=='player' and refreshes==0)
combat=false canvas.apply.scripts.OnClick()
assert(Prefs.Read(account).spells[204596]=='manual' and refreshes==1)
panel:OnDefaults()
assert(Addon.TargetingUI.draft.spells[204596]==nil and Prefs.Read(account).spells[204596]=='manual')
assert(navCount==1) Addon.TargetingUI:Initialize(api) assert(navCount==1)
-- Per-context spell choices override ordinary choices without changing them.
canvas.context.scripts.OnClick()
assert(Addon.TargetingUI.context=='vehicle')
flame.choice.scripts.OnClick() -- Default -> cursor for this spell in vehicle UI.
canvas.apply.scripts.OnClick()
assert(Prefs.Read(account).contextSpells.vehicle[204596]=='cursor')
assert(Prefs.Read(account).spells[204596]==nil)
assert(Prefs.Resolve({spells={[204596]='player'},contexts={vehicle='manual'},contextSpells={vehicle={[204596]='cursor'}}},204596,'vehicle')=='cursor')
assert(not Prefs.Validate({contextSpells={vehicle='bad'}}))
assert(not Prefs.Validate({contextSpells={fake={}}}))
canvas.spellID:SetText('999002') canvas.add.scripts.OnClick()
assert(Addon.TargetingUI.added[999002] and #canvas.rows==#Prefs.Classes.DEMONHUNTER+6)
canvas.spellID:SetText('invalid') canvas.add.scripts.OnClick()
assert(canvas.status.text=='Enter a valid spell ID.')
-- Inherited explicit custom choices must display the same mode they execute.
Addon.TargetingUI.draft.spells[999001]='player'
Addon.TargetingUI:Render(api,true)
local unknown
for _,row in ipairs(canvas.rows) do if row.title.text=='Quest reticle (999001)' then unknown=row end end
assert(unknown.choice.text=='Inherited: At player')
TEST_SUCCESS=true
