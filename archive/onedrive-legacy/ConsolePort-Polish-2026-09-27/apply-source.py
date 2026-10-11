from pathlib import Path

work = Path(__file__).resolve().parent
root = work/'staged/Interface/AddOns'
def read(p): return p.read_text(encoding='utf8')
def put(p,s):
    with p.open('w', encoding='utf8', newline='\r\n') as f: f.write(s)
def replace(s,a,b,n=1):
    assert s.count(a)==n, (a[:80],s.count(a),n)
    return s.replace(a,b)

p=root/'ConsolePort_Bar/Widget/Group/Group.lua'
s=read(p)
s=replace(s,"local GROUP, GROUP_BUTTON = 'Group', 'GroupButton';", "local GROUP, GROUP_BUTTON = 'Group', 'GroupButton';\n\n"+read(work/'face-skin.lua'))
s=replace(s,"\tMixin(self.cooldown, env.ProxyCooldown):OnLoad()", "\tMixin(self.cooldown, env.ProxyCooldown):OnLoad()\n\tif self.isForeverFaceButton then InstallForeverFaceSkin(self) end;")
s=replace(s,'\t\tif self.msqGroup then\n\t\t\tself.msqGroup:AddButton(button)', '\t\tif self.msqGroup and not button.isForeverFaceButton then\n\t\t\tself.msqGroup:AddButton(button)')
s=replace(s,'\t\tbutton:AddToMasque(self.msqGroup)', '\t\tif not button.isForeverFaceButton then button:AddToMasque(self.msqGroup) end;')
s=replace(s,'\tbutton.Hotkey = Mixin', '\tbutton.isForeverFaceButton = not not (ForeverBanks[parent.id] and ForeverFaceButtons[buttonID]);\n\tif button.isForeverFaceButton then env.LIB.SkinUtility.PreventSkinning(button) end;\n\tbutton.Hotkey = Mixin')
put(p,s)

# Remove the obsolete trial in the unused Cluster path; restore its native skin.
p=root/'ConsolePort_Bar/Widget/Cluster/Cluster.lua';s=read(p)
s=replace(s,'local ForeverFaceButtons = { PAD1 = true; PAD2 = true; PAD3 = true; PAD4 = true };\n','')
s=replace(s,'\tbutton.isForeverFaceButton = modifier == NOMOD and ForeverFaceButtons[buttonID] or false;\n','')
put(p,s)
p=root/'ConsolePort_Bar/Widget/Cluster/Skins.lua';s=read(p)
start=s.index('local CircleMask =');end=s.index('local function SetRotatedMaskTexture')
s=s[:start]+'---------------------------------------------------------------\n\n'+s[end:]
s=replace(s,"\t\tif self.isForeverFaceButton then\n\t\t\tmask:SetTexture(CircleMask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')\n\t\telse\n\t\t\tmask:SetTexture(Assets.MainMask)\n\t\tend",'\t\tmask:SetTexture(Assets.MainMask)')
s=replace(s,'\t\tSetFaceButtonStyle(self, mask, size * offset)\n','')
put(p,s)

p=root/'ConsolePort_Forever/ConsolePort_Forever.lua';s=read(p)
s=replace(s,'local function RefreshForeverHUD()',read(work/'cast-anchor.lua')+'\n\nlocal function RefreshForeverHUD()')
s=replace(s,'    HideBlizzardMenuBar()\nend','    HideBlizzardMenuBar()\n    MovePlayerCastBar()\nend')
put(p,s)

p=root/'ConsolePort/Model/Game/Bindings.lua';s=read(p)
s=replace(s,'\tBindings.DefaultIcons = {', "\tBindings.DefaultIcons = {\n\t\t['CLICK LM_B1:LeftButton']          = 132247; -- LiteMount's declared addon icon")
put(p,s)
print('Staged GroupButton circular skin, retired Cluster trial, cast anchor, and default LiteMount icon.')
