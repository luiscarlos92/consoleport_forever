function Update(self)
	if self:HasAction() then
		ActiveButtons[self] = true
		if self._state_type == "action" then
			ActionButtons[self] = true
			NonActionButtons[self] = nil
			if not self.config.actionButtonUI then
				ActionButtonsNonUI[self] = true
			end
		else
			ActionButtons[self] = nil
			NonActionButtons[self] = true
			ActionButtonsNonUI[self] = nil
		end
		self:SetAlpha(1.0)
		UpdateButtonState(self)
		UpdateUsable(self)
		UpdateCooldown(self)
		UpdateFlash(self)
	else
		ActiveButtons[self] = nil
		ActionButtons[self] = nil
		NonActionButtons[self] = nil
		ActionButtonsNonUI[self] = nil
		if gridCounter == 0 and not self.config.showGrid then
			self:SetAlpha(0.0)
		end
		self.cooldown:Hide()
		self:SetChecked(false)

		if ClearActionButtonCooldowns then
			ClearActionButtonCooldowns(self.cooldown, self.chargeCooldown, self.lossOfControlCooldown)
		else
			ClearChargeCooldown(self)
		end

		if self.LevelLinkLockIcon then
			self.LevelLinkLockIcon:SetShown(false)
		end
	end

	-- Add a green border if button is an equipped item
	if self:IsEquipped() and not self.config.hideElements.equipped then
		self.Border:SetVertexColor(0, 1.0, 0, 0.35)
		self.Border:Show()
	else
		self.Border:Hide()
	end

	-- Update Action Text
	if not self:IsConsumableOrStackable() then
		self.Name:SetText(self:GetActionText())
	else
		self.Name:SetText("")
	end

	-- Update icon and hotkey
	local texture = self:GetTexture()

	-- Zone ability button handling
	self.zoneAbilityDisabled = false
	self.icon:SetDesaturated(false)

	if texture then
		self.icon:SetTexture(texture)
		self.icon:Show()
		self.rangeTimer = - 1
		if not self.MasqueSkinned then
			self.SlotBackground:Hide()
			if self.config.hideElements.border then
				self.NormalTexture:SetTexture()
				self.icon:RemoveMaskTexture(self.IconMask)
				self.HighlightTexture:SetSize(52, 51)
				self.HighlightTexture:SetPoint("TOPLEFT", self, "TOPLEFT", -2.5, 2.5)
				self.CheckedTexture:SetSize(52, 51)
				self.CheckedTexture:SetPoint("TOPLEFT", self, "TOPLEFT", -2.5, 2.5)
				self.cooldown:ClearAllPoints()
				self.cooldown:SetAllPoints()
			else
				self:SetNormalAtlas("UI-HUD-ActionBar-IconFrame-AddRow")
				self.icon:AddMaskTexture(self.IconMask)
				self.HighlightTexture:SetSize(46, 45)
				self.HighlightTexture:SetPoint("TOPLEFT")
				self.CheckedTexture:SetSize(46, 45)
				self.CheckedTexture:SetPoint("TOPLEFT")
				self.cooldown:ClearAllPoints()
				self.cooldown:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -2)
				self.cooldown:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -3, 3)
			end
		end
	else
		self.icon:Hide()
		if ClearActionButtonCooldowns then
			ClearActionButtonCooldowns(self.cooldown, self.chargeCooldown, self.lossOfControlCooldown)
		else
			self.cooldown:Hide()
		end
		self.rangeTimer = nil
		if self.HotKey:GetText() == RANGE_INDICATOR then
			self.HotKey:Hide()
		else
			self.HotKey:SetVertexColor(unpack(self.config.text.hotkey.color))
		end
		if not self.MasqueSkinned then
			self.SlotBackground:Show()
			if self.config.hideElements.borderIfEmpty then
				self.NormalTexture:SetTexture()
			else
				self:SetNormalAtlas("UI-HUD-ActionBar-IconFrame-AddRow")
			end
		end
	end

	self:UpdateLocal()

	UpdateCount(self)

	UpdateFlyout(self)

	UpdateOverlayGlow(self)

	UpdateNewAction(self)

	UpdateSpellHighlight(self)

	UpdateAssistedCombatRotationFrame(self)

	UpdatedAssistedHighlightFrame(self)

	if GameTooltip_GetOwnerForbidden() == self then
		UpdateTooltip(self)
	end

	-- this could've been a spec change, need to call OnStateChanged for action buttons, if present
	if not InCombatLockdown() and self._state_type == "action" then
		local onStateChanged = self:GetAttribute("OnStateChanged")
		if onStateChanged then
			self.header:SetFrameRef("updateButton", self)
			self.header:Execute(([[
				local frame = self:GetFrameRef("updateButton")
				control:RunFor(frame, frame:GetAttribute("OnStateChanged"), %s, %s, %s)
			]]):format(formatHelper(self:GetAttribute("state")), formatHelper(self._state_type), formatHelper(self._state_action)))
		end
	end
	lib.callbacks:Fire("OnButtonUpdate", self)
end

