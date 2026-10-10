TEST_SUCCESS=nil
local Routing=Addon.TemporaryRouting
local nativeDragStart,nativeReceiveDrag,nativePickup
--@NATIVE_EDIT_SNIPPETS
-- Possession and quest overrides use Blizzard's own vehicle/override APIs;
-- additionally test a high native page with no family flag.
function HasVehicleActionBar() return state.family=='vehicle' or state.family=='possess' end
function HasOverrideActionBar() return state.family=='override' or state.family=='quest' end
api.HasVehicleActionBar=HasVehicleActionBar api.HasOverrideActionBar=HasOverrideActionBar
Addon.SecureModes.Install=function() error('temporary routing enabled the full suspended mode installer') end
local controls={'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN'}
local banks={'Base','L2','R2','L2R2'}
local modifiers={'','SHIFT-','CTRL-','CTRL-SHIFT-'}
local layoutBefore
api.NUM_ACTIONBAR_PAGES=6 api.NUM_OVERRIDE_BUTTONS=6 api.C_Timer={After=function(_,fn) fn() end}
api.UIParent=frame()
api.CreateFrame=function(kind,name,parent,template) assert(not combat and kind=='Frame' and template=='SecureHandlerBaseTemplate') return frame(parent) end
-- Native Frame:SetID never overwrites ConsolePort's Lua physical-button id.
function Frame:SetID(value) self.nativeID=value end
function Frame:GetID() return self.nativeID or 0 end
function Frame:Hide() self.shown=false end
local accessEnabled=0
Addon.TemporaryAccess.Probe=function() return true end
Addon.TemporaryAccess.Enable=function() accessEnabled=accessEnabled+1 end
Addon.TemporaryAccess.Disable=function() end
local callbacks={}
function bridge.bar:RegisterSafeCallback(event,fn) callbacks[event]=fn end
local legacy=frame()
legacy.props={page='override',visibility='[vehicleui][overridebar] show; hide',override='shown'}
legacy:SetAttribute('_onstate-override','native override body')
function Frame:RegisterVisibilityDriver(value) assert(not combat) self.visibleDriver=value end
function Frame:RegisterDriver(name,value,body) assert(not combat and type(body)=='string') self[name..'Driver']=value end
function bridge.bar:Map(kind,id,fn) assert(kind=='Page' and not id) fn(legacy) end
function Frame:Run(body,...) return run(self,self,'self,...',body,...) end
function manager:Run(body,...)
 Frame.Run(self,body,...)
 managerEnvironment.pager=body:find("GetFrameRef('Pager')",1,true) and self.refs.Pager or self.refs.CPFTemporaryResolvedActions
end
function Frame:ChildUpdate(name,value)
 for _,button in pairs(self.buttons or {}) do
  local body=button:GetAttribute('_childupdate-'..name)
  if body then run(self,button,'self,message',body,value) end
 end
end
local routes={}
local nativePageBody
--@NATIVE_PAGER_RESPONSE
local pager=frame()
pager.working={headers={}}
function pager:OnActionPageChanged(page) self.observedPage=page end
pager:SetAttribute('NativePage',nativePageBody)
--@NATIVE_PAGER_ACTION_HELPERS
manager:SetFrameRef('Pager',pager)
managerEnvironment.pager=pager
local nativeResponse=[[ local newstate=...; self:ChildUpdate('actionpage',newstate) ]]
for bankIndex,bank in ipairs(banks) do
 local group=api['ConsolePortGroup'..bank]
 local definition=bridge.bar.Layout.children[bank]
 definition.visibility='[vehicleui][overridebar] hide; show'
 definition.opacity='[vehicleui][overridebar] 0; [mod:M1] 100; 45'
 definition.pos={x=(bankIndex-2)*300,y=20}
 group:SetAttribute('_onstate-opacity','native fade body')
 group:SetAttribute('ActionPageChanged',nativeResponse)
 pager.working.headers[#pager.working.headers+1]=group
 for index,key in ipairs(controls) do
  local target=group.buttons[key]
  local s=modifiers[bankIndex]
  target:SetAttribute('state',s)
  routes[#routes+1]={key=s..key,target=target,bank=bank,index=index}
  engine:Register(s..key,'CPFTemporary'..#routes,function(down,button)
   local prior=trusted trusted,hardware=true,true
   if target.scripts.PreClick then target.scripts.PreClick(target,button,down) end
   target.scripts.OnClick(target,button,down,true,true)
   if target.scripts.PostClick then target.scripts.PostClick(target,button,down) end
   trusted,hardware=prior,false
  end)
 end
end
function manager:GetBindings(key)
 local index
 for i,id in ipairs(controls) do if id==key then index=i end end
 return {['']=24+index,['SHIFT-']=index,['CTRL-']=36+index,['CTRL-SHIFT-']=60+index}
end
for _,route in ipairs(routes) do
 route.target.Env.OnReceiveDrag=nativeReceiveDrag
 route.target:CreateEnvironment(route.target.Env)
 route.target:SetAttribute('OnDragStart',nativeDragStart)
 route.target:SetAttribute('PickupButton',nativePickup)
 route.target:SetBindings(manager:GetBindings(route.target.id))
end
for slot=1,180 do slots[slot]={'spell',999,'spell'} end
slots[1]={'spell',116844,'spell'}
local function page(family,bonus,pageNumber)
 state.family=family state.bonus=bonus or 0 state.page=pageNumber or 1
 local was=trusted trusted=true pager:RunAttribute('NativePage',1) trusted=was
end
-- The native pager/child handler alone reproduces the reported L2 possession.
page('skyriding',5)
assert(api.ConsolePortGroupL2.buttons.PAD1:GetAttribute('action')==121,'original native L2 dragonriding takeover not reproduced')
assert(api.ConsolePortGroupL2R2.buttons.PAD1:GetAttribute('action')==61)
page(nil)
layoutBefore=Addon.Core.Copy(bridge.bar.Layout)
assert(Routing:Refresh(bridge,api,true))
-- Native page callbacks must update fixed/custom L2R2 cells as well as IDs 1-12.
page('skyriding',5)
assert(api.ConsolePortGroupL2.buttons.PAD1:GetAttribute('action')==1,'dragonriding still possesses L2')
assert(api.ConsolePortGroupL2R2.buttons.PAD1:GetAttribute('action')==121,'dragonriding did not populate L2+R2')
local prior=trusted trusted=true
assert(pager:RunAttribute('GetSpellID',1)==999,'native double-page assist mismatch was not reproduced')
assert(managerEnvironment.pager:RunAttribute('GetSpellID',1)==116844,'ordinary assist queried dragonriding spell')
trusted=prior
assert(not Routing.resolvedActions:IsShown(),'resolved-action helper acquired visible UI')
assert(legacy.visibleDriver=='hide' and legacy.overrideDriver=='false','standalone override page still owns controller bindings')
assert(Addon.Core.Equal(layoutBefore,bridge.bar.Layout),'temporary routing modified saved layout/geometry')
local wrappers=wrapCount
assert(Routing:Refresh(bridge,api,true) and wrapCount==wrappers,'routing duplicated native wrappers')
for _,bank in ipairs(banks) do
 local group=api['ConsolePortGroup'..bank]
 assert(group.visibleDriver=='show' and group.opacityDriver=='[mod:M1] 100; 45','temporary bank visibility/fade policy not restored')
end
local classes={'DEMONHUNTER','PALADIN','DRUID','WARRIOR','DEATHKNIGHT','EVOKER','HUNTER','MAGE','MONK','PRIEST','ROGUE','SHAMAN','WARLOCK'}
local cases=0
for classIndex,class in ipairs(classes) do
 function api.UnitClass() return class,class end
 -- Character binding changes flow through native SetBindings without resetting
 -- the page policy. Give each character a distinct ordinary combo bank.
 function manager:GetBindings(key)
  local index for i,id in ipairs(controls) do if id==key then index=i end end
  return {['']=24+index,['SHIFT-']=index,['CTRL-']=36+index,['CTRL-SHIFT-']=60+index+classIndex}
 end
 assert(Routing:Refresh(bridge,api,true))
 for _,family in ipairs({'normal','skyriding','vehicle','possess','override','quest','temporary','possess-native-page','form','stealth'}) do
  local bonus=family=='skyriding' and 5 or (family=='form' or family=='stealth') and 1 or 0
  page(family,bonus,family=='possess-native-page' and 12 or nil)
  engine:Focus() engine:Combat(true) combat=true
  for _,route in ipairs(routes) do
   local special=family=='skyriding' or family=='vehicle' or family=='possess' or family=='override' or family=='quest' or family=='temporary' or family=='possess-native-page'
   local expected=route.bank=='Base' and 24+route.index or route.bank=='L2' and route.index
      or route.bank=='R2' and 36+route.index or 60+route.index+classIndex
   local empty=false
   if special and route.bank=='L2R2' then
    expected=((family=='skyriding' and 11 or 12)-1)*12+route.index
    empty=(family=='vehicle' or family=='possess' or family=='override' or family=='quest' or family=='possess-native-page') and route.index>6
   elseif (family=='form' or family=='stealth') and route.bank=='L2' then expected=72+route.index end
   assert(route.target:GetAttribute('type')==(empty and 'empty' or 'action'),'native temporary action type differs: '..class..'/'..family..'/'..route.key)
   if not empty then assert(route.target:GetAttribute('action')==expected,'wrong bank/page: '..class..'/'..family..'/'..route.key) end
   uses,casts,releases={},{},{}
   engine:Dispatch(route.key,true) engine:Dispatch(route.key,false)
   assert(#casts==0 and #uses==(empty and 0 or 1),'native temporary input dispatch failed: '..class..'/'..family..'/'..route.key)
   if not empty then assert(uses[1].slot==expected,'temporary click slot differs from display') end
   cases=cases+1
  end
  assert(not Routing:Refresh(bridge,api,true),'routing performed insecure combat setup')
  engine:Combat(false) combat=false
 end
end
assert(cases==13*10*32)
page(nil,0,2)
assert(api.ConsolePortGroupL2.buttons.PAD1:GetAttribute('action')==13,'ordinary manual page was lost')
page('possess-native-page',0,12)
assert(api.ConsolePortGroupL2.buttons.PAD1:GetAttribute('action')==13,'unflagged possession lost ordinary main page')
assert(api.ConsolePortGroupL2R2.buttons.PAD1:GetAttribute('action')==133)
page(nil)
-- The native header can still carry the quest page when a fresh ordinary
-- press runs before its page callback. It must not keep replacing L2R2.
local exiting=api.ConsolePortGroupL2R2.buttons.PAD1
api.ConsolePortGroupL2R2:SetAttribute('actionpage',12)
Addon.SecureModes.RefreshButton(exiting)
assert(exiting:GetAttribute('action')==74,'stale quest header retained temporary actions after exit')
api.ConsolePortGroupL2R2:SetAttribute('actionpage',1)
-- A native layout rebuild can reinstall its default page callback. The
-- registered callback repairs it without changing the shared saved layout.
api.ConsolePortGroupL2R2:RegisterPageResponse(nativeResponse)
function Addon:RefreshModes() assert(Routing:Refresh(bridge,api,true)) end
assert(callbacks.OnLayoutChanged and callbacks.OnNewBindings and callbacks.OnEnvLoaded)
callbacks.OnLayoutChanged()
page('skyriding',5)
assert(api.ConsolePortGroupL2R2.buttons.PAD1:GetAttribute('action')==121,'native layout rebuild regressed temporary bank')
page(nil)
-- A held native action is not retargeted by a mount/page change.
local held=api.ConsolePortGroupL2R2.buttons.PAD1
page('skyriding',5) combat=true engine:Combat(true)
uses,casts,releases={},{},{}
engine:Dispatch('CTRL-SHIFT-PAD1',true)
page(nil)
assert(held:GetAttribute('action')==121,'temporary page switched a held action')
engine:Dispatch('CTRL-SHIFT-PAD1',false)
assert(held:GetAttribute('action')==74,'ordinary character combo did not return after held release')
engine:Combat(false) combat=false
-- Class-neutral routing does not acquire foreign modal claims.
engine:ForeignClaim(true) engine:Combat(true) combat=true
assert(not pcall(engine.Dispatch,engine,'PAD1',true),'routing displaced foreign modal owner')
engine:Combat(false) combat=false engine:ForeignClaim(false)
-- The accepted ground interceptor runs on the final temporary L2+R2 action,
-- with its native click owner and page latch intact.
page('vehicle') slots[133]={'spell',207684,'spell'}
assert(Addon.GroundTargeting.Enable(bridge,api,true))
uses,casts,releases={},{},{} engine:Combat(true) combat=true
engine:Dispatch('CTRL-SHIFT-PAD1',true) engine:Dispatch('CTRL-SHIFT-PAD1',false)
assert(#casts==1 and #uses==0 and casts[1].text=='/cast [@cursor] Sigil of Misery','temporary routing broke accepted ground placement')
engine:Combat(false) combat=false
assert(Addon.GroundTargeting.Disable(api))
wrappers=wrapCount -- Ground's separate, idempotent wrappers remain installed.
assert(Routing:Disable(bridge,api)) page('skyriding',5)
assert(api.ConsolePortGroupL2.buttons.PAD1:GetAttribute('action')==121,'disable failed to restore native pager')
assert(legacy.visibleDriver==legacy.props.visibility and legacy.overrideDriver==legacy.props.override)
assert(Routing:Refresh(bridge,api,true) and wrapCount==wrappers) page('skyriding',5)
assert(api.ConsolePortGroupL2R2.buttons.PAD1:GetAttribute('action')==121)
-- The native global pager would misidentify ordinary L2 slot 1 as slot 121.
-- The assist wrapper's scoped helper must query the actual resolved slot.
slots[1]={'spell',116844,'spell'} slots[121]={'spell',999,'spell'}
local before=trusted trusted=true
assert(pager:RunAttribute('GetSpellID',1)==999,'native double-page assist mismatch was not reproduced')
assert(Routing.resolvedActions:RunAttribute('GetSpellID',1)==116844,'ordinary assist queried dragonriding spell')
trusted=before
-- Custom actions remain intact before and after the temporary page.
local custom={texture='native-custom',func=function() end}
page(nil) held:SetState('CTRL-SHIFT-','custom',custom)
page('skyriding',5) assert(held:GetAttribute('action')==121)
page(nil) assert(held._state_type=='custom' and held._state_action==custom,'ordinary custom action was lost')
-- Native drop/pickup on an action slot belongs to the current temporary page,
-- and must survive addon refresh and mount/page transitions without rewriting
-- ordinary spells. Only the modeled native drag engine edits storage here.
held:SetAttribute('LABdisableDragNDrop',nil)
for _,family in ipairs({'skyriding','vehicle','possess','override','quest','temporary','possess-native-page'}) do
 local bonus=family=='skyriding' and 5 or 0
 local nativePage=family=='possess-native-page' and 12 or 1
 page(family,bonus,nativePage)
 local expected=family=='skyriding' and 121 or 133
 local ordinary=held:GetAttribute('cpf-temp-action-CTRL-SHIFT-')
 local kind,slot=held:RunAttribute('OnReceiveDrag','spell',1,nil,424242)
 assert(kind=='action' and slot==expected,'native drop targeted ordinary storage: '..family..'/'..tostring(kind)..'/'..tostring(slot)..'/'..tostring(held:GetAttribute('type'))..'/'..tostring(held:GetAttribute('action')))
 slots[slot]={'spell',424242,'spell'}
 assert(Routing:Refresh(bridge,api,true))
 assert(slots[expected][2]==424242 and held:GetAttribute('cpf-temp-action-CTRL-SHIFT-')==ordinary,'temporary drop reverted or polluted ordinary cache: '..family)
 page(nil) page(family,bonus,nativePage)
 assert(slots[expected][2]==424242,'temporary dropped spell lost on page transition: '..family)
 kind,slot=held:RunAttribute('OnDragStart')
 assert(kind=='action' and slot==expected,'native pickup targeted ordinary storage: '..family)
 slots[slot]=nil
 assert(Routing:Refresh(bridge,api,true))
 page(nil) page(family,bonus,nativePage)
 assert(slots[expected]==nil,'temporary removed ability came back: '..family)
 if family~='skyriding' and family~='temporary' then
  local unavailable=api.ConsolePortGroupL2R2.buttons.PADDRIGHT
  unavailable:SetAttribute('LABdisableDragNDrop',nil)
  local beforeType=unavailable:GetAttribute('cpf-temp-kind-CTRL-SHIFT-')
  local beforeAction=unavailable:GetAttribute('cpf-temp-action-CTRL-SHIFT-')
  assert(unavailable:GetAttribute('type')=='empty' and unavailable:RunAttribute('OnReceiveDrag','spell',1,nil,777)==false,'unavailable temporary cell consumed a drop')
  assert(unavailable:GetAttribute('cpf-temp-kind-CTRL-SHIFT-')==beforeType and unavailable:GetAttribute('cpf-temp-action-CTRL-SHIFT-')==beforeAction,'temporary overflow drop corrupted ordinary bindings')
 end
end
-- An actual drag owns the current page even when an earlier held action kept
-- the old ordinary/custom button latched during a mount transition.
page(nil) held:SetState('CTRL-SHIFT-','custom',custom)
held.OnReceiveDragCustom=function() error('temporary drop opened ordinary binding editor') end
run(held.header,held,'self,button,down',Routing.PreClick,'LeftButton',true)
page('skyriding',5)
assert(held:GetAttribute('type')=='custom','stale ordinary drag fixture did not reproduce held custom page')
local dragKind,dragSlot=held:RunAttribute('OnReceiveDrag','spell',1,nil,424243)
assert(dragKind=='action' and dragSlot==121 and not held:GetAttribute('cpf-temp-held'),'held ordinary drop did not resolve current temporary page')
slots[dragSlot]={'spell',424243,'spell'} page(nil)
assert(held._state_type=='custom' and held._state_action==custom,'temporary drop rewrote ordinary custom binding')
held:SetState('CTRL-SHIFT-','action',74)
local originalOrdinary=Addon.Core.Copy(slots[74])
run(held.header,held,'self,button,down',Routing.PreClick,'LeftButton',true)
page('skyriding',5)
assert(held:GetAttribute('action')==74,'stale ordinary pickup fixture did not arm old action')
dragKind,dragSlot=held:RunAttribute('OnDragStart')
assert(dragKind=='action' and dragSlot==121 and not held:GetAttribute('cpf-temp-held'),'held ordinary pickup removed wrong page')
slots[dragSlot]=nil page(nil)
assert(Addon.Core.Equal(originalOrdinary,slots[74]),'temporary pickup removed ordinary action storage')
-- Direct ordinary spells are also editable: refresh must not reapply identical
-- binding declarations, and native removal must clear the companion's cache.
page(nil) held:SetState('CTRL-SHIFT-','spell',902)
assert(Routing:Refresh(bridge,api,true))
assert(held:GetAttribute('type')=='spell' and held:GetAttribute('spell')==902,'ordinary edit reset by unchanged bindings')
run(held.header,held,'self,button,down',Routing.PreClick,'LeftButton',true)
assert(held:GetAttribute('cpf-temp-held'),'native editing fixture did not arm mouse-down latch')
held:RunAttribute('OnDragStart')
assert(held:GetAttribute('type')=='empty' and not held:GetAttribute('cpf-temp-held'),'ordinary dragged-off ability came back')
assert(Routing:Refresh(bridge,api,true))
page('skyriding',5) page(nil)
assert(held:GetAttribute('type')=='empty','removed ordinary ability returned after mount/refresh')
run(held.header,held,'self,button,down',Routing.PreClick,'LeftButton',true)
held:RunAttribute('OnReceiveDrag','spell',1,nil,903)
assert(not held:GetAttribute('cpf-temp-held'),'native drop kept stale held-action latch')
assert(Routing:Refresh(bridge,api,true))
page('skyriding',5) page(nil)
assert(held:GetAttribute('type')=='spell' and held:GetAttribute('spell')==903,'ordinary replacement did not survive native page refresh')
assert(accessEnabled>0 and Addon.Core.Equal(layoutBefore,bridge.bar.Layout))
TEST_SUCCESS=true
