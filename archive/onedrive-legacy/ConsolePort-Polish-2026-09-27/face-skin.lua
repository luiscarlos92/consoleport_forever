-- Forever's saved layout uses GroupButton, not ClusterButton. These sixteen
-- buttons own their art; the remaining group buttons keep their native/Masque skin.
local ForeverBanks = { Base = true; L2 = true; R2 = true; L2R2 = true };
local ForeverFaceButtons = { PAD1 = true; PAD2 = true; PAD3 = true; PAD4 = true };
local ForeverCircle = [[Interface\Masks\CircleMaskScalable]];
local ForeverRing = [[Interface\AddOns\ConsolePort\Assets\Textures\Cursor\RoundBorderHighlight]];

local function SetForeverRoundRegion(texture, button)
	if not texture then return end;
	texture:SetTexture(ForeverRing)
	texture:SetTexCoord(0, 1, 0, 1)
	texture:ClearAllPoints()
	texture:SetPoint('CENTER', button, 'CENTER', 0, 0)
	local size = button:GetWidth();
	texture:SetSize(size, size)
end

local function UpdateForeverFaceButton(self)
	-- LAB calls UpdateLocal after its populated/empty texture update. MasqueSkinned
	-- suppresses LAB's square reset, while the two enrollment guards below prevent
	-- Masque from acquiring these buttons (PreventSkinning alone does NOT do that).
	local mask = env.LIB.SkinUtility.GetIconMask(self);
	mask:SetTexture(ForeverCircle, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
	mask:ClearAllPoints()
	mask:SetPoint('CENTER', self, 'CENTER', 0, 0)
	-- The supplied ring has transparent outer padding; keep the fill inside it.
	local diameter = self:GetWidth() * 0.88;
	mask:SetSize(diameter, diameter)
	self.icon:AddMaskTexture(mask)
	self.icon:SetTexCoord(0, 1, 0, 1)

	local background = env.LIB.SkinUtility.GetSlotBackground(self);
	background:SetColorTexture(0.04, 0.04, 0.04, 0.65)
	background:SetDrawLayer('BACKGROUND', -8)
	background:ClearAllPoints()
	background:SetAllPoints(self.icon)
	background:AddMaskTexture(mask)
	background:Show()
	if self.SlotArt then
		self.SlotArt:SetTexture(nil)
		self.SlotArt:Hide()
	end
	SetForeverRoundRegion(self.NormalTexture, self)
	SetForeverRoundRegion(self.PushedTexture or self:GetPushedTexture(), self)
	SetForeverRoundRegion(self.HighlightTexture or self:GetHighlightTexture(), self)
	SetForeverRoundRegion(self.CheckedTexture or self:GetCheckedTexture(), self)
	SetForeverRoundRegion(self.Flash, self)
	SetForeverRoundRegion(self.Border, self)
	SetForeverRoundRegion(self.NewActionTexture, self)
	SetForeverRoundRegion(self.SpellHighlightTexture, self)
	if self.BorderShadow then self.BorderShadow:SetTexture(nil) end;

	-- Retail creates all three cooldowns in ActionButtonTemplate. Do not alter
	-- timers, colors, numbers or charge drawSwipe; only their outline and bounds.
	for _, key in ipairs({'cooldown', 'chargeCooldown', 'lossOfControlCooldown'}) do
		local cooldown = self[key];
		if cooldown then
			cooldown:ClearAllPoints()
			cooldown:SetAllPoints(mask)
			cooldown:SetSwipeTexture(ForeverCircle)
			cooldown:SetUseCircularEdge(true)
		end
	end
	self.Name:SetWidth(self:GetWidth())
end

local function InstallForeverFaceSkin(self)
	self.UpdateLocal = UpdateForeverFaceButton;
	self.ShowOverlayGlow = env.LIB.RoundGlow.ShowOverlayGlow;
	self.HideOverlayGlow = env.LIB.RoundGlow.HideOverlayGlow;
	-- Native art refreshes can run independently of LAB's UpdateLocal.
	if self.UpdateButtonArt then
		hooksecurefunc(self, 'UpdateButtonArt', UpdateForeverFaceButton)
	end
	self:HookScript('OnSizeChanged', UpdateForeverFaceButton)
	self:UpdateLocal()
end
