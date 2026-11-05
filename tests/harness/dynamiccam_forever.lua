unpack=table.unpack; strlenutf8=string.len; strmatch=string.match
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
function CreateFrame() return {scripts={}, RegisterEvent=function()end, SetScript=function(self,k,v)self.scripts[k]=v end} end
function UnitFactionGroup() return 'Alliance' end
function GetLocale() return 'enUS' end
function UnitClass() return 'Druid','DRUID' end
function UnitRace() return 'Night Elf','NightElf' end
function RegionalUniqueNamesEnabled() return true end
C_GameRules={IsGameRuleActive=function()return false end}
Enum={GameRule={HardcoreRuleset=1,RPRuleset=2,PvPRuleset=3}}
function UnitNameUnmodified() return 'Test','Person' end
function GetRealmName() return '91' end
function GetCurrentRegionName() return 'US' end
function GetCurrentRegion() return 1 end
function GetCVarDefault() return '1' end
function geterrorhandler() return error end
WOW_PROJECT_MAINLINE=1; WOW_PROJECT_CLASSIC=2; WOW_PROJECT_CAMELOT=18; WOW_PROJECT_ID=18
DC={}
DynamicCam=DC
--@LIBS
local ace=LibStub:NewLibrary('AceAddon-3.0',99999)
function ace:GetAddon() return DC end
local locale=LibStub:NewLibrary('AceLocale-3.0',99999)
function locale:GetLocale() return setmetatable({},{__index=function(_,k)return k end}) end
local gui=LibStub:NewLibrary('AceGUI-3.0',99999)
function gui:Create() end
--@DEFAULTS
local profile={version=6,standardSettings={cvars={test_cameraOverShoulder=0.8,cameraZoomSpeed=12,cameraDistanceMaxZoomFactor=2.6},reactiveZoomMaxZoomTime=0.35},situations={}}
local zooms={['100']=20,['160']=28,['300']=5.5,['301']=7,['302']=0,['320']=8,['323']=16,['033']=28,['023']=22,['006']=18,['002']=7,['034']=24,['005']=8,['031']=20,['021']=17,['001']=12,['024']=20,['004']=14,['020']=17,['030']=20}
for id,zoom in pairs(zooms) do
    assert(DC.defaults.profile.situations[id], 'unsupported imported context '..id)
    profile.situations[id]={enabled=true,viewZoom={enabled=true}}
    if zoom>0 then profile.situations[id].viewZoom.zoomValue=zoom end
end
DynamicCamDB={profileKeys={['Test Person']='Retail-like (Forever)'},profiles={['Retail-like (Forever)']=profile}}
DC.db=LibStub('AceDB-3.0'):New('DynamicCamDB',DC.defaults,true)
assert(DC.db:GetCurrentProfile()=='Retail-like (Forever)')
assert(DC.db.profile.standardSettings.cvars.test_cameraOverShoulder==0.8)
local count=0
for id,s in pairs(DC.db.profile.situations) do
    if s.enabled then count=count+1; assert(s.condition==DC.defaults.profile.situations[id].condition) end
end
assert(count==20 and DC.db.profile.situations['325'] and not DC.db.profile.situations['325'].enabled,'enabled contexts lost')

local timers, environments={},{}
local world={resting=false,indoors=false,combat=false,mounted=false,swimming=false,npc=false}
local time=0
function GetTime() return time end
function IsResting() return world.resting end
function IsIndoors() return world.indoors end
function IsOutdoors() return not world.indoors end
function IsInInstance() return false,'none' end
function UnitAffectingCombat() return world.combat end
function IsMounted() return world.mounted end
function UnitOnTaxi() return false end
function IsSwimming() return world.swimming end
function UnitExists() return world.npc end
function UnitCastingInfo() end
function UnitChannelInfo() end
C_Spell={GetSpellName=function()return 'Fishing' end}
function UnitGUID() end
function GetCVar(name) return name=='cameraView' and '1' or '0' end
function hooksecurefunc() end
ImmersionFrame={IsShown=function()return world.npc end}
function DC:RunScript(id,key)
    local env=environments[id]
    if not env then env=setmetatable({this={},DynamicCam=self},{__index=_G});environments[id]=env end
    return assert(load(self.db.profile.situations[id][key],id..':'..key,'t',env))()
end
for id,s in pairs(DC.db.profile.situations)do if s.enabled then DC:RunScript(id,'executeOnInit') end end
DC.conditionExecutionCache={}
function DC:ScheduleTimer(method) timers[#timers+1]=method end
function DC:CancelTimer() end
function DC:GetSettingsValue() return false end
function DC:ReactiveZoomOff() self.zoomStarted=true end
function DC:SettingsPanelSetIgnoreParentAlpha() end
function DC:ApplySettings() self.applied=true end
function DC:RegisterEvents() self.eventsRegistered=true end
function DC:SendMessage() end
function DC:ChangeSituation(_,new) self.currentSituationID=new end
local started=false
local constantlyRunningFrame=CreateFrame('Frame')
local ConstantlyRunningFrameFunction=function() end
local moreQuestDialog=false
local waitForQuestFrameToReopen=0.5
local unsetMoreQuestDialogTimer
local function Round(n,p)return math.floor(n*10^p+0.5)/10^p end
local delayTime
--@STARTUP
--@EVALUATOR
DC:Startup()
assert(started and DC.zoomStarted and constantlyRunningFrame.scripts.OnUpdate)
for _,method in ipairs(timers) do DC[method](DC) end
assert(DC.applied and DC.eventsRegistered and DC.enteredSituationAtLogin,'startup never evaluated')
assert(DC.currentSituationID=='004', 'world situation not active')
local function evaluate(expected)
    time=time+100;DC:EvaluateSituations();time=time+100;DC:EvaluateSituations()
    assert(DC.currentSituationID==expected,'wrong native situation: '..tostring(DC.currentSituationID))
end
world.combat=true;evaluate('006');world.combat=false
world.resting=true;evaluate('001')
world.indoors=true;evaluate('002')
world.indoors=false;world.resting=false;world.swimming=true;evaluate('323')
world.swimming=false;world.mounted=true;evaluate('100')
world.mounted=false;world.npc=true;evaluate('300')
world.npc=false;evaluate('004')
local aceDB=LibStub('AceDB-3.0')
aceDB.frame.scripts.OnEvent(aceDB.frame,'PLAYER_LOGOUT')
DC.db=aceDB:New('DynamicCamDB',DC.defaults,true)
assert(DC.db:GetCurrentProfile()=='Retail-like (Forever)')
assert(DC.db.profile.situations['004'].enabled and DC.db.profile.situations['004'].viewZoom.zoomValue==14)
