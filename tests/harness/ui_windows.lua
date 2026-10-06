-- Runs after the full Input/popup/quantity harness in the same restricted VM.
TEST_SUCCESS=nil
contexts.enabled=true
function Frame:EnableMouse(value) self.mouseEnabled=value end
function Frame:GetFrameStrata() return self.strata or 'MEDIUM' end
function Frame:GetPoint() return 'CENTER' end
function Frame:IsVisible() return self:IsShown() end
function Frame:IsAnchoringRestricted() return false end
function Frame:GetDebugName() return self.name or 'anonymous' end
function Frame:SetEnabled(enabled) if enabled then self:Enable() else self:Disable() end end
function Frame:SetNormalFontObject() end
local windowTimers={}
C_Timer={After=function(_,fn) windowTimers[#windowTimers+1]=fn end}
function RunNextFrame(fn) windowTimers[#windowTimers+1]=fn end
local function flushWindows()
    local count=0
    while #windowTimers>0 do count=count+1 assert(count<100,'window callback loop') table.remove(windowTimers,1)() end
end
local function unravel(t,i)
    local k=next(t,i)
    if k~=nil then return k,unravel(t,k) end
end
db.table.unravel=unravel
function db:Register(key,value) self[key]=value return value end
function db:Save() end
function db:RunSafe(fn,...) assert(not combat) return fn(...) end
C_Widget={IsFrameWidget=function(frame) return type(frame)=='table' and frame.scripts~=nil end}
CPAPI.Index=function() return Frame end
CPAPI.GetEnv=function() return {Attributes={PassThrough='native-pass-through'},FrameManagers={},FramePipelines={}},db,'ConsolePort_Cursor' end
function cursor:OnStackChanged() end
--@NATIVE_STACK
local CURSOR_ADDON_NAME='ConsolePort_Cursor'
EventUtil={ContinueOnAddOnLoaded=function(name,fn) assert(name==CURSOR_ADDON_NAME) fn() end}
--@NATIVE_CURSOR_REGISTRATION
local nativeStack=db.Stack
local paneA=CreateFrame('Frame','APane',UIParent)
local paneB=CreateFrame('Frame','BPane',UIParent)
local leafA=CreateFrame('Button','AFirst',paneA)
local leafB=CreateFrame('Button','BFirst',paneB)
paneA:Hide() paneB:Hide()
assert(nativeStack:SetFrame(paneA,true) and nativeStack:SetFrame(paneB,true))
-- Registering a child does not create an additional window candidate.
assert(nativeStack:SetFrame(leafA,true))
-- Simulate candidate.4's persisted true row and run the actual native remove
-- API. A later Show must not revive automatic gameplay-surface ownership.
local supplemental=CreateFrame('Frame','ConsolePortForeverTemporaryAccess',UIParent)
assert(nativeStack:SetFrame(supplemental,true)) flushWindows()
assert(ConsolePort:RemoveInterfaceCursorFrame(supplemental))
nativeStack:UpdateFrames() flushWindows()
supplemental:Hide() supplemental:Show() flushWindows()
assert(nativeStack.Registry.ConsolePort_Cursor.ConsolePortForeverTemporaryAccess==false)
for _,visibleFrame in ipairs({nativeStack:GetVisibleCursorFrames()}) do
    assert(visibleFrame~=supplemental,'persisted supplemental registration survived native cleanup')
end
contexts:Enable({db=db,api={version='3.3.9'}},api,true,true)
cursor:SetCurrentNode(parent)
paneA:Show() paneB:Show() flushWindows()
-- Native face rows cover all modifier variants. The bare directional route
-- remains native, while uncovered modified gameplay keys are consumed.
for _,modifier in ipairs({'','SHIFT-','CTRL-','CTRL-SHIFT-'}) do input:SetButton(modifier..'PAD1',cursor,leafA,true,'LeftButton') end
local moves=0
input:SetCommand('PADDUP',cursor,true,'LeftButton','NativeMove',function(_,down) if down then moves=moves+1 end end)
local navigation=input.Widgets.PADDUP:GetOverride(true)
local faceBefore=input.Widgets.PAD1:GetOverride(true)
cursor:SetCurrentNode(leafA)
assert(contexts.context.kind=='window' and contexts.context.frame==paneA)
assert(input.Widgets.PAD1:GetOverride(true)==faceBefore,'window paging seized a native face route')
assert(input.Widgets.PADDUP:GetOverride(true)==navigation,'native direction was replaced')
press(input.Widgets.PADDUP,true) press(input.Widgets.PADDUP,false) assert(moves==1)
assert(input.Widgets['SHIFT-PADDUP']:GetAttribute('typerelease')=='CPFConsume','modified direction leaked its gameplay binding')
-- A later native scroll claim replaces the uncovered-key consume row.
input:SetButton('SHIFT-PADDUP',cursor,leafA,true,'LeftButton')
assert(input.Widgets['SHIFT-PADDUP']:GetOverride(true).owner==cursor)
local rows=contexts.input.states
local trigger=input.Widgets.PADRTRIGGER
press(trigger,true) press(trigger,false)
assert(cursor:GetCurrentNode()==paneB,'trigger did not focus the next native registered window')
press(input.Widgets.PADLTRIGGER,true) press(input.Widgets.PADLTRIGGER,false)
assert(cursor:GetCurrentNode()==paneA)
-- A changed owner between down/up must not focus a different window.
press(trigger,true) cursor:SetCurrentNode(leafB) press(trigger,false)
assert(cursor:GetCurrentNode()==leafB,'stale trigger release changed the new owner')
-- A focused context menu suspends paging but leaves native face/dpad ownership.
local menu=CreateFrame('Frame','L_DropDownList1',UIParent)
local menuLeaf=CreateFrame('Button','L_DropDownList1Button1',menu)
assert(nativeStack:SetFrame(menu,true)) flushWindows()
cursor:SetCurrentNode(menuLeaf)
assert(contexts.context.kind=='menu')
press(trigger,true) press(trigger,false)
assert(cursor:GetCurrentNode()==menuLeaf,'context menu leaked window paging')
assert(input.Widgets.PAD1:GetOverride(true)==faceBefore)
menu:Hide() flushWindows() cursor:SetCurrentNode(leafA)
-- Pinned native TabSystemOwner/Tracker/System/Button callbacks, including the
-- actual art mixin's selected/enabled state and disabled-tab behavior.
function GenerateClosure(fn,...)
    local args={...}
    return function(...) local all={table.unpack(args)} for i=1,select('#',...) do all[#all+1]=select(i,...) end return fn(table.unpack(all)) end
end
function GetKeysArray(t) local keys={} for key in pairs(t) do keys[#keys+1]=key end return keys end
function GetOrCreateTableEntry(t,key) t[key]=t[key] or {} return t[key] end
--@NATIVE_TABS
api.TabSystemOwnerMixin=TabSystemOwnerMixin
for key,value in pairs(TabSystemOwnerMixin) do paneA[key]=value end
paneA.internalTabTracker=setmetatable({},{__index=TabSystemTrackerMixin}) paneA.internalTabTracker:Init()
local tabSystem=CreateFrame('Frame','NativeTabs',paneA)
for key,value in pairs(TabSystemMixin) do tabSystem[key]=value end
tabSystem.tabs={}
local tooltip=CreateFrame('Frame','GameTooltip',UIParent)
function tooltip:GetOwner() return self.owner end
function tooltip:IsOwned(owner) return self.owner==owner end
function GetAppropriateTooltip() return tooltip end
GameTooltip=tooltip api.GameTooltip=tooltip
tooltip:Hide()
paneA:SetTabSystem(tabSystem)
local tabCallbacks=0
for id=1,3 do
    paneA.internalTabTracker:AddTab(id)
    paneA:SetTabCallback(id,function(user) if user then tabCallbacks=tabCallbacks+1 end end)
    local button=CreateFrame('Button','NativeTab'..id,tabSystem)
    for key,value in pairs(TabSystemButtonArtMixin) do button[key]=value end
    for key,value in pairs(TabSystemButtonMixin) do button[key]=value end
    button.tabID=id button.tabSystem=tabSystem
    button.Text=CreateFrame('Frame',nil,button)
    for _,key in ipairs({'Left','Middle','Right','LeftActive','MiddleActive','RightActive'}) do button[key]=CreateFrame('Frame',nil,button) end
    button:SetScript('OnClick',button.OnClick)
    tabSystem.tabs[id]=button
end
paneA:SetTab(1,false)
cursor:SetCurrentNode(leafA)
assert(contexts.context.routes.PADRSHOULDER==tabSystem.tabs[2])
press(input.Widgets.PADRSHOULDER,true) press(input.Widgets.PADRSHOULDER,false)
assert(paneA:GetTab()==2 and tabCallbacks==1,'shoulder did not use the native tab callback exactly once')
-- Disable the proposed target while held; native enabled-state changes cancel
-- the press instead of redirecting its release to the next eligible tab.
paneA:SetTab(1,false)
press(input.Widgets.PADRSHOULDER,true)
tabSystem.tabs[2]:Disable()
press(input.Widgets.PADRSHOULDER,false)
assert(paneA:GetTab()==1 and tabCallbacks==1,'disabled target redirected a stale tab release')
press(input.Widgets.PADRSHOULDER,true) press(input.Widgets.PADRSHOULDER,false)
assert(paneA:GetTab()==3 and tabCallbacks==2,'disabled tab was not skipped')
-- Tooltip toggle dispatches the current native OnEnter route and does not
-- hide another owner's tooltip or run a face/gameplay action.
local entered=0
leafA:SetScript('OnEnter',function(self) entered=entered+1 tooltip.owner=self tooltip:Show() end)
function cursor:OnEnterNode(node) if node then fire(node,'OnEnter') end end
-- Existing callback wrappers are replaced above only in this test host; refresh
-- explicitly before entering to keep the production hooks' contract visible.
cursor:SetCurrentNode(leafA) contexts:Refresh()
press(input.Widgets.PADRSTICK,true) press(input.Widgets.PADRSTICK,false)
assert(entered==1 and tooltip:IsShown())
press(input.Widgets.PADRSTICK,true) press(input.Widgets.PADRSTICK,false)
assert(entered==1 and not tooltip:IsShown())
-- Popup and quantity continue to preempt ordinary window controls.
cursor:SetCurrentNode(target)
assert(contexts.context.kind=='popup' and contexts.context.routes.PADRTRIGGER==false)
stack:Show() cursor:SetCurrentNode(stack.LeftButton)
assert(contexts.context.kind=='quantity' and contexts.context.routes.PADLSHOULDER==false)
stack:Hide() cursor:SetCurrentNode(leafA)
assert(contexts.context.kind=='window')
keyboard:Show() assert(not contexts.context)
keyboard:Hide() assert(contexts.context.kind=='window')
-- Native radial or color-picker focus keeps its baseline input ownership.
local radial=CreateFrame('Frame','NativeRadial',UIParent)
db.Radial={Headers={[radial]=true}}
assert(contexts:Refresh() and not contexts.context)
radial:Hide() contexts:Refresh() assert(contexts.context.kind=='window')
local priorWraps=wraps contexts:Refresh() contexts:Refresh()
assert(wraps==priorWraps,'window refresh duplicated native wrappers')
press(trigger,true) combat=true contexts:Refresh() press(trigger,false)
assert(cursor:GetCurrentNode()==leafA,'combat release changed window focus')
combat=false contexts:Refresh()
leafA:Hide() assert(not contexts.context,'hidden focused leaf kept a window owner')
leafA:Show() assert(contexts.context.kind=='window')
assert(contexts:Enable({db=db,api={version='3.3.9'}},api,false))
-- The extra ability is an ordinary native binding, not a temporary bank.
-- The real Layers resolver must restore it after UI R3 ownership ends.
local extraOwner=CreateFrame('Frame','ExtraBindingOwner',UIParent)
assert(db.Layers:Claim(extraOwner,'BASE','SHIFT-PADRSTICK','binding','EXTRAACTIONBUTTON1'))
cursor:Hide()
assert(contexts:Enable({db=db,api={version='3.3.9'}},api,true,true,true))
assert(GetBindingAction('SHIFT-PADRSTICK',true)=='EXTRAACTIONBUTTON1','ordinary extra-action chord was consumed')
cursor:Show() cursor:SetCurrentNode(leafA)
assert(GetBindingAction('SHIFT-PADRSTICK',true)~='EXTRAACTIONBUTTON1','focused UI leaked extra-action gameplay')
cursor:Hide()
assert(GetBindingAction('SHIFT-PADRSTICK',true)=='EXTRAACTIONBUTTON1','closing UI did not restore extra-action chord')
assert(contexts:Enable({db=db,api={version='3.3.9'}},api,false))
assert(db.Layers:Release(extraOwner,'SHIFT-PADRSTICK'))
cursor:Show()
TEST_SUCCESS=true
