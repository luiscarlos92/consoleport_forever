-- Executes installed ConsolePort library/ProxyButton, staged Group factories,
-- actual LAB update function, staged helper, and untouched Immersion talk-box code.
unpack = table.unpack or unpack
local ROOT = 'C:/Program Files (x86)/World of Warcraft/_retail_/'
local WORK = 'ConsolePort-Refinements-2026-09-27/'
local STAGE = arg[1] or WORK..'staged/'
local function check(v,msg) assert(v,msg) end
local function eq(a,b,msg) assert(a==b,(msg or '')..' expected '..tostring(b)..', got '..tostring(a)) end
nop = function() end
local bindingActions={PAD1='JUMP',PAD2='',PAD3='INTERACTTARGET',PAD4='TURNORACTION'}
GetBindingAction=function(id)return bindingActions[id] or '' end
local targetExists=false
UnitExists=function()return targetExists end
C_Spell={GetSpellTexture=function(id)eq(id,6603);return 132223 end}
function Mixin(obj,...) for i=1,select('#',...) do for k,v in pairs(select(i,...)) do obj[k]=v end end return obj end
function CreateFromMixins(...) return Mixin({},...) end
function wipe(t) for k in pairs(t) do t[k]=nil end end
function GenerateClosure(f,...) local a={...};return function(...) return f(unpack(a)) end end
local Methods={}
local function object(parent)
 return setmetatable({parent=parent, width=45,height=45,scale=1,shown=true,points={},scripts={},attrs={},masks={},strata='MEDIUM'}, {__index=Methods})
end
function Methods:SetTexture(t) self.texture=t;self.atlas=nil end
function Methods:GetTexture() return self.texture end
function Methods:SetAtlas(t) self.atlas=t;self.texture=nil end
function Methods:SetColorTexture(...) self.texture={...};self.atlas=nil end
function Methods:SetTexCoord(...) self.texcoord={...} end
function Methods:ClearAllPoints() self.points={} end
function Methods:SetPoint(...) self.points={...} end
function Methods:GetPoint() return unpack(self.points) end
function Methods:SetAllPoints(o) self.allpoints=o or self.parent end
function Methods:SetSize(w,h) self.width=w;self.height=h end
function Methods:GetSize() return self.width,self.height end
function Methods:SetWidth(w) self.width=w end
function Methods:SetHeight(h) self.height=h end
function Methods:GetWidth() return self.width end
function Methods:GetHeight() return self.height end
function Methods:SetScale(s) self.scale=s end
function Methods:GetScale() return self.scale end
function Methods:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function Methods:GetFrameStrata() return self.strata end
function Methods:SetFrameStrata(s) self.strata=s end
function Methods:GetParent() return self.parent end
function Methods:SetParent(p) self.parent=p end
function Methods:GetName() return self.name end
function Methods:SetAlpha(a) self.alpha=a end
function Methods:SetShown(v) self.shown=v end
function Methods:Show() self.shown=true end
function Methods:Hide() self.shown=false end
function Methods:IsShown() return self.shown end
function Methods:IsVisible() return self.shown end
function Methods:AddMaskTexture(m) self.masks[m]=true end
function Methods:RemoveMaskTexture(m) self.masks[m]=nil end
function Methods:SetDrawLayer(...) self.layer={...} end
function Methods:SetVertexColor(...) self.color={...} end
function Methods:SetDesaturated(v) self.desaturated=v end
function Methods:SetSwipeTexture(v) self.swipe=v end
function Methods:SetUseCircularEdge(v) self.circular=v end
function Methods:SetText(v) self.text=v end
function Methods:GetText() return self.text or '' end
function Methods:SetAttribute(k,v) self.attrs[k]=v end
function Methods:GetAttribute(k) return self.attrs[k] end
function Methods:RegisterEvent(e) self.events=self.events or {};self.events[e]=true end
function Methods:SetScript(e,f) self.scripts[e]=f end
function Methods:GetScript(e) return self.scripts[e] end
function Methods:HookScript(e,f) local old=self.scripts[e];self.scripts[e]=function(...)if old then old(...) end;f(...)end end
function Methods:SetIgnoreParentAlpha(v) self.ignoreParentAlpha=v end
function Methods:CreateTexture(_,layer)
 local t=object(self);t.drawLayer=layer;self.textures=self.textures or {};self.textures[#self.textures+1]=t;return t
end
function Methods:EnableMouse(v) self.mouse=v end
function Methods:CreateMaskTexture() return object(self) end
function Methods:SetChecked(v) self.checked=v end
function Methods:GetPushedTexture() return self.PushedTexture end
function Methods:GetHighlightTexture() return self.HighlightTexture end
function Methods:GetCheckedTexture() return self.CheckedTexture end
function Methods:HasAction() return self.testTexture~=nil end
function Methods:IsEquipped() return false end
function Methods:IsConsumableOrStackable() return false end
function Methods:GetActionText() return '' end
local made={}
function CreateFrame(_,name,parent) local o=object(parent);o.name=name;made[#made+1]=o;return o end
function CreateFramePool() return {} end
function hooksecurefunc(a,b,c)
 local t,k,f
 if type(a)=='string' then t,k,f=_G,a,b else t,k,f=a,b,c end
 local old=assert(t[k],k)
 t[k]=function(...) local out={old(...)};f(...);return unpack(out) end
end
local lib,lab,lbg={},{},{ShowOverlayGlow=nop,HideOverlayGlow=nop}
LibStub=setmetatable({NewLibrary=function()return lib end},{__call=function(_,name)if name=='LibActionButton-1.0' then return lab elseif name=='LibButtonGlow-1.0' then return lbg end end})
local db={Gamepad={Index={Modifier={Owner={}}}}, UIHandle={GetUIControlBinding=function(_,id)return id end}}
function db:RegisterCallback() end
function db.Gamepad.SetIconToTexture(h,id) h.icon:SetTexture(id) end
local env={LIB=lib,LAB=lab,factories={},Attributes={Update=function(s)return s end},Manager={RegisterReroute=nop,GetBindings=function()return nil end},ConfigurableWidgetMixin={SetDynamicProps=function(self,p)self.props=p end},MovableWidgetMixin={},Interface={}}
env.MakeID=string.format
env.Attributes.GUID='test-guid'
setmetatable(env,{__call=function(_,key)return 12 end})
function env:RegisterCallback() end
function env:RegisterCallbacks() end
function env:AddFactory(k,f) self.factories[k]=f end
function env:Map() end
local cached={}
function env:Acquire(k,id,...) if not cached[id] then cached[id]=self.factories[k](id,...) end return cached[id] end
CPAPI={IsRetailVersion=true, SecureEnvironmentMixin={CreateEnvironment=nop},GetEnv=function()return env,db end,SkipHotkeyRender='skip',Debounce=function(f)return f end,Index=function()return Methods end}
function CPAPI.CreateFlagClosures(t) local out={};for k,v in pairs(t)do out[k]=function(old,on)old=old or 0;local has=math.floor(old/v)%2==1;return old+(on and not has and v or not on and has and -v or 0)end end return out end
NUM_ACTIONBAR_BUTTONS=12
CPActionBar={OnLoad=nop,OnRelease=nop}
YELLOW_FONT_COLOR={WrapTextInColorCode=function(_,v)return v end}
assert(loadfile(ROOT..'Interface/AddOns/ConsolePort/Libs/Local/ActionButton.lua'))()
assert(loadfile(ROOT..'Interface/AddOns/ConsolePort_Bar/Widget/Button/Button.lua'))('ConsolePort_Bar',env)
env.Button.GetConfig=function()return {hideElements={border=false,borderIfEmpty=false,equipped=false},text={hotkey={color={1,1,1}}},showGrid=true} end
local roundShow,roundHide=lib.RoundGlow.ShowOverlayGlow,lib.RoundGlow.HideOverlayGlow
function lab:CreateButton(id,name,parent,config)
 local b=CreateFrame('CheckButton',name,parent);b.id=id;b.config=config
 for _,k in ipairs({'icon','IconMask','NormalTexture','SlotBackground','SlotArt','PushedTexture','HighlightTexture','CheckedTexture','Flash','Border','BorderShadow','NewActionTexture','SpellHighlightTexture','cooldown','chargeCooldown','lossOfControlCooldown','Name','HotKey'}) do b[k]=object(b);b[k].atlas='square-'..k end
 b.icon:AddMaskTexture(b.IconMask)
 b.GetTexture=function(self)return self.testTexture end
 b.UpdateButtonArt=function(self) for _,k in ipairs({'NormalTexture','SlotArt','SlotBackground'})do self[k]:SetAtlas('square-'..k)end end
 b.SetNormalAtlas=function(self,v)self.NormalTexture:SetAtlas(v)end
 b.AddToMasque=function(self,g)g:AddButton(self);self.MasqueSkinned=true end
 return b
end
assert(loadfile(STAGE..'Interface/AddOns/ConsolePort_Bar/Widget/Group/Group.lua'))('ConsolePort_Bar',env)
local names={'PAD1','PAD2','PAD3','PAD4','PADDUP','PADDDOWN','PADDLEFT','PADDRIGHT'}
local function masque() return {added={},AddButton=function(self,b)check(not b.isForeverFaceButton,'Masque acquired a Forever face');self.added[#self.added+1]=b;b.NormalTexture:SetAtlas('masque-square')end} end
local msq={Group=function()return masque()end}
local count=0
for _,early in ipairs({true,false})do
 cached={}
 for _,bank in ipairs({'Base','L2','R2','L2R2'}) do
  local p=Mixin(object(),CPGroupBar);p.name='ConsolePortGroup'..bank;p.id=bank;p.buttons={};p.modifiers={};p.OnRelease=nop
  if early then p:OnMasqueLoaded(msq) end
  local props={};for _,id in ipairs(names)do props[id]={pos={point='LEFT',relPoint='LEFT',x=60,y=45}}end
  p:UpdateButtons(props)
  if not early then p:OnMasqueLoaded(msq)end
  eq(#p.msqGroup.added,4,'Masque D-pad count')
  p:UpdateButtons(props);eq(#p.msqGroup.added,8,'Masque rebuild D-pad count')
  for i,id in ipairs(names)do
   local b=p.buttons[id];eq(b.Hotkey.icon.texture,id,'hotkey preserved');eq(b.width,45,'button width preserved')
   eq(b.points[4],60,'button x preserved');eq(b.points[5],45,'button y preserved')
   if i<=4 then
    count=count+1;check(b.isForeverFaceButton and b.MasqueSkinned,'face factory tag/skin suppression');eq(b.ShowOverlayGlow,roundShow);eq(b.HideOverlayGlow,roundHide)
    b:UpdateButtonArt();b:UpdateLocal()
    for _,k in ipairs({'NormalTexture','PushedTexture','HighlightTexture','CheckedTexture','Flash','Border','NewActionTexture','SpellHighlightTexture'})do check(b[k].texture:find('RoundBorderHighlight',1,true),bank..id..k);eq(b[k].atlas,nil)end
    check(b.IconMask.texture:find('CircleMaskScalable',1,true),'mask circular');check(b.icon.masks[b.IconMask] and b.SlotBackground.masks[b.IconMask],'populated + empty masks')
    eq(b.SlotArt.texture,nil);eq(b.SlotArt.shown,false);eq(b.BorderShadow.texture,nil)
    for _,k in ipairs({'cooldown','chargeCooldown','lossOfControlCooldown'})do check(b[k].circular,k);eq(b[k].allpoints,b.IconMask);eq(b[k].swipe,b.IconMask.texture)end
   else
    check(not b.isForeverFaceButton,'D-pad excluded');eq(b.NormalTexture.atlas,'masque-square');eq(b.IconMask.atlas,'square-IconMask');eq(b.cooldown.circular,nil)
   end
  end
 end
end
eq(count,32,'16 faces across two Masque load orders')
local p=object();p.id='Unrelated';local unrelated=env.factories.GroupButton('Other_PAD1','PAD1',p);check(not unrelated.isForeverFaceButton,'other groups excluded')

-- Run the actual installed LAB Update body against populated, custom, and empty slots.
ActiveButtons={};ActionButtons={};NonActionButtons={};ActionButtonsNonUI={};gridCounter=0
UpdateButtonState=nop;UpdateUsable=nop;UpdateCooldown=nop;UpdateFlash=nop;UpdateCount=nop;UpdateFlyout=nop;UpdateOverlayGlow=nop;UpdateNewAction=nop;UpdateSpellHighlight=nop;UpdateAssistedCombatRotationFrame=nop;UpdatedAssistedHighlightFrame=nop
ClearActionButtonCooldowns=nop;GameTooltip_GetOwnerForbidden=function()return nil end;InCombatLockdown=function()return false end;RANGE_INDICATOR='*';lib.callbacks={Fire=nop}
local labenv=setmetatable({lib=lib},{__index=_G});assert(loadfile(WORK..'evidence/lab-update.lua','t',labenv))()
for _,bank in ipairs({'Base','L2','R2','L2R2'})do for _,id in ipairs({'PAD1','PAD2','PAD3','PAD4'})do
 local b=cached['ConsolePortGroup'..bank..'_'..id]
 for _,kind in ipairs({'action','custom','empty'})do
  b._state_type=kind;b.testTexture=kind~='empty' and 123456 or nil
  labenv.Update(b)
  eq(b.icon.shown,kind~='empty');check(b.SlotBackground.shown,'empty background present');eq(b.NormalTexture.atlas,nil,'LAB cannot restore square');check(b.NormalTexture.texture:find('RoundBorderHighlight',1,true),'final ring')
 end
end end
-- Base art must survive both final LAB writes and native UpdateButtonArt resets.
for _,id in ipairs({'PAD1','PAD2','PAD3','PAD4'})do
 local b=cached['ConsolePortGroupBase_'..id];b._state_type='custom';b.testTexture=123456;labenv.Update(b)
 local function art()
  if id=='PAD1' then check(b.icon.texture:find('ForeverInGame.blp',1,true));eq(b.icon.texcoord[1],397/2048);eq(b.icon.texcoord[4],1746/2048)
  elseif id=='PAD2' then eq(b.icon.atlas,'128-redbutton-exit');eq(GetBindingAction('PAD2'),'','art must not bind cancel')
  elseif id=='PAD3' then eq(b.icon.texture,132223)
  else eq(b.icon.atlas,targetExists and 'crosshair_inspect_32' or 'crosshair_unableinspect_32') end
 end
 art();b:UpdateButtonArt();art();targetExists=true;b:UpdateLocal();art();targetExists=false
 local oldBinding=bindingActions[id];bindingActions[id]='OTHER';labenv.Update(b);eq(b.icon.texture,123456,'custom rebinding retains its own icon');bindingActions[id]=oldBinding
end
for _,bank in ipairs({'L2','R2','L2R2'})do for _,id in ipairs({'PAD1','PAD2','PAD3','PAD4'})do
 local b=cached['ConsolePortGroup'..bank..'_'..id];b._state_type='custom';b.testTexture=98765;labenv.Update(b);eq(b.icon.texture,98765,'modifier art unchanged')
end end
print('PASS: real Group factories and ProxyButton skin chain; 16 face / 16 D-pad slots; early/late Masque + rebuild; 48 actual LAB populated/custom/empty updates; state textures, masks, cooldowns and proc dispatch.')

-- A fresh sandbox models each login/reload; use Edit Mode base-method wrappers.
local function castSuite(label)
 local S=setmetatable({}, {__index=_G});S._G=S
 local queue,combat,dirty={},false,0
 S.UIParent=object();S.UIParent.scale=0.76
 S.PlayerFrame=object(S.UIParent);S.PlayerFrame.scale=0.8
 S.TargetFrame=object(S.UIParent)
 local health=object(S.PlayerFrame)
 S.PlayerFrame.PlayerFrameContent={PlayerFrameContentMain={HealthBarsContainer=health}}
 local buffs=object(S.UIParent);S.BuffFrame=buffs
 buffs.AuraContainer={addIconsToRight=false,iconScale=0.8,iconPadding=3,iconStride=8}
 buffs.UpdateGridLayout=function(self)self.layoutRuns=(self.layoutRuns or 0)+1 end
 buffs.SetPointBase=Methods.SetPoint;buffs.ClearAllPointsBase=Methods.ClearAllPoints
 buffs.ApplySystemAnchor=function(self)self:SetPoint('TOPRIGHT',S.UIParent,'TOPRIGHT',0,0)end
 buffs.OnEditModeExit=nop
 S.ConsolePortGroupBase=object(S.UIParent);S.ConsolePortGroupBase.scale=1.06
 local cast=object(S.PlayerFrame);cast.width=150;cast.height=10;cast.scale=1.25;cast.look='UNITFRAME';S.PlayerCastingBarFrame=cast
 cast.SetPointBase=Methods.SetPoint;cast.ClearAllPointsBase=Methods.ClearAllPoints;cast.SetScaleBase=Methods.SetScale
 cast.SetPoint=function(self,...)dirty=dirty+1;self:SetPointBase(...)end
 cast.ClearAllPoints=function(self)dirty=dirty+1;self:ClearAllPointsBase()end
 cast.SetScale=function(self,s)dirty=dirty+1;self:SetScaleBase(s)end
 cast.SetLook=function(self,l)self.look=l;self:SetSize(l=='UNITFRAME' and 150 or 208,l=='UNITFRAME' and 10 or 11)end
 cast.ApplySystemAnchor=function(self)self:SetPoint('TOPRIGHT',S.PlayerFrame,'BOTTOMRIGHT',0,0)end
 cast.OnEditModeExit=nop
 S.PlayerFrame_AttachCastBar=function()cast:SetParent(S.PlayerFrame);cast:SetLook('UNITFRAME');cast:SetPoint('TOPRIGHT',S.PlayerFrame,'BOTTOMRIGHT',-24,12)end
 S.PlayerFrame_DetachCastBar=function()cast:SetLook('CLASSIC')end
 S.hooksecurefunc=function(a,b,c)
  local t,k,f;if type(a)=='string'then t,k,f=S,a,b else t,k,f=a,b,c end
  local old=assert(t[k]);t[k]=function(...)old(...);f(...)end
 end
 local events
 local prompts={}
 S.CreateFrame=function(_,name,parent)
  local f=object(parent);f.name=name;if name then prompts[#prompts+1]=f else events=f end;return f
 end
 S.InCombatLockdown=function()return combat end
 S.C_Timer={After=function(_,f)queue[#queue+1]=f end}
 local removed=0;S.GetBottomManagedFrameContainer=function()return {RemoveManagedFrame=function(_,f)eq(f,cast);removed=removed+1 end}end
 assert(loadfile(STAGE..'Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua','t',S))()
 local function flush()local n=0;while #queue>0 do local f=table.remove(queue,1);f();n=n+1;check(n<100,'cast hook recursion')end end
 local function position()
  eq(cast.parent,S.UIParent);eq(cast.points[1],'BOTTOM');eq(cast.points[2],S.ConsolePortGroupBase);eq(cast.points[3],'TOP');eq(cast.points[4],0);eq(cast.points[5],12+5/cast:GetEffectiveScale())
  eq(cast.width,150);eq(cast.height,10);eq(cast.look,'UNITFRAME');check(math.abs(cast:GetEffectiveScale()-0.76)<1e-9,'cast effective size');eq(cast.attachedToPlayerFrame,false)
 end
 events.scripts.OnEvent(events,'PLAYER_ENTERING_WORLD');flush();position();eq(dirty,0,'no Edit Mode bookkeeping');eq(removed,1)
 S.PlayerFrame_AttachCastBar();local d=dirty;flush();position();eq(dirty,d,'attachment repair no tainted snap writes')
 cast:ApplySystemAnchor();S.PlayerFrame_DetachCastBar();cast:SetScale(1.7);d=dirty;flush();position();eq(dirty,d)
 combat=true;cast:ApplySystemAnchor();flush();eq(cast.points[1],'TOPRIGHT','combat defers mutation')
 combat=false;events.scripts.OnEvent(events,'PLAYER_REGEN_ENABLED');flush();position()
 S.ConsolePortGroupBase:SetScale(0.94);position()
 local function buffPosition()
  eq(buffs.points[1],'TOPRIGHT');eq(buffs.points[2],S.PlayerFrame);eq(buffs.points[3],'TOPLEFT');eq(buffs.points[4],-12);eq(buffs.points[5],5)
  eq(buffs.AuraContainer.addIconsToRight,false);eq(buffs.AuraContainer.iconScale,0.8);eq(buffs.AuraContainer.iconPadding,3);eq(buffs.AuraContainer.iconStride,8)
 end
 buffPosition();buffs:ApplySystemAnchor();buffs.AuraContainer.addIconsToRight=true;buffs:UpdateGridLayout();flush();buffPosition()
 buffs.AuraContainer.addIconsToTop=true;buffs:UpdateGridLayout();flush();eq(buffs.points[1],'BOTTOMRIGHT');eq(buffs.points[3],'BOTTOMLEFT');eq(buffs.points[4],-12);eq(buffs.points[5],-5)
 buffs.AuraContainer.addIconsToTop=false;buffs:UpdateGridLayout();flush();buffPosition()
 combat=true;buffs:ApplySystemAnchor();flush();eq(buffs.points[1],'TOPRIGHT');combat=false;events.scripts.OnEvent(events,'PLAYER_REGEN_ENABLED');flush();buffPosition()
 eq(#prompts,2,'no prompt duplicates');for i,p in ipairs(prompts)do
  eq(p.parent,S.ConsolePortGroupBase);eq(p.mouse,false);eq(p.points[4],i==1 and -155 or 155);eq(p.points[5],-32)
  eq(p.width,34);eq(p.height,30.6);eq(p.textures[2].texcoord[1],223/512);eq(p.textures[2].texcoord[3],(i==1 and 141 or 188)/256)
  check(p.textures[3].texture:find(i==1 and 'ps_s_l1' or 'ps_s_r1',1,true),'glyph')
 end
 -- Late aura module availability is repaired through ADDON_LOADED.
 S.BuffFrame=nil;events.scripts.OnEvent(events,'ADDON_LOADED');flush();S.BuffFrame=buffs;events.scripts.OnEvent(events,'ADDON_LOADED');flush();buffPosition()
 eq(S.PlayerFrame.points[4],-310);eq(S.PlayerFrame.points[5],-175);eq(S.TargetFrame.points[4],310);eq(S.TargetFrame.points[5],-175)
 print('PASS: cast '..label..', attachment restore, Edit Mode reset, combat deferral/recovery, five-pixel raise; left-growing buff layout/edit-mode/combat/late load; two passive targeting prompts; size/skin/unit positions preserved.')
end
castSuite('login');castSuite('reload')

-- Execute native Immersion movement, including its animation and return to rest.
local im={};assert(loadfile(STAGE..'WTF/Account/119624169#1/SavedVariables/Immersion.lua','t',im))()
local talk=object();talk.extraY=0
local settings=im.ImmersionSetup
local baseY=39.27963256835938
local L=setmetatable({frame={TalkBox=talk},Mixin=Mixin},{__call=function(_,k)return settings[k] end})
local I=setmetatable({UIParent={GetBottom=function(self)return self.bottom or 0 end},abs=math.abs},{__index=_G})
talk.SetPoint=function(self,point,parent,x,y)self.bottom=y;self.x=x;self.point=point end
assert(loadfile(ROOT..'Interface/AddOns/Immersion/Logic/Talkbox.lua','t',I))('Immersion',L)
local function settle()local n=0;while talk.scripts.OnUpdate do talk.scripts.OnUpdate(talk);n=n+1;check(n<200,'Immersion animation did not settle')end end
talk.shown=false;talk:SetExtraOffset(0);eq(talk.bottom,baseY);eq(talk.x,0)
talk.shown=true;talk:SetExtraOffset((100+32)*settings.elementscale);settle();check(math.abs(talk.bottom-(baseY+132))<1e-8);eq(talk.offsetY,baseY)
talk:SetExtraOffset((100+48)*settings.elementscale);settle();check(math.abs(talk.bottom-(baseY+148))<1e-8)
talk:SetExtraOffset(0);settle();eq(talk.bottom,baseY);eq(talk.point,'Bottom');eq(talk.x,0)
eq(settings.titleoffset,446.7689819335938);eq(settings.titleoffsetY,-117.6884460449219);eq(settings.scale,1.2)
print('PASS: native Immersion rest (0,39.2796), reward/objective rise by 132/148, animated return to the user-selected Y; title offsets and scale 1.2 retained.')
