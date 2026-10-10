local _,Addon=...
local Core,Repair=Addon.Core,{VERSION=1,FIELD='shared/integration/immersionProgressRepairVersion'}
Addon.ImmersionProgress=Repair
local function writable(api)
    return not api.InCombatLockdown() and not (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown())
end
function Repair:Probe(api)
    local frame=api.ImmersionFrame
    local talk=frame and frame.TalkBox
    local progress=talk and talk.Elements and talk.Elements.Progress
    if not api.C_AddOns or api.C_AddOns.GetAddOnMetadata('Immersion','Version')~='1.4.61'
        or not api.C_AddOns.IsAddOnLoaded('Immersion') or type(api.ImmersionSetup)~='table'
        or type(api.RunNextFrame)~='function' or type(api.hooksecurefunc)~='function'
        or type(api.InCombatLockdown)~='function' or type(api.GetQuestID)~='function'
        or not frame or type(frame.QUEST_PROGRESS)~='function' or type(frame.OnEvent)~='function'
        or type(frame.HookScript)~='function' or type(frame.IsShown)~='function'
        or not talk or type(talk.SetExtraOffset)~='function' or type(talk.IsVisible)~='function'
        or not progress or type(talk.Elements.IsShown)~='function' or type(progress.GetSize)~='function'
        or type(progress.IsShown)~='function' then
        return nil,'qualified Immersion Required Items layout unavailable'
    end
    return frame
end
function Repair:Eligible(frame)
    local owner,api=self.owner,self.api
    if not owner or not api or owner.busy or not owner:IsCharacterInstalled() or not writable(api)
        or owner.db.shared.integrationPolicy.immersionProgressRepairVersion~=self.VERSION
        or api.ImmersionFrame~=frame or not self:Probe(api) or not frame:IsShown()
        or frame.lastEvent~='QUEST_PROGRESS' or frame.TalkBox.lastEvent~='QUEST_PROGRESS' then return false end
    local cfg,talk=api.ImmersionSetup,frame.TalkBox
    if type(cfg.boxpoint)~='string' or not cfg.boxpoint:match('Bottom')
        or type(cfg.anidivisor)~='number' or cfg.anidivisor<=0 or cfg.nameplatemode
        or type(cfg.elementscale)~='number' or cfg.elementscale<=0 or cfg.elementscale~=cfg.elementscale or cfg.elementscale>=math.huge
        or not talk:IsVisible() or not talk.Elements:IsShown() or not talk.Elements.Progress:IsShown() then return false end
    return true
end
function Repair:Queue(frame)
    self.serial=(self.serial or 0)+1
    local serial,api=self.serial,self.api
    local quest=api.GetQuestID and api.GetQuestID()
    -- Immersion measures children synchronously and again next frame. Wait
    -- beyond that second measurement; never replace its event/layout methods.
    api.RunNextFrame(function() api.RunNextFrame(function()
        if serial~=self.serial or not self:Eligible(frame)
            or (api.GetQuestID and api.GetQuestID()~=quest) then return end
        local _,height=frame.TalkBox.Elements.Progress:GetSize()
        if type(height)~='number' or height~=height or height<=1 or height==math.huge then return end
        local offset=(height+48)*api.ImmersionSetup.elementscale
        if type(frame.TalkBox.extraY)=='number' and math.abs(frame.TalkBox.extraY-offset)<0.3 then return end
        frame.TalkBox:SetExtraOffset(offset)
    end) end)
end
function Repair:Refresh(owner,api)
    self.owner,self.api=owner,api
    local frame,reason=self:Probe(api)
    if not frame or not owner:IsCharacterInstalled() then return false,reason or 'configuration not accepted' end
    if not writable(api) or owner.busy then return false,'Required Items repair waits for combat and Edit Mode to end' end
    local policy=owner.db.shared.integrationPolicy
    if policy.immersionProgressRepairVersion==nil and not owner.db.managedFields[self.FIELD] then
        local adapter=owner.adapters.immersionProgress
        if not adapter then return false,'Forever repair policy adapter unavailable' end
        -- A single backed-up Forever-owned field. Never rerun the installer or
        -- touch ImmersionSetup, Edit Mode, bindings, rings or action slots.
        local step={id=self.FIELD,scope='immersionProgress',path={'immersionProgressRepairVersion'},
            before=Core.Encode(nil),value=self.VERSION,revision=owner.CONFIG_REVISION}
        local journal=Addon.Transactions.Prepare(owner.db,owner.guid,{step},{immersionProgressRepair=true})
        local ok,error=Addon.Transactions.Apply(journal,{immersionProgress=adapter},function() return writable(api) and not owner.busy end)
        if not ok then return false,error end
        Addon.Transactions.Commit(owner.db,journal,owner.record.appliedRevision)
    end
    if policy.immersionProgressRepairVersion~=self.VERSION then return false,'Required Items repair disabled or restored; policy preserved' end
    self.hooked=self.hooked or setmetatable({},{__mode='k'})
    if not self.hooked[frame] then
        self.hooked[frame]=true
        api.hooksecurefunc(frame,'QUEST_PROGRESS',function() self:Queue(frame) end)
        api.hooksecurefunc(frame,'OnEvent',function()
            if frame.lastEvent~='QUEST_PROGRESS' then self.serial=(self.serial or 0)+1 end
        end)
        frame:HookScript('OnHide',function() self.serial=(self.serial or 0)+1 end)
    end
    -- Retry an eligible open progress dialog after a combat/Edit Mode deferral.
    if self:Eligible(frame) then
        local _,height=frame.TalkBox.Elements.Progress:GetSize()
        if type(height)=='number' and height>1 and height<math.huge
            and (type(frame.TalkBox.extraY)~='number' or math.abs(frame.TalkBox.extraY-(height+48)*api.ImmersionSetup.elementscale)>=0.3) then
            self:Queue(frame)
        end
    end
    return true,'Required Items offset refreshed after native layout; Immersion settings preserved'
end
