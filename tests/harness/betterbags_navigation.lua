-- Native Lua is executed unchanged. Frame/C APIs, rendering, vectors and the
-- secure wrapper boundary are models; this is not engine/taint/hardware proof.
local combat, gamepad, tooltip, queue = false, true, nil, {}
local heldItem=false
local startupCombat = false
local secureMode = true -- models the public native wrapper boundary, not WoW taint
local A, BB, modules = {}, {Bags={}}, {}
unpack=table.unpack
function wipe(t) for k in pairs(t)do t[k]=nil end return t end
table.wipe=wipe
function tIndexOf(t,v)for k,x in ipairs(t)do if x==v then return k end end end
function tContains(t,v)return tIndexOf(t,v)~=nil end
table.contains=tContains
function issecure()return secureMode end
function issecretvalue()return false end
function InCombatLockdown()return combat end
function InGlue()return false end
function securecallfunction(f,...)return f(...)end
function GetCursorInfo()end
function ClearCursor()heldItem=false end
function SpellCanTargetItem()return false end
function SetGamePadCursorControl()end
function GetScaledCenter(f)return f:GetCenter()end
function SetClampedTextureRotation()end
function GenerateClosure(fn,...)
    local args={...};return function(...)local all={table.unpack(args)};for _,v in ipairs({...})do all[#all+1]=v end;return fn(table.unpack(all))end
end
local vector={}
function vector:GetLength()return math.sqrt(self.x*self.x+self.y*self.y)end
function vector:Normalize()local n=self:GetLength();if n>0 then self.x,self.y=self.x/n,self.y/n end;return self end
function vector:Add(v)return CreateVector2D(self.x+v.x,self.y+v.y)end
function vector:IsEqualTo(v)return self.x==v.x and self.y==v.y end
function CreateVector2D(x,y)return setmetatable({x=x,y=y},{__index=vector})end
function Vector2D_CalculateAngleBetween(x,y,a,b)return math.acos(math.max(-1,math.min(1,(x*a+y*b)/math.sqrt((x*x+y*y)*(a*a+b*b)))))end
function Clamp(v,low,high)return math.max(low,math.min(high,v))end
math.clamp=Clamp
function CreateFromMixins(...)local t={};for _,m in ipairs({...})do for k,v in pairs(m)do t[k]=v end end;return t end
CallbackRegistryMixin={GenerateCallbackEvents=function()end}
function CallbackRegistryMixin:RegisterCallback(k,fn,who)self.callbacks=self.callbacks or {};self.callbacks[k]=self.callbacks[k]or {};self.callbacks[k][who]=fn end
function CallbackRegistryMixin:UnregisterCallback(k,who)if self.callbacks and self.callbacks[k]then self.callbacks[k][who]=nil end end
function CallbackRegistryMixin:TriggerEvent(k,...)local c={};for who,fn in pairs(self.callbacks and self.callbacks[k]or {})do c[who]=fn end;for who,fn in pairs(c)do fn(who,...)end end
C_RestrictedActions={IsAddOnRestrictionActive=function()return combat end}
Enum={AddOnRestrictionType={Combat=1}}
EventRegistry=CreateFromMixins(CallbackRegistryMixin)
GAMEPAD_DPAD_RIGHT='right';GAMEPAD_DPAD_LEFT='left';GAMEPAD_DPAD_TOP='up';GAMEPAD_DPAD_BOTTOM='down'
GAMEPAD_FACE_BOTTOM='accept';GAMEPAD_FACE_RIGHT='circle';GAMEPAD_STICK_RIGHT='scroll'
GAMEPAD_FACE_LEFT='square';GAMEPAD_FACE_TOP='triangle'
for _,name in ipairs({'GAMEPAD_DPAD_HORIZONTAL','GAMEPAD_DPAD_VERTICAL','GAMEPAD_DPAD','GAMEPAD_MENU_LEFT','GAMEPAD_MENU_RIGHT','GAMEPAD_SHOULDER_LEFT','GAMEPAD_SHOULDER_RIGHT','GAMEPAD_STICK_LEFT','GAMEPAD_STICK_LEFT_PRESS','GAMEPAD_STICK_RIGHT_VERTICAL','GAMEPAD_STICK_RIGHT_HORIZONTAL','GAMEPAD_STICK_RIGHT_PRESS','GAMEPAD_TRIGGER_LEFT','GAMEPAD_TRIGGER_RIGHT','GAMEPAD_BUTTON_ANY_DOWN','GAMEPAD_BUTTON_ANY_UP','GAMEPAD_BUTTON_ANY_DOWN_OR_UP'})do _G[name]=name end
GenerateFlatClosure=GenerateClosure
InputUtil={IsGamepadUIEnabled=function()return gamepad end}
local gamepadInit,gamepadUninit
function InputUtil.RegisterGamepadInit(_,fn)gamepadInit=fn end
function InputUtil.RegisterGamepadUninit(_,fn)gamepadUninit=fn end
local forbidAddonCollections = true -- observed blocked panel-list route; not a general engine taint model
local secureHelper={CoerceToBoolean=function(v)return not not v end,ToOptionalString=tostring}
function secureHelper:WrapFunction(fn)
    return function(...)
        local previous=secureMode
        if forbidAddonCollections and not previous then
            for i=1,select('#',...) do
                local value=select(i,...)
                assert(type(value)~='table' or value.GetName or value==GamepadMode.FrameControlsManager,
                    'addon panel collection crossed native boundary')
            end
        end
        secureMode=true
        local values={pcall(fn,...)};secureMode=previous
        if not values[1]then error(values[2])end
        return table.unpack(values,2)
    end
end
function secureHelper:RegisterKey()end
function secureHelper:SetSecureValue(o,k,v)o[k]=v end
function secureHelper.SecureCallOptionalFunction(o,k,...)if o[k]then return true,o[k](...)end;return false end
local utility
function import(name)if name:find('SecureHelper')then return secureHelper end;return utility end
local function frame(name,kind,parent,x,y)
    local f={name=name,kind=kind or 'Frame',parent=parent,children={},scripts={},shown=true,x=x or 100,y=y or 100,w=32,h=32}
    if parent then parent.children[#parent.children+1]=f end
    function f:GetName()return self.name end
    function f:GetParent()return self.parent end
    function f:GetChildren()return table.unpack(self.children)end
    function f:IsObjectType(k)return self.kind==k or k=='Frame' end
    function f:GetScript(k)return self.scripts[k]end
    function f:HookScript(k,fn)local prior=self.scripts[k];self.scripts[k]=function(...)if prior then prior(...)end;fn(...)end end
    function f:SetScript(k,fn)self.scripts[k]=fn end
    function f:IsShown()return self.shown end
    function f:IsVisible()return self.shown and (not self.parent or self.parent:IsVisible())end
    function f:Show()local old=self.shown;self.shown=true;if not old and self.scripts.OnShow then self.scripts.OnShow(self)end end
    function f:Hide()local old=self.shown;self.shown=false;if old and self.scripts.OnHide then self.scripts.OnHide(self)end end
    function f:GetSize()return self.w,self.h end
    function f:IsRectValid()return true end
    function f:GetRect()return self.x,self.y,self.w,self.h end
    f.GetScaledRect=f.GetRect
    function f:GetCenter()return self.x+self.w/2,self.y+self.h/2 end
    function f:GetLeft()return self.x end
    function f:GetBottom()return self.y end
    function f:GetTop()return self.y+self.h end
    function f:GetRight()return self.x+self.w end
    function f:SetHighlightLocked(v)self.highlight=v end
    function f:FocusEnter()tooltip=self.name end
    function f:FocusExit()tooltip=nil end
    function f:MouseDown(b)self.down=b or 'LeftButton' end
    function f:MouseUp(b)self.click=b or 'LeftButton' end
    function f:IsEnabled()return self.enabled~=false end
    function f:SetAlpha(v)self.alpha=v end
    function f:GetAlpha()return self.alpha or 1 end
    function f:ClearAllPoints()end
    function f:SetPoint()end
    return f
end
UIParent=frame('UIParent')
GamepadMode={};GamepadSharedUtility={}
local groups={}
function GamepadMode.CreateBindingGroup()
    local b={handlers={}}
    function b:AddFunctionBinding(k,fn)self.handlers[k]=fn end
    b.AddAxisBinding=b.AddFunctionBinding
    groups[#groups+1]=b
    return b
end
function GamepadMode.ActivateBindingGroup(b)assert(secureMode,'addon attempted direct input stack write');if b then b.active=true end end
function GamepadMode.DeactivateBindingGroup(b)assert(secureMode,'addon attempted direct input stack write');if b then b.active=false end end
function GamepadMode.UncacheBindingGroup()end
function CreateAndInitFromMixin(m,...)local o=CreateFromMixins(m);if m==PromptedBindingMixin or m==PromptedBindingFooterMixin then o:Init(...)else o:ResetVars()end;return o end
InputPromptLegends={PromptTemplates={StandardOneIcon={name='One'},StandardTwoIcon={name='Two'}}}
function InputPromptLegends.CreateInputLegend(parent,name)
    local f=frame(name,nil,parent)
    function f:SetParent(p)self.parent=p end
    function f:GetOrCreatePromptFrameUsingTemplateAndInputs()end
    function f:RefreshWithPromptedBindings()end
    return f
end
function CursorHasItem()return heldItem end
function InRepairMode()return false end
function SpellIsTargeting()return false end
function CanSellItems()return false end
function UnitClassBase()return 'MAGE' end
MerchantFrame=frame('Merchant');MerchantFrame.shown=false
Item={CreateFromBagAndSlot=function()return {GetItemID=function()return 1 end,GetItemLink=function()return 'item:1'end}end}
C_Item={IsUsableItem=function()return true end,IsEquippableItem=function()return false end}
C_Container={GetContainerItemInfo=function()return {hasLoot=false,stackCount=1}end}
--@NAV_UTILITY
--@NAV_SMART
SmartNavigation=CreateFromMixins(frame('SmartNavigation'),SmartNavigationMixin)
SmartNavigation:ResetVars();SmartNavigation:InitializeGamepad();SmartNavigation:SetupInputBindings()
SmartNavigation.xRes,SmartNavigation.yRes=1920,1080
SmartNavigation.maxScrollSpeed=100;SmartNavigation.startDelay=0;SmartNavigation.repeatStart=.4;SmartNavigation.repeatDelay=.2
SmartNavigation.Pointer={IntroAnim={IsPaused=function()return false end,Restart=function()end,Pause=function()end},Icon={Cursor={}}}
SmartNavigation.scripts.OnHide=SmartNavigation.OnHide
--@NAV_PROMPTS
-- Art updates are leaf rendering boundaries; selection/focus/click code stays native.
function SmartNavigation:UpdateCursorPosition()end
GamepadScrollBarHint={Hide=function()end}
--@NAV_MANAGER
local manager=GamepadMode.FrameControlsManager
local itemMenu
MenuUtil={CreateContextMenu=function(owner,build)
    local menu=frame('NativeItemMenu',nil,UIParent)
    function menu:GetOwnerRegion()return owner end
    function menu:SetClosedCallback(fn)self.closed=fn end
    function menu:Close()manager:FrameHidden(self);self:Hide();if self.closed then self.closed()end end
    local root={SetTag=function()end,CreateButton=function()end}
    build(owner,root)
    manager:FrameShown(menu,true)
    itemMenu=menu
    return menu
end}
manager.gamepadBindings=GamepadMode.CreateBindingGroup()
manager.gamepadFallthroughCatcherBindings=GamepadMode.CreateBindingGroup()
function manager:RefreshGamepadCursorHovering()end
function manager:RefreshJumpHints()end
local registrations=0
local nativeShown=manager.FrameShown
function manager:FrameShown(...)registrations=registrations+1;return nativeShown(self,...)end
local refreshes=0
local nativeRefreshGroups=SmartNavigation.RefreshButtonGroups
function SmartNavigation:RefreshButtonGroups(...)refreshes=refreshes+1;return nativeRefreshGroups(self,...)end
local hidden=frame('hidden',nil,UIParent);hidden.shown=false
ContainerFrameCombinedBags=frame('BlizzardCombined',nil,hidden)
ContainerFrameSettingsManager={IsUsingCombinedBags=function()return true end}
Enum.BagIndex={Backpack=0}
function ContainerFrame_AllowedToOpenBags()return true end
function IsAnyStandardHeldBagOpen()return ContainerFrameCombinedBags:IsShown()end
function OpenBag()ContainerFrameCombinedBags:Show()end
--@NAV_NATIVE_BAGS
ContainerFrameCombinedBagsMixin={}
--@NAV_CONTAINER_PROMPTS
--@NAV_NATIVE_FOCUS
ContainerFrameCombinedBags.FocusGamepad=ContainerFrameCombinedBagsMixin.FocusGamepad
ContainerFrameCombinedBags.UnfocusGamepad=ContainerFrameCombinedBagsMixin.UnfocusGamepad
ContainerFrameCombinedBags.SmartNavigationCloseHandler=ToggleBackpack_Combined
ContainerFrameCombinedBags.SetUpSearchGamepad=function()end -- unrelated hidden stock search is excluded
GamepadBackpackButton=frame('GamepadBackpackButton','Button',UIParent,50,50)
GamepadBagBar={GetBagButton=function()return GamepadBackpackButton end}
ContainerFrameCombinedBags.PortraitButton=frame('StockPortrait','Button',ContainerFrameCombinedBags)
ContainerFrameCombinedBags.SmartNavPanelInfoAdded=ContainerFrameCombinedBagsMixin.SmartNavPanelInfoAdded
ContainerFrameCombinedBags.SearchBoxIcon=frame('StockSearchIcon')
ContainerFrameCombinedBagsMixin.SetupGamepad(ContainerFrameCombinedBags)
local function newBag(name)
    local window=frame(name,nil,UIParent)
    local scroll=frame(name..'Scroll','ScrollFrame',window,100,200);scroll.w,scroll.h=200,220
    function scroll:GetVerticalScroll()return self.scroll or 0 end
    function scroll:GetVerticalScrollRange()return 100 end
    function scroll:SetVerticalScroll(v)self.scroll=v end
    local item=frame(name..'Item','Button',scroll,110,320)
    local second=frame(name..'Second','Button',scroll,155,320)
    for _,button in ipairs({item,second})do
        button.buttonContext='ButtonContext_ContainerFrameItemButton';button.hasItem=true
        function button:GetBagID()return 0 end
        function button:GetID()return 1 end
        function button:IsReadable()return false end
    end
    local decoration=frame(name..'Decoration','Button',scroll,110,320)
    local holder={button=item,frame=scroll,_decoration=decoration}
    local bag={frame=window,item=item,second=second,decoration=decoration,holder=holder,scroll=scroll,scrollBox=scroll}
    function bag:Hide(ctx)assert(ctx,'native context missing');self.frame:Hide()end
    return bag
end
local backpack=newBag('BetterBackpack');BB.Bags.Backpack=backpack
modules.ItemFrame={activeItems={[backpack.holder]=true}}
modules.Context={New=function()return {}end}
local messages={}
modules.Events={RegisterMessage=function(_,name,fn)messages[name]=fn end}
function BB:GetModule(name)return modules[name]end
local enabled=true
function BB:IsEnabled()return enabled end
function BB:WatchBackpackFrame()end
function hooksecurefunc(o,k,fn)
    local before=o[k]
    o[k]=function(...)
        local r={before(...)};local previous=secureMode;secureMode=false
        local ok,err=pcall(fn,...);secureMode=previous;if not ok then error(err)end
        return table.unpack(r)
    end
end
C_Timer={After=function(_,fn)queue[#queue+1]=function()
    local previous=secureMode;secureMode=false;local ok,err=pcall(fn);secureMode=previous;if not ok then error(err)end
end end}
local function flush()for _=1,5 do local pending=queue;queue={};for _,fn in ipairs(pending)do fn()end end end
WOW_PROJECT_CAMELOT=18;WOW_PROJECT_ID=18
LibStub=function()return {GetAddon=function(_,n)if n=='BetterBags'then return BB end end}end
-- Native dispatch tracks the hidden stock container; the visible addon is absent.
manager:FrameShown(ContainerFrameCombinedBags)
assert(SmartNavigation:GetActiveFrame()==ContainerFrameCombinedBags and SmartNavigation.currentButton==GamepadBackpackButton,'old hidden owner did not reproduce')
--@NAV_PRODUCT
if startupCombat then combat=true end
A:InstallBagNavigation()
if startupCombat then assert(not A.navigation,'startup in combat installed navigation');combat=false end
A:InstallBagNavigation();flush()
assert(SmartNavigation:GetActiveFrame()==backpack.frame and manager.focusedFrame==ContainerFrameCombinedBags,'visible panel/native controller split missing')
assert(not tContains(manager.shownFrames,backpack.frame),'addon window replaced native controller')
assert(SmartNavigation.currentButton==backpack.item and tooltip==backpack.item.name,'real item/tooltip focus failed')
assert(not SmartNavigation:IsButtonValid(backpack.decoration),'decorative duplicate remained navigable')
assert(A:GetBagNavigationStatus().focused and A:GetBagNavigationStatus().window==backpack.frame.name,'navigation diagnostic missed actual focus')
local record=A.navigation.frames[backpack.frame]
local footer=ContainerFrameCombinedBags.gamepadFooter
assert(footer.isShown,'native item action footer missing')
assert(ContainerFrameCombinedBags.gamepadFooter.parentFrame==ContainerFrameCombinedBags,'native footer was reparented')
local inputs=SmartNavigation.navigationBindings.handlers
inputs.right(true);inputs.right(false)
assert(SmartNavigation.currentButton==backpack.second,'native direction did not select next item')
inputs.accept();assert(backpack.second.click=='LeftButton','native accept did not click real item')
backpack.second.click=nil
footer.bindings.handlers.square(true)
assert(backpack.second.click=='RightButton','native Square item action failed')
assert(footer.bindings.handlers.triangle,'native item menu binding missing')
footer.bindings.handlers.triangle(true)
assert(itemMenu and SmartNavigation:GetActiveFrame()==itemMenu and not footer.isShown,'native Triangle item menu did not take focus')
messages['bags/Draw/Backpack/Done']();flush()
assert(SmartNavigation:GetActiveFrame()==itemMenu,'bag draw stole another window focus')
itemMenu:Close()
assert(SmartNavigation:GetActiveFrame()==backpack.frame and manager.focusedFrame==ContainerFrameCombinedBags and footer.isShown,'item menu did not return native bag focus')
inputs.left(true);inputs.left(false)
assert(SmartNavigation.currentButton==backpack.item,'native menu return lost navigation groups')
inputs.right(true);inputs.right(false);flush()
assert(SmartNavigation.currentButton==backpack.second,'native menu return lost navigation groups')
assert(SmartNavigation.rightStickScrollBindings.active,'native scrolling binding missing')
SmartNavigation.rightStickScrollBindings.handlers.scroll(0,-1);SmartNavigation:OnUpdate(.1)
assert(backpack.scroll:GetVerticalScroll()>0,'native right stick did not scroll')
SmartNavigation.rightStickScrollBindings.handlers.scroll(0,0)
SmartNavigation:SelectButton(backpack.second)
local start=registrations
for _=1,100 do messages['bags/Draw/Backpack/Done']()end
assert(#queue==1,'draw burst was not coalesced');flush()
assert(registrations==start and SmartNavigation.currentButton==backpack.second,'redraw stole/rebuilt focus')
heldItem=true;footer.bindings.handlers.circle(true);flush()
assert(not heldItem and backpack.frame:IsShown(),'native back did not return held item first')
footer.bindings.handlers.circle(true);flush()
assert(not backpack.frame:IsShown() and #manager.shownFrames==0 and not SmartNavigation.bindingActive,'Circle did not release native owner')
assert(not ContainerFrameCombinedBags:IsShown(),'Circle retained native bag-open bookkeeping')
backpack.frame:Show();flush();assert(SmartNavigation:GetActiveFrame()==backpack.frame,'reopen did not focus bag')
local other=frame('OtherWindow',nil,UIParent);manager:FrameShown(other)
assert(not footer.isShown,'native item actions retained focus over another window')
messages['bags/Draw/Backpack/Done']();flush()
assert(SmartNavigation:GetActiveFrame()==other,'bag draw stole another window focus')
manager:FrameHidden(other);other:Hide()
local bank=newBag('BetterBank');bank.frame:Hide();BB.Bags.Bank=bank
BankFrame=frame('StockBank',nil,hidden)
BankFrame.SmartNavigationCloseHandler=function(self)self:Hide();return true end
messages['item/Updated'](nil,bank.holder,bank.decoration)
A:InstallBagNavigation();flush();bank.frame:Show();flush()
assert(SmartNavigation:GetActiveFrame()==bank.frame and manager.focusedFrame==BankFrame,'bank window not registered')
inputs.circle();flush();assert(not bank.frame:IsShown() and backpack.frame:IsShown(),'Circle closed wrong bag bank='..tostring(bank.frame:IsShown())..' backpack='..tostring(backpack.frame:IsShown())..' active='..tostring(SmartNavigation:GetActiveFrame() and SmartNavigation:GetActiveFrame():GetName()))
-- Combat writes, startup in combat and stale queued work are refused.
backpack.frame:Hide();flush();assert(not ContainerFrameCombinedBags:IsShown(),'manual close retained native bag-open bookkeeping')
combat=true;backpack.frame:Show();start=registrations;flush()
assert(registrations==start,'combat registration attempted')
combat=false;A:InstallBagNavigation();flush();assert(SmartNavigation:GetActiveFrame()==backpack.frame,'combat recovery failed')
local replacement=newBag('Replacement');backpack.frame:Hide();BB.Bags.Backpack=replacement
BB:WatchBackpackFrame(replacement.frame);flush()
assert(SmartNavigation:GetActiveFrame()==replacement.frame and A:GetBagNavigationStatus().window==replacement.frame.name,'design change retained old focus')
local reused={frame=replacement.frame}
function reused:Hide(ctx)assert(ctx);self.closed=true;self.frame:Hide()end
BB.Bags.Backpack=reused;A:QueueBagNavigation();flush();footer.bindings.handlers.circle(true);flush()
assert(reused.closed,'reused window closed stale bag owner')
BB.Bags.Backpack=replacement;replacement.frame:Show();A:QueueBagNavigation();flush()
replacement.frame.parent=hidden;A:QueueBagNavigation();flush()
assert(replacement.frame:IsShown() and not tContains(manager.shownFrames,ContainerFrameCombinedBags),'hidden ancestor retained navigation')
replacement.frame.parent=UIParent;A:QueueBagNavigation();flush()
enabled=false;A:QueueBagNavigation();flush();assert(not tContains(manager.shownFrames,ContainerFrameCombinedBags),'disabled addon retained navigation')
enabled=true;A:InstallBagNavigation();flush()
local nativeRefresh=SmartNavigation.RefreshButtonGroups
SmartNavigation.RefreshButtonGroups=nil;A:QueueBagNavigation();start=registrations;flush()
assert(registrations==start and A.navigation.reason=='native navigation not ready','missing native readiness still registered')
SmartNavigation.RefreshButtonGroups=nativeRefresh;A:InstallBagNavigation();flush()
local foreign=function()return true end
replacement.frame.SmartNavigationCloseHandler=foreign;A:InstallBagNavigation();flush()
assert(replacement.frame.SmartNavigationCloseHandler==foreign,'foreign close handler overwritten')
gamepad=false;ContainerFrameCombinedBags:UnfocusGamepad();A:QueueBagNavigation();start=registrations;flush();assert(registrations==start,'mouse interface registered navigation')
manager:ResetVars();SmartNavigation:ResetVars();SmartNavigation.enabled=true
gamepad=true;gamepadInit();flush();assert(SmartNavigation:GetActiveFrame()==replacement.frame,'gamepad transition lost window')
A:QueueBagNavigation();A:StopBagNavigation();start=registrations;local lastRefresh=refreshes;flush();gamepadInit();flush()
assert(registrations==start and refreshes==lastRefresh,'logout work resurrected navigation')
local visibleBefore=replacement.frame:IsShown();local close=replacement.frame.SmartNavigationCloseHandler
if close~=foreign then close() end
assert(replacement.frame:IsShown()==visibleBefore,'logout close handler wrote a frame')
TEST_SUCCESS=true
