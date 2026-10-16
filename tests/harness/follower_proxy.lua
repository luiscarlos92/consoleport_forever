-- Continuation of the actual native follower execution fixture. The macro
-- tokenizer, frame lookup/Click C methods and permissions remain explicit host
-- doubles; native /click Lua, Map, restricted ring and secure proxy dispatch run.
TEST_SUCCESS=nil
--@FOLLOWER_PROXY_SOURCE
do
local macroCalls,macroAllowed=0,true
local nativeClickSlash
local proxyChecks=0
local function verify(value,message) proxyChecks=proxyChecks+1 assert(value,message) end
local primary=CreateFrame('Button',nil,UIParent,'PingableActionButtonTemplate')
local secondary=CreateFrame('Button',nil,UIParent,'PingableActionButtonTemplate')
local OTHER=999001
local function configure(frame)
    Mixin(frame,ZoneAbilityFrameSpellButtonMixin)
    frame.Icon={SetTexture=function() end}
    frame.Count={SetText=function() end}
    frame.CheckForTutorial=function() end -- tutorial UI is unrelated to identity.
    frame:SetScript('OnClick',ZoneAbilityFrameSpellButtonMixin.OnClick)
end
configure(primary) configure(secondary)
C_Spell=C_Spell or {}
C_Spell.GetSpellCharges=function() end C_Spell.GetSpellCooldown=function() end
C_Spell.GetSpellCastCount=function() return 0 end
C_SpellBook={FindSpellOverrideByID=function(id) return id end}
C_ZoneAbility={GetZoneAbilityIcon=function(id) return id end}
primary:SetContent({spellID=ID}) secondary:SetContent({spellID=OTHER})
secureScripts[ZoneAbilityFrameSpellButtonMixin.OnClick]=true
local activePool={primary}
local followerContext=true
local api={find=function(name) return frames[name] end,
    create=function(name) return CreateFrame('Button',name,UIParent,'SecureActionButtonTemplate,SecureHandlerStateTemplate') end,
    driver=RegisterStateDriver,combat=InCombatLockdown,context=function() return followerContext end,
    pool=function() return activePool end,nativeClick=ZoneAbilityFrameSpellButtonMixin.OnClick,
    public=function(value) return type(value)~='table' or value.__opaque~=true end}
local bridge=assert(Addon.FollowerProxyPrototype.New(api))
verify(bridge:Refresh(),'qualified out-of-combat delegate missing')
function Frame:IsObjectType(kind) return kind=='Button' end
-- Preserve the native /click-supplied edge; the earlier direct-click host did
-- not need this C-method argument and deliberately omitted it.
function Frame:Click(button,down)
    if down==nil then down=false end
    fire(self,'PreClick',button,down)
    fire(self,'OnClick',button,down,nil,nil)
    fire(self,'PostClick',button,down)
end
function GetClickFrame(name) return frames[name] end
function SecureCmdOptionParse(text) return text end -- Fixed /click payload has no options.
function StringToBoolean(value,default)
    if value=='' then return default end
    if value=='1' or value=='true' then return true end
    if value=='0' or value=='false' then return false end
    return default
end
local register=SlashCommandUtil.CheckAddSecureSlashCommand
SlashCommandUtil.CheckAddSecureSlashCommand=function(_,_,fn) nativeClickSlash=fn end
SLASH_COMMAND.CLICK=2 SLASH_COMMAND_CATEGORY.CHAT_COMMAND=2
--@FOLLOWER_NATIVE_CLICK_SLASH
SlashCommandUtil.CheckAddSecureSlashCommand=register
C_Macro.RunMacroText=function(text,button)
    verify(trusted and hardware,'macro lost modeled secure hardware route')
    macroCalls=macroCalls+1
    if not macroAllowed then error('modeled engine rejects macrotext') end
    local args=assert(text:match('^/click ([^\n]+)$'),'unexpected macro payload')
    nativeClickSlash(args)
end
local function entry()
    ring.Data[1]={[0]={},bridge:Entry()}
    ring:RefreshAll()
end
local function use(hold,selected)
    if not combat then
    nativeSettings.ringPressAndHold=hold ring:OnPressAndHoldChanged()
    nativeSettings.ringStickySelect=false ring:OnStickySelectChanged()
    else
        verify(nativeSettings.ringPressAndHold==hold and not nativeSettings.ringStickySelect,'combat test attempted public ring reconfiguration')
    end
    currentIndex=selected and 1 or nil
    edge('LeftButton',true) edge('LeftButton',false)
    if not hold then edge('LeftButton',true) edge('LeftButton',false) end
end
entry()
local encoded=Addon.Core.Copy(ring.Data[1])
verify(encoded[1].binding=='CLICK CPFOfflineFollowerProxy:LeftButton' and encoded[1].autoassigned,
    'native ring representation is not a serializable temporary binding')
local routed=0
for _,withAdapter in ipairs({false,true}) do
if withAdapter then attach() end
for _,hold in ipairs({true,false}) do
    for _,keyDown in ipairs({'0','1'}) do
        cvars.ActionButtonUseKeyDown=keyDown
        for _,modifier in ipairs({'','shift','ctrl','ctrlshift'}) do
            FOLLOWER_MODIFIERS={shift=modifier:find('shift')~=nil,ctrl=modifier:find('ctrl')~=nil}
            for iteration=1,3 do
                local before,macros=#calls,macroCalls use(hold,true)
                verify(#calls==before+1 and macroCalls==macros+1,'custom binding chain lost or duplicated cast: adapter='..tostring(withAdapter)
                    ..' hold='..tostring(hold)..' keyDown='..keyDown..' modifier='..modifier..' casts='..tostring(#calls-before)..' macros='..tostring(macroCalls-macros))
                verify(calls[#calls].id==ID and calls[#calls].toggle==true,'custom binding chain lost native toggle semantics')
                routed=routed+1
            end
        end
    end
end
if withAdapter then pump() detach() end
end
FOLLOWER_MODIFIERS={} cvars.ActionButtonUseKeyDown='1'
local before=#calls use(true,false)
verify(#calls==before,'neutral nonsticky proxy cast')
-- Each independent access gate must stop the entire chain without a second
-- generic spell attempt: both /click's proxy gate and secure click's delegate.
for _,target in ipairs({bridge.frame,primary}) do
    for _,kind in ipairs({'access','forbidden'}) do
        target.HasAccessConstraints=function() return kind=='access' end
        target.HasAnyForbiddenAspects=function() return kind=='forbidden' end
        before=#calls use(true,true)
        verify(#calls==before,'proxy/delegate native access gate bypassed')
    end
    target.HasAccessConstraints=Frame.HasAccessConstraints
    target.HasAnyForbiddenAspects=Frame.HasAnyForbiddenAspects
end
-- Missing, foreign, ambiguous and opaque identities do not retain a delegate.
for _,case in ipairs({'missing','outside','ambiguous','opaque','foreign'}) do
    activePool={primary} followerContext=true
    if case=='missing' then activePool={}
    elseif case=='outside' then followerContext=false
    elseif case=='ambiguous' then secondary:SetContent({spellID=ID}) activePool={primary,secondary}
    elseif case=='opaque' then followerContext={__opaque=true}
    else activePool={secondary} secondary:SetScript('OnClick',function() end) end
    verify(not bridge:Refresh(),'unknown delegate identity enabled proxy')
    before=#calls use(true,true)
    verify(#calls==before and bridge.frame:GetAttribute('clickbutton')==nil,'missing delegate retained stale cast')
end
configure(secondary) primary:SetContent({spellID=ID}) secondary:SetContent({spellID=OTHER})
activePool={primary} followerContext=true assert(bridge:Refresh())
-- Counterexample: a native pool frame is mutable. Borrowing the pointer alone
-- dispatches another spell after actual native SetContent reuses that frame.
primary:SetContent({spellID=OTHER})
before=#calls use(true,true)
verify(#calls==before+1 and calls[#calls].id==OTHER,'pooled delegate reuse counterexample did not reproduce')
local unsafeReuseCasts=#calls-before
verify(not bridge:Refresh(),'recycled non-follower still qualified')
before=#calls use(true,true) verify(#calls==before,'out-of-combat reconciliation retained recycled delegate')
secondary:SetContent({spellID=ID}) activePool={secondary}
verify(bridge:Refresh(),'replacement follower pool frame failed rebind')
before=#calls use(true,true) verify(#calls==before+1 and calls[#calls].id==ID,'replacement frame routed to stale delegate')
-- Combat transition must use predeclared secure state, not a public callback
-- writing a protected proxy. Clearing again on peace prevents stale re-enable.
local function transition(inCombat)
    combat=inCombat trusted=true
    bridge.frame:RunAttribute('_onstate-follower-combat','follower-combat',inCombat and 'combat' or 'peace')
    trusted=false
end
transition(true)
secondary:SetContent({spellID=OTHER})
verify(not bridge:Refresh(),'public lifecycle refreshed protected proxy in combat')
before=#calls use(true,true)
verify(#calls==before,'combat pool reuse clicked a different spell')
transition(false)
before=#calls use(true,true) verify(#calls==before,'peace transition re-enabled stale delegate before reconciliation')
primary:SetContent({spellID=ID}) activePool={primary} assert(bridge:Refresh())
before=#calls use(true,true) verify(#calls==before+1,'postcombat replacement failed to resume after reconciliation')
-- C_Macro restrictions are an engine boundary: rejection stops the chain;
-- no second cast path or native bypass is attempted in this experiment.
macroAllowed=false before=#calls
local ok,err=pcall(use,true,true)
trusted=false hardware=false
verify(not ok and tostring(err):find('modeled engine rejects macrotext',1,true) and #calls==before,
    'macro rejection attempted a bypass or generic fallback')
macroAllowed=true currentIndex=nil ring:Hide()
-- Native auto-assignment compares complete entries. Replacing its spell row
-- with a custom row allows a later native auto-add to append the plain spell.
db.RegisterCallback=function() end
CPAPI.IsModernVersion=true CPAPI.ExtraActionButtonID=169
CPAPI.GetActiveZoneAbilities=function() return {{spellID=ID,uiPriority=1}} end
C_ActionBar={FindSpellActionButtons=function() end}
--@FOLLOWER_NATIVE_ACTION_MAP
--@FOLLOWER_NATIVE_AUTO
function ring:AnnounceAddition() end -- Announcement art/sound is outside this probe.
local beforeRows=#ring.Data[1]
ring:ToggleZoneAbilities()
verify(#ring.Data[1]==beforeRows+1 and ring.Data[1][#ring.Data[1]].type=='spell',
    'native automatic re-add counterexample did not reproduce')
-- A stable serialized representation also needs refresh reconciliation; merely
-- adding the named proxy is not an integration-ready native transient adapter.
FOLLOWER_PROXY_RESULTS={checks=proxyChecks,routedSelections=routed,
    unsafePoolReuseCasts=unsafeReuseCasts,nativeAutoReaddedSpell=true,
    conservativeCandidateDisablesInCombat=true,fullCombatRouteQualified=false,
    macroEnginePermissionQualified=false,
    limit='Macro tokenizer/frame C methods/access are modeled; native slash, Map, restricted controller and dispatch are actual source. No Retail permission, taint, pool event-order or full combat qualification.'}
TEST_SUCCESS=true
end
