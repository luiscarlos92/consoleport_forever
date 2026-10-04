local nativeImmersion,nativeExtraFade={},{}
--@NATIVE_IMMERSION_CONFIG
local combat=false
local versions={Immersion='1.4.61',Immersion_ExtraFade='1.18.0'}
local api={ImmersionSetup=nativeImmersion.GetDefaultConfig(),InCombatLockdown=function() return combat end,
    C_AddOns={GetAddOnMetadata=function(name) return versions[name] end,IsAddOnLoaded=function(name) return versions[name]~=nil end}}
nativeImmersion.cfg=api.ImmersionSetup
api.ImmersionSetup.padgoodbye=false api.ImmersionSetup.solidbackground=true
api.ImmersionSetup.manual='keep unknown data' api.ImmersionSetup.customFont={name='preserved theme font'}
api.ImmersionSetup.titleoffsetY=37 api.ImmersionSetup.boxoffsetX=-19
assert(nativeImmersion.Get('padgoodbye')==false)
LibStub=function(name) assert(name=='AceAddon-3.0') return {GetAddon=function(_,addon) assert(addon=='Immersion_ExtraFade') return nativeExtraFade end} end
--@NATIVE_EXTRFADE_OPTIONS
IEF_Config={keepChatFrame=false,customFramesToKeep={MyFrame=true}}
nativeExtraFade:InitializeSavedVariables()
api.IEF_Config=IEF_Config
IEF_Config.UIParentAlpha=0 IEF_Config.unknownTransient=true
local before=Addon.Core.Copy({immersion=api.ImmersionSetup,extrafade=api.IEF_Config})
local immersion=assert(Addon.FlatIntegrations.New('immersion',api))
local extra=assert(Addon.FlatIntegrations.New('extrafade',api))
local schema=Addon.FlatIntegrations.Types('immersion')
for key in pairs(nativeImmersion.defaults) do assert(schema[key],'uncovered native Immersion default '..key) end
for _,key in ipairs(NATIVE_IMMERSION_SETTINGS_KEYS) do assert(schema[key],'uncovered native Immersion panel setting '..key) end
local extraSchema=Addon.FlatIntegrations.Types('extrafade')
for key in pairs(before.extrafade) do if key~='UIParentAlpha' and key~='unknownTransient' then assert(extraSchema[key],'uncovered native ExtraFade setting '..key) end end
assert(Addon.Core.Equal(before,{immersion=api.ImmersionSetup,extrafade=api.IEF_Config}),'readiness/adoption changed native settings')
assert(immersion.allowed.padgoodbye and immersion.allowed.padnext and immersion.allowed.titleoffsetY and immersion.allowed.solidbackground)
assert(not immersion.allowed.manual and not immersion.allowed.customFont)
assert(extra.allowed.customFramesToKeep and not extra.allowed.UIParentAlpha and not extra.allowed.unknownTransient)
assert(immersion:read({'padgoodbye'})==false and immersion:read({'boxoffsetX'})==-19)
local ref=IEF_Config.customFramesToKeep
assert(extra:write({'customFramesToKeep'},{OtherFrame=false}) and IEF_Config.customFramesToKeep==ref and ref.MyFrame==nil)
assert(extra:write({'customFramesToKeep'},before.extrafade.customFramesToKeep) and ref.MyFrame==true)
assert(IEF_Config.keepChatFrame==false and IEF_Config.UIParentAlpha==0 and IEF_Config.unknownTransient==true)
assert(immersion:write({'boxoffsetX'},nil) and api.ImmersionSetup.boxoffsetX==nil)
assert(nativeImmersion.Get('boxoffsetX')==0,'absent raw setting did not retain native default lookup')
assert(immersion:write({'boxoffsetX'},-19))
combat=true assert(not immersion:write({'padgoodbye'},'PAD2')) combat=false
assert(not pcall(extra.write,extra,{'customFramesToKeep'},{Wrong='not a flag'}))
api.ImmersionSetup.boxoffsetX=function() end
assert(not pcall(immersion.read,immersion,{'boxoffsetX'}))
local partial=assert(Addon.FlatIntegrations.New('immersion',api))
assert(not partial.allowed.boxoffsetX and partial.allowed.padgoodbye and #partial.pending==1)
api.ImmersionSetup.boxoffsetX=-19
local saved=api.ImmersionSetup
api.ImmersionSetup=Addon.Core.Copy(saved)
assert(not pcall(immersion.read,immersion,{'titleoffsetY'}),'stale cached settings table was accepted')
api.ImmersionSetup=saved versions.Immersion='future'
assert(not Addon.FlatIntegrations.New('immersion',api))
assert(not pcall(immersion.write,immersion,{'titleoffsetY'},0),'version changed without requalification')
versions.Immersion='1.4.61' api.IEF_Config=nil
assert(not Addon.FlatIntegrations.New('extrafade',api))
assert(immersion.reloadRequired and extra.reloadRequired)
TEST_SUCCESS=true
