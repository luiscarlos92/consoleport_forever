-- Anchor/scaling model, running the actual presentation and fitting code.
-- This checks physical rectangles, not just SetPoint argument strings.
local Frame={}
local rootScale,screenW,screenH=1,1920,1080
local axes={BOTTOMLEFT={0,0},BOTTOM={.5,0},BOTTOMRIGHT={1,0},LEFT={0,.5},CENTER={.5,.5},RIGHT={1,.5},TOPLEFT={0,1},TOP={.5,1},TOPRIGHT={1,1}}
function Frame:GetEffectiveScale() return (self.parent and self.parent:GetEffectiveScale() or rootScale)*(self.scale or 1) end
function Frame:SetPoint(a,b,c,x,y) self.point={a,b,c,x or 0,y or 0} end
function Frame:ClearAllPoints() self.point=nil end
function Frame:SetSize(w,h) self.width,self.height=w,h end
function Frame:GetWidth() return self.width end function Frame:GetHeight() return self.height end
function Frame:GetParent() return self.parent end
function Frame:SetScale(s) self.scale=s end
function Frame:GetScale() return self.scale or 1 end
function Frame:SetParent(p) self.parent=p end
function Frame:SetTexture(t) self.texture=t end function Frame:SetAtlas(t) self.atlas=t end
function Frame:SetTexCoord() end function Frame:SetAlpha(a) self.alpha=a end
function Frame:SetText(t) self.width,self.height=8,16 end function Frame:SetTextColor() end
function Frame:Show() self.shown=true end function Frame:Hide() self.shown=false end
function Frame:IsShown() return self.shown end function Frame:SetIgnoreParentAlpha() end
function Frame:GetPixels()
    if self==UIParent then return 0,0,screenW,screenH end
    local p=assert(self.point,'missing anchor')
    local left,bottom,rw,rh=p[2]:GetPixels()
    local ra,sa=axes[p[3]],axes[p[1]]
    local s=self:GetEffectiveScale()
    local w,h=self.width*s,self.height*s
    return left+rw*ra[1]+p[4]*s-w*sa[1],bottom+rh*ra[2]+p[5]*s-h*sa[2],w,h
end
function Frame:GetRect()
    local x,y,w,h=self:GetPixels() local s=self:GetEffectiveScale()
    return x/s,y/s,w/s,h/s
end
function Frame:SetAllPoints() end function Frame:AddMaskTexture() end
function Frame:CreateTexture() return setmetatable({parent=self,shown=true},{__index=Frame}) end
function Frame:CreateMaskTexture() return self:CreateTexture() end
function Frame:CreateFontString() return self:CreateTexture() end
function CreateFrame(_,_,parent) return setmetatable({parent=parent or UIParent,shown=true},{__index=Frame}) end
function InCombatLockdown() return false end
UIParent=setmetatable({shown=true,width=screenW,height=screenH},{__index=Frame})
local device={Label='SHP',GetIconForButton=function(_,id) return id,false end}
local db={Gamepad={GetActiveDevice=function() return device end,Index={Modifier={Key={SHIFT='PADLTRIGGER',CTRL='PADRTRIGGER'}}}}}
Addon.adapters={consoleport={api={version='3.3.10'},db=db},rings={api={classSet='Auras',classChord=Addon.ClassActions.LEFT_CHORD},rings={Data={Auras={{type='spell',spell=101}}},GetBindingForSet=function() return 'CLICK Class:Auras' end}}}
function GetBindingAction() return 'CLICK Class:Auras' end
function GetNumShapeshiftForms() return 1 end function GetShapeshiftFormInfo() return 1,true,true,101 end
C_Spell={GetSpellTexture=function() return 101 end}
--@PRODUCT_HUD
local HUD=Addon.HUDPresentation
-- Exact CP rectangle scaling contract; only GetRect and scale are host doubles.
local BOUNDS={}
local function GetRect(f) return f:GetRect() end
local function GetEffectiveScale(f) return f:GetEffectiveScale() end
local function GetHitRectInsets() return 0,0,0,0 end
local function issecret() return false end
--@NATIVE_SCALED_RECT
local cells={PAD1={195,-45},PAD2={240,0},PAD3={150,0},PAD4={195,45},PADDLEFT={-7.5,0},PADDUP={37.5,45},PADDRIGHT={82.5,0},PADDDOWN={37.5,-45}}
local BUTTON_SIZE=45 -- Exact pinned Blizzard ActionButtonTemplate dimensions.
local function layout(spread,bottomY,baseY,active)
    for _,id in ipairs({'Base','L2','R2','L2R2'}) do
        local x=id=='L2' and -spread or id=='R2' and spread or 0
        local y=id=='Base' and baseY or id=='L2R2' and bottomY or 80
        local bank=CreateFrame('Frame',nil,UIParent)
        bank:SetSize(277.5,140) bank.scale=id==active and 1.06 or .94
        bank.props={rescale='[mod:SHIFT] 106; 94',pos={point='BOTTOM',relPoint='BOTTOM',x=x,y=y}}
        bank.buttons={} _G['ConsolePortGroup'..id]=bank
        HUD.PlaceBank(bank)
        for key,pos in pairs(cells) do
            local button=CreateFrame('Button',nil,bank) button:SetSize(BUTTON_SIZE,BUTTON_SIZE)
            button:SetPoint('LEFT',bank,'LEFT',pos[1],pos[2]) bank.buttons[key]=button
        end
        HUD.BankPrompt(bank,id)
    end
    HUD.PlaceBank(ConsolePortGroupBase) -- All native child dimensions are ready.
    HUD.ClassShortcut(ConsolePortGroupBase)
end
local function checkRect(frame,name,shadow)
    local r=assert(HUD.Rect(frame))
    r.name=name
    assert(r.x-(shadow or 0)>=0 and r.y-(shadow or 0)>=0 and r.x+r.w+(shadow or 0)<=UIParent:GetWidth() and r.y+r.h+(shadow or 0)<=UIParent:GetHeight(),name..' out of screen')
    local x,y,w,h=GetHitRectScaled(frame)
    assert(math.abs(r.x-x)<.0001 and math.abs(r.y-y)<.0001 and math.abs(r.w-w)<.0001 and math.abs(r.h-h)<.0001,'scale differs from native CP')
    return r
end
local cases=0
local fixedHints={}
for _,resolution in ipairs({{1280,720},{1366,768},{1920,1080},{2560,1440},{3840,2160}}) do
    for _,scale in ipairs({.64,.84,1}) do
        rootScale=scale screenW,screenH=resolution[1],resolution[2]
        UIParent:SetSize(screenW/scale,screenH/scale) BOUNDS.z=scale
        for _,positions in ipairs({{270,5,160},{315,10,150}}) do
            for _,active in ipairs({'Base','L2','R2','L2R2'}) do
                layout(positions[1],positions[2],positions[3],active)
                assert(HUD.LayoutGuard(),'no clear placement '..screenW..' '..rootScale..' '..active)
                local identity=table.concat({screenW,screenH,rootScale,positions[1],positions[2],positions[3]},':')
                for _,id in ipairs({'L2','R2'}) do
                    local rect=HUD.Rect(_G['ConsolePortGroup'..id].__cpfBankPrompt)
                    local key=identity..id local prior=fixedHints[key]
                    if prior then assert(math.abs(rect.x-prior.x)<.001 and math.abs(rect.y-prior.y)<.001,'trigger prompt jumps with selected bank '..id..' active='..active..' x='..rect.x..' y='..rect.y..' prior='..prior.x..','..prior.y)
                    else fixedHints[key]=rect end
                end
                local buttons,decorations={},{}
                for _,id in ipairs({'Base','L2','R2','L2R2'}) do
                    local bank=_G['ConsolePortGroup'..id]
                    for key,button in pairs(bank.buttons) do buttons[#buttons+1]=checkRect(button,id..key,2) end
                    if bank.__cpfBankPrompt then decorations[#decorations+1]=checkRect(bank.__cpfBankPrompt,id..' prompt') end
                end
                local badge=ConsolePortGroupBase.__cpfClassShortcut
                decorations[#decorations+1]=checkRect(badge,'class icon')
                decorations[#decorations+1]=checkRect(badge.prompt,'complete class prompt')
                for _,hint in ipairs(decorations) do
                    for _,button in ipairs(buttons) do assert(not HUD.Overlap(hint,button,2),'hint overlaps spell cell') end
                end
                for i,hint in ipairs(decorations) do for j=i+1,#decorations do assert(not HUD.Overlap(hint,decorations[j]),'decorations overlap') end end
                for i,button in ipairs(buttons) do for j=i+1,#buttons do
                    local other=buttons[j]
                    assert(not HUD.Overlap(button,other),'native banks overlap '..button.name..' '..other.name..' active='..active..' dx='..(math.min(button.x+button.w,other.x+other.w)-math.max(button.x,other.x))..' dy='..(math.min(button.y+button.h,other.y+other.h)-math.max(button.y,other.y)))
                end end
                cases=cases+1
            end
        end
    end
end
assert(cases==120)
-- Deliberately recreate a clipped label, then collide it with a spell. The
-- runtime guard must fit both situations without moving any gameplay cell.
rootScale=1 screenW,screenH=1920,1080 UIParent:SetSize(screenW,screenH) BOUNDS.z=1
layout(270,5,160,'Base')
local combo=ConsolePortGroupL2R2.__cpfBankPrompt
combo:ClearAllPoints() combo:SetPoint('TOP',ConsolePortGroupL2R2,'BOTTOM',0,-2)
assert(HUD.Rect(combo).y<0,'old clipped prompt not reproduced')
assert(HUD.LayoutGuard()) checkRect(combo,'recovered clipped prompt')
combo:ClearAllPoints() combo:SetPoint('CENTER',ConsolePortGroupL2R2.buttons.PAD1,'CENTER',0,0)
assert(HUD.Overlap(HUD.Rect(combo),HUD.Rect(ConsolePortGroupL2R2.buttons.PAD1)),'collision not reproduced')
local cell=HUD.Rect(ConsolePortGroupL2R2.buttons.PAD1)
assert(HUD.LayoutGuard()) assert(not HUD.Overlap(HUD.Rect(combo),cell,2))
local after=HUD.Rect(ConsolePortGroupL2R2.buttons.PAD1)
assert(cell.x==after.x and cell.y==after.y,'fitting moved gameplay')
TEST_SUCCESS=true
