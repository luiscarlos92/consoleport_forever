local C=Addon.Core
local queued,ready,combat,editing={},false,false,false
function RunNextFrame(callback) queued[#queued+1]=callback end
local function advance()
    ready=true local current=queued queued={}
    for _,callback in ipairs(current) do callback() end
end
function abs(value) return math.abs(value) end
UIParent={GetBottom=function(frame) return frame.bottom or 0 end}
local config={boxpoint='Bottom',anidivisor=5,elementscale=1,boxoffsetX=17,boxoffsetY=39,scale=1.2}
local L=setmetatable({},{__call=function(_,key) return config[key] end})
local frame={shown=true}
local Events,Frame=frame,{}
local API={IsQuestCompletable=function() return true end,GetTitleText=function() return 'Required Items' end,
    GetProgressText=function() return 'Progress' end,GetRewardText=function() return 'Rewards' end}
local quest=123
function GetTime() return 10 end
function frame:IsShown() return self.shown end
function frame:HookScript(key,callback) self[key]=callback end
function frame:PlayIntro() self.shown=true end
function frame:AddHint() end
function frame:ToggleHintState() end
function frame:HandleGossipQuestOverlap() end
function frame:UpdateItems() end
function frame:UpdateBackground() end
local function measured(children)
    local result={shown=true,height=403,width=570,children=children or {}}
    function result:GetChildren() return table.unpack(self.children) end
    function result:GetRegions() end
    function result:IsShown() return self.shown end
    function result:SetSize(w,h) self.width,self.height=w,h end
    function result:SetWidth(w) self.width=w end
    function result:SetHeight(h) self.height=h end
    function result:GetSize() return self.width,self.height end
    function result:GetTop() return 1000 end
    function result:GetBottom() return 1000-self.height end
    function result:GetLeft() return 0 end
    function result:GetRight() return self.width end
    return result
end
local child={height=200,shown=true}
function child:IsShown() return self.shown end
function child:GetTop() return ready and 1000 or nil end
function child:GetBottom() return ready and 1000-self.height or nil end
function child:GetLeft() return ready and 0 or nil end
function child:GetRight() return ready and 120 or nil end
local progress=measured({child})
local elements=measured({progress}) elements.Progress=progress
local AdjustMixin={}
--@NATIVE_ADJUST_CHILDREN
for key,value in pairs(AdjustMixin) do elements[key]=value progress[key]=value end
local Elements={}
--@NATIVE_BOUNDARIES
elements.UpdateBoundaries=Elements.UpdateBoundaries
function elements:ShowProgress() self.shown=true progress.shown=self.hasItems~=false return progress.shown end
local talk={Elements=elements,extraY=0,bottom=39}
local TalkBox={}
--@NATIVE_TALKBOX_OFFSETS
for key,value in pairs(TalkBox) do talk[key]=value end
function talk:IsVisible() return frame.shown end
function talk:SetPoint(point,parent,x,y) self.point,self.bottom=point,y end
function talk:SetScript(key,callback) self[key]=callback end
frame.TalkBox=talk
function frame:UpdateTalkingHead() talk:SetExtraOffset(0) end
function frame:ResetElements() elements.shown=false progress.shown=false end
function frame:AddQuestInfo() talk:SetExtraOffset(375) end
--@NATIVE_QUEST_EVENTS
--@NATIVE_FRAME_EVENT
frame.OnEvent=Frame.OnEvent
local cfgBefore=C.Copy(config)
-- The pinned handler reads the first measurement. The native next-frame
-- measurement changes the height but never recalculates its extra offset.
frame:OnEvent('QUEST_PROGRESS')
assert(talk.extraY==49)
advance() assert(progress.height==200 and talk.extraY==49,'native defect no longer reproduced')
local db=assert(Addon.Store.EnsureSchema({},'G'))
local record=assert(Addon.Store.GetCharacter(db,'G')); record.appliedRevision=17
local owner={db=db,record=record,guid='G',CONFIG_REVISION=17}
function owner:IsCharacterInstalled() return self.record.appliedRevision>0 end
local api={ImmersionFrame=frame,ImmersionSetup=config,RunNextFrame=RunNextFrame,GetQuestID=function() return quest end,
    InCombatLockdown=function() return combat end,EditModeManagerFrame={IsShown=function() return editing end},
    C_AddOns={GetAddOnMetadata=function() return '1.4.61' end,IsAddOnLoaded=function() return true end}}
local hooks=0
function api.hooksecurefunc(target,key,callback)
    hooks=hooks+1 local original=target[key]
    target[key]=function(...) local result=original(...) callback(...) return result end
end
owner.adapters={immersionProgress=Addon.FlatConfigAdapter.New(function() return db.shared.integrationPolicy end,
    {immersionProgressRepairVersion=true},api.InCombatLockdown)}
local repair=Addon.ImmersionProgress
assert(repair:Refresh(owner,api))
assert(hooks==2 and db.shared.integrationPolicy.immersionProgressRepairVersion==1)
assert(db.nextTransactionID==1 and db.backups['1'] and db.transactions['1'].status=='committed')
assert(#db.transactions['1'].steps==1 and record.appliedRevision==17)
assert(repair:Refresh(owner,api) and hooks==2 and db.nextTransactionID==1)
ready=false frame:OnEvent('QUEST_PROGRESS') assert(talk.extraY==49)
advance() assert(talk.extraY==49) advance() assert(talk.extraY==248)
assert(talk.offsetX==17 and talk.offsetY==39 and C.Equal(cfgBefore,config),'native settings or base offsets changed')
for i=1,100 do if talk.OnUpdate then talk.OnUpdate(talk) end end
assert(math.abs(talk.bottom-(39+248))<0.3,'native bottom animation did not finish at repaired offset')
-- All counts/layout heights use the measured child geometry, including money
-- and currency panels. Scale stays native and later settings edits are read.
for _,height in ipairs({28,75,150,310}) do
    child.height=height config.elementscale=1.5 frame:OnEvent('QUEST_PROGRESS') advance() advance()
    assert(talk.extraY==(height+48)*1.5)
end
config.elementscale=1 child.height=200
-- Stale/hidden callbacks cannot affect another dialog or edited setting.
local function cancelled(change)
    frame.shown=true elements.hasItems=true config.boxpoint='Bottom' config.anidivisor=5 config.nameplatemode=false
    db.shared.integrationPolicy.immersionProgressRepairVersion=1 combat=false editing=false
    frame:OnEvent('QUEST_PROGRESS') local original=talk.extraY
    change() advance() local expected=talk.extraY advance()
    assert(talk.extraY==expected,'stale or ineligible correction changed layout')
end
cancelled(function() frame:OnEvent('QUEST_COMPLETE') assert(talk.extraY==375) end)
cancelled(function() frame.shown=false frame.OnHide() end)
cancelled(function() quest=quest+1 end)
cancelled(function() combat=true end)
cancelled(function() editing=true end)
cancelled(function() config.elementscale=math.huge end) config.elementscale=1
cancelled(function() config.boxpoint='Top' end)
cancelled(function() config.anidivisor=0 end)
cancelled(function() config.nameplatemode=true end)
cancelled(function() db.shared.integrationPolicy.immersionProgressRepairVersion=0 end)
cancelled(function() owner.busy=true end) owner.busy=false
combat=false editing=false config.boxpoint='Bottom' config.anidivisor=5 config.nameplatemode=false
db.shared.integrationPolicy.immersionProgressRepairVersion=1
-- No Required Items leaves the native reset; QUEST_ITEM_UPDATE recomputes the
-- same progress dialog. A subsequent progress event supersedes a queued one.
elements.hasItems=false frame:OnEvent('QUEST_PROGRESS') advance() advance() assert(not progress.shown)
elements.hasItems=true frame:OnEvent('QUEST_PROGRESS') child.height=180 frame:OnEvent('QUEST_ITEM_UPDATE')
advance() advance() assert(talk.extraY==228 and frame.lastEvent=='QUEST_PROGRESS')
api.C_AddOns.GetAddOnMetadata=function() return 'future' end
assert(not repair:Refresh(owner,api))
api.C_AddOns.GetAddOnMetadata=function() return '1.4.61' end
db.shared.integrationPolicy.immersionProgressRepairVersion=nil
assert(not repair:Refresh(owner,api) and db.nextTransactionID==1,'restored policy was silently enabled again')
assert(C.Equal(cfgBefore,config)==false) -- Only the explicit test setting edits.
config.nameplatemode=nil assert(C.Equal(cfgBefore,config),'repair persisted native configuration')
record.appliedRevision=0
assert(not repair:Refresh(owner,api) and db.nextTransactionID==1,'unaccepted character activated repair')
record.appliedRevision=17 combat=true
assert(not repair:Refresh(owner,api) and db.nextTransactionID==1,'combat initialized repair policy')
combat=false editing=true
assert(not repair:Refresh(owner,api) and db.nextTransactionID==1,'Edit Mode initialized repair policy')
TEST_SUCCESS=true
