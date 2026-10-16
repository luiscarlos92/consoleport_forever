-- Actual pinned RestrictedFrames / RestrictedEnvironment in the same isolated
-- fixture. Frame/handle C methods, combat and securecall taint remain doubles.
TEST_SUCCESS=nil
do
local total=0
local function expect(value,message) total=total+1 assert(value,message) end
local handleNamespace
CopyTable=function(value) return copy(value) end
function GetFrameMetatable() return {__index=Frame} end
function GetButtonMetatable() return {__index=Frame} end
function GetFrameHandleFrame(handle)
    for frame,value in pairs(handleCache) do if value==handle then return frame,frame.protected end end
end
function GetFrameHandle(frame) return proxy(frame) end
function AddReferencedFrame() end
function PropagateForbiddenToReferencedFrames() end
function InitFrameHandleNamespace(value) handleNamespace=value end
local softErrors={}
function SoftError(value) softErrors[#softErrors+1]=tostring(value) end
--@FOLLOWER_NATIVE_RESTRICTED_FRAMES
expect(type(handleNamespace)=='table','actual restricted frame namespace not loaded')
local zone=CreateFrame('Button',nil,UIParent,'PingableActionButtonTemplate')
zone.GetSpellID=ZoneAbilityFrameSpellButtonMixin.GetSpellID
zone.spellID=ID zone:SetAttribute('follower-spell',ID)
local handle=proxy(zone)
handle.GetAttribute=handleNamespace.GetAttribute
handle.CallMethod=handleNamespace.CallMethod
local read=assert(BuildRestrictedClosure('return self:GetAttribute("follower-spell")',restricted,'self'))
expect(read(handle)==ID,'outside-combat native handle read failed')
combat=true
local ok,err=pcall(read,handle)
expect(not ok and tostring(err):find('Invalid frame handle',1,true),
    'unprotected combat handle unexpectedly authorized identity read')
combat=false
local raw=assert(BuildRestrictedClosure('return self.spellID',restricted,'self'))
expect(raw(handle)==nil,'restricted handle exposed arbitrary native spell field')
local invoke=assert(BuildRestrictedClosure('return self:CallMethod("GetSpellID")',restricted,'self'))
trusted=true local result=invoke(handle)
expect(result==nil,'public CallMethod returned spell identity into secure code')
trusted=false
-- Even for a protected target, the public callback cannot grant attribute
-- authority in combat; actual CallMethod forces insecure before invoking it.
zone.protected=true
zone.WriteIdentity=function(self)
    self.writeCalls=(self.writeCalls or 0)+1
    self.callbackTrusted=trusted
    self.writeAllowed,self.writeError=pcall(self.SetAttribute,self,'follower-spell',self:GetSpellID())
end
zone.spellID=999001 combat=true trusted=true
local write=assert(BuildRestrictedClosure('return self:CallMethod("WriteIdentity")',restricted,'self'))
write(handle)
expect(zone.writeCalls==1 and zone.callbackTrusted==false and not zone.writeAllowed
    and tostring(zone.writeError):find('insecure protected attribute write',1,true)
    and zone:GetAttribute('follower-spell')==ID,
    'public CallMethod incorrectly authorized combat identity write')
trusted=false combat=false
-- Execute the actual restricted global whitelist rather than manufacturing a
-- failed cast by omitting an API from a test-only environment.
function GetGlobalEnvironment() return _G end
_G.IsFrameHandle=IsFrameHandle
rtable={copytable=Addon.Core.Copy}
C_Item=C_Item or {} C_AssistedCombat=C_AssistedCombat or {} C_TransmogOutfitInfo=C_TransmogOutfitInfo or {}
local environmentExport={}
--@FOLLOWER_NATIVE_RESTRICTED_ENVIRONMENT
local scope=environmentExport.RESTRICTED_FUNCTIONS_SCOPE
expect(type(scope)=='table' and scope.CastSpellByID==nil and scope.CastSpellByName==nil,
    'native restricted whitelist unexpectedly exposes protected casting')
local unsafe=assert(BuildRestrictedClosure('CastSpellByID(426756, nil, true)',scope,'self'))
local count=#calls
ok,err=pcall(unsafe,handle)
expect(not ok and tostring(err):find('CastSpellByID',1,true) and #calls==count,
    'restricted direct cast unexpectedly reached protected API')
-- Generic secure spell attributes have no documented tryToggle switch in the
-- pinned handler. Supplying one does not change its actual two-argument call.
local direct=CreateFrame('Button','FollowerAttributeExperiment',UIParent,'SecureActionButtonTemplate')
direct:SetAttribute('pressAndHoldAction',true) direct:SetAttribute('typerelease','spell')
direct:SetAttribute('spell',ID) direct:SetAttribute('tryToggleSpell',true) direct:SetAttribute('toggle',true)
hardware=true trusted=true fire(direct,'OnClick','LeftButton',false,true,true) trusted=false hardware=false
expect(#calls==count+1 and calls[#calls].argc==2 and calls[#calls].toggle==nil,
    'generic spell unexpectedly consumed invented toggle attributes')
FOLLOWER_BOUNDARY_RESULTS={checks=total,actualHandleAndWhitelistSource=true,
    unprotectedCombatIdentityRejected=true,publicCallbackReturnsDiscarded=true,
    publicCombatWriteRejected=true,directRestrictedCastUnavailable=true,
    genericToggleAttributeUnsupported=true,
    limit='C protection/securecall/handle lookup are modeled. Source checks identify unavailable authority; no Retail protection flags, taint, C toggle semantics or permission acceptance.'}
TEST_SUCCESS=true
end
