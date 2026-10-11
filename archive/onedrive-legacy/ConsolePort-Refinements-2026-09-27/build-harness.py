from pathlib import Path
import shutil
w=Path(__file__).resolve().parent
old=w.parent/'ConsolePort-Polish-2026-09-27'
s=(old/'harness.lua').read_text()
s=s.replace("local WORK = 'ConsolePort-Polish-2026-09-27/'", "local WORK = 'ConsolePort-Refinements-2026-09-27/'")
s=s.replace('nop = function() end', '''nop = function() end
local bindingActions={PAD1='JUMP',PAD2='',PAD3='INTERACTTARGET',PAD4='TURNORACTION'}
GetBindingAction=function(id)return bindingActions[id] or '' end
local targetExists=false
UnitExists=function()return targetExists end
C_Spell={GetSpellTexture=function(id)eq(id,6603);return 132223 end}''')
s=s.replace('function Methods:CreateTexture() return object(self) end', '''function Methods:CreateTexture(_,layer)
 local t=object(self);t.drawLayer=layer;self.textures=self.textures or {};self.textures[#self.textures+1]=t;return t
end
function Methods:EnableMouse(v) self.mouse=v end''')
marker="print('PASS: real Group factories"
at=s.index(marker)
s=s[:at]+'''-- Base art must survive both final LAB writes and native UpdateButtonArt resets.
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
''' + s[at:]
s=s.replace(" S.TargetFrame=object(S.UIParent)", ''' S.TargetFrame=object(S.UIParent)
 local health=object(S.PlayerFrame)
 S.PlayerFrame.PlayerFrameContent={PlayerFrameContentMain={HealthBarsContainer=health}}
 local buffs=object(S.UIParent);S.BuffFrame=buffs
 buffs.AuraContainer={addIconsToRight=false,iconScale=0.8,iconPadding=3,iconStride=8}
 buffs.UpdateGridLayout=function(self)self.layoutRuns=(self.layoutRuns or 0)+1 end
 buffs.SetPointBase=Methods.SetPoint;buffs.ClearAllPointsBase=Methods.ClearAllPoints
 buffs.ApplySystemAnchor=function(self)self:SetPoint('TOPRIGHT',S.UIParent,'TOPRIGHT',0,0)end
 buffs.OnEditModeExit=nop''')
s=s.replace(" S.CreateFrame=function()events=object();return events end", ''' local prompts={}
 S.CreateFrame=function(_,name,parent)
  local f=object(parent);f.name=name;if name then prompts[#prompts+1]=f else events=f end;return f
 end''')
s=s.replace("eq(cast.points[5],12)", "eq(cast.points[5],12+5/cast:GetEffectiveScale())")
s=s.replace(" S.ConsolePortGroupBase:SetScale(0.94);position()", ''' S.ConsolePortGroupBase:SetScale(0.94);position()
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
 S.BuffFrame=nil;events.scripts.OnEvent(events,'ADDON_LOADED');flush();S.BuffFrame=buffs;events.scripts.OnEvent(events,'ADDON_LOADED');flush();buffPosition()''')
s=s.replace("relative bank anchor, loaded size/skin retained; unit-frame positions unchanged.", "five-pixel raise; left-growing buff layout/edit-mode/combat/late load; two passive targeting prompts; size/skin/unit positions preserved.")
s=s.replace("local settings=im.ImmersionSetup", "local settings=im.ImmersionSetup\nlocal baseY=39.27963256835938")
s=s.replace('eq(talk.bottom,150)', 'eq(talk.bottom,baseY)').replace('eq(talk.offsetY,150)','eq(talk.offsetY,baseY)')
s=s.replace('eq(talk.bottom,282)', 'check(math.abs(talk.bottom-(baseY+132))<1e-8)').replace('eq(talk.bottom,298)', 'check(math.abs(talk.bottom-(baseY+148))<1e-8)')
s=s.replace('native Immersion rest (0,150), reward rise to 282, objective rise to 298, animated return to 150', 'native Immersion rest (0,39.2796), reward/objective rise by 132/148, animated return to the user-selected Y')
(w/'harness.lua').write_text(s,encoding='utf8')
shutil.copy2(old/'evidence/lab-update.lua',w/'evidence/lab-update.lua')
print('Extended real-library/frame-mock harness written.')
