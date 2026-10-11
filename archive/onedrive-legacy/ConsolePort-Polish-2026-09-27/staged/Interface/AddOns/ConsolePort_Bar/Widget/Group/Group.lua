local env, db = CPAPI.GetEnv(...)
---------------------------------------------------------------
local GROUP, GROUP_BUTTON = 'Group', 'GroupButton';

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


---------------------------------------------------------------
local Button = CreateFromMixins(env.ProxyButton, env.ConfigurableWidgetMixin);
---------------------------------------------------------------
do  -- Alpha update closures
	Button.AlphaState = CPAPI.CreateFlagClosures({
		OnCooldown    = 0x02;
		OverlayActive = 0x04;
		MouseOver     = 0x08;
		ShowGrid      = 0x10;
	});
end

function Button:OnMouseMotionFocus()
	self:UpdateAlpha(self.AlphaState.MouseOver, true)
end

function Button:OnMouseMotionClear()
	self:UpdateAlpha(self.AlphaState.MouseOver, false)
end

function Button:OnOverlayGlow(state)
	self:UpdateAlpha(self.AlphaState.OverlayActive, state)
end

function Button:OnCooldownSet(cooldown, _, duration)
	local onCooldown = (cooldown and duration and duration > 2);
	self:UpdateAlpha(self.AlphaState.OnCooldown, onCooldown)
end

function Button:OnCooldownClear()
	self:UpdateAlpha(self.AlphaState.OnCooldown, false)
end

function Button:ForceIgnoreParentAlpha(state)
	self.forceIgnore = state;
	self:UpdateAlpha()
end

function Button:UpdateAlpha(closure, state)
	if closure then
		self.alpha = closure(self.alpha or 0, state);
	end
	local ignoreParentAlpha = self.alpha ~= 0;
	if ( self.forceIgnore ~= nil  ) then
		ignoreParentAlpha = self.forceIgnore;
	end
	self:SetIgnoreParentAlpha(ignoreParentAlpha)
end

function Button:OnLoad()
	env.ProxyButton.OnLoad(self)
	Mixin(self.cooldown, env.ProxyCooldown):OnLoad()
	if self.isForeverFaceButton then InstallForeverFaceSkin(self) end;

	self:SetAttribute('id', self.id)
	self:SetAttribute('flyoutDirection', 'DOWN')
	self:SetAttribute(CPAPI.SkipHotkeyRender, true)

	self:HookScript('OnEnter', self.OnMouseMotionFocus)
	self:HookScript('OnLeave', self.OnMouseMotionClear)
end

function Button:SetProps(props)
	self:SetDynamicProps(props)
	self:OnPropsUpdated()
end

function Button:OnPropsUpdated()
	local props = self.props;
	local pos = props.pos;
	self:ClearAllPoints()
	self:SetPoint(pos.point, self:GetParent(), pos.relPoint, pos.x, pos.y)

	local bindings = env.Manager:GetBindings(self.id);
	if bindings then
		self:SetBindings(bindings)
	end
end

function Button:SetBindings(set)
	local emulation = db.Gamepad.Index.Modifier.Owner[self.id];
	for modifier, binding in pairs(set) do
		if self:IsModifierActive(modifier) then
			if not emulation then
				self:RefreshBinding(modifier, binding)
			else
				self:RefreshBinding(modifier, set[env.ModComplement(modifier, emulation)])
			end
		end
	end
end

function Button:IsModifierActive(modifier)
	return self:GetParent():IsModifierActive(modifier)
end

function Button:ShouldOverrideActionBarBinding()
    return true; -- just return true here, since we already filter by modifier in SetBindings
end

function Button:GetOverrideBinding(modifier)
	return modifier..self.id;
end

function Button:GetSnapSize()
	return 5;
end

function Button:GetEffectiveCombination(state)
	local emulation = db.Gamepad.Index.Modifier.Owner[self.id];
	if emulation then
		return env.ModComplement(state or self:GetAttribute('state'), emulation), self.id;
	end
	return state, self.id;
end

---------------------------------------------------------------
CPGroupBar = Mixin({
---------------------------------------------------------------
	snapToPixels = 5;
	AlphaEvents = {
		ACTIONBAR_SHOWGRID = { Button.AlphaState.ShowGrid, true  };
		ACTIONBAR_HIDEGRID = { Button.AlphaState.ShowGrid, false };
	};
---------------------------------------------------------------
}, CPActionBar, env.MovableWidgetMixin);
---------------------------------------------------------------

function CPGroupBar:OnLoad()
	CPActionBar.OnLoad(self)
	self.buttons   = {};
	self.modifiers = {};

	db:RegisterCallback('OnHintsFocus', self.OnHints, self, false)
	db:RegisterCallback('OnHintsClear', self.OnHints, self, nil)
	env:RegisterCallback('OnNewBindings', self.OnNewBindings, self)
	env:RegisterCallback('OnMasqueLoaded', self.OnMasqueLoaded, self)
	env:RegisterCallbacks(self.OnVariableChanged, self,
		'Settings/disableDND',
		'Settings/showMainIcons',
		'Settings/showCooldownText'
	);
	env:RegisterCallbacks(self.OnHotkeysChanged, self,
		'Settings/groupHotkeySize',
		'Settings/groupHotkeyAnchor',
		'Settings/groupHotkeyRelAnchor',
		'Settings/groupHotkeyOffsetX',
		'Settings/groupHotkeyOffsetY'
	);

	self:RegisterPageResponse([[
		local newstate = ...;
		self:ChildUpdate('actionpage', newstate)
	]])
	self:HookScript('OnEvent', self.OnAlphaEvent)
	for event in pairs(self.AlphaEvents) do
		self:RegisterEvent(event)
	end

	if env.MSQ then
		self:OnMasqueLoaded(env.MSQ)
	end
end

function CPGroupBar:SetProps(props)
	self:SetDynamicProps(props)
	self:OnDriverChanged()
	self:UpdateButtons(props.children or {})
	self:OnVariableChanged()
	CPActionBar.OnDriverChanged(self)
	CPActionBar.OnHierarchyChanged(self)
end

function CPGroupBar:OnPropsUpdated()
	self:SetProps(self.props)
end

function CPGroupBar:OnRelease()
	CPActionBar.OnRelease(self)
	env:Map(GROUP_BUTTON, nil, function(button)
		if ( button:GetParent() == self ) then
			env:Release(button)
		end
	end)
end

function CPGroupBar:UpdateButtons(buttons)
	self:OnRelease()
	wipe(self.buttons)
	for buttonID, props in pairs(buttons) do
		local button = env:Acquire(GROUP_BUTTON, env.MakeID('%s_%s', self:GetName(), buttonID), buttonID, self)
		button:Show()
		button:SetProps(props)
		self.buttons[buttonID] = button;
		if self.msqGroup and not button.isForeverFaceButton then
			self.msqGroup:AddButton(button)
		end
	end
end

function CPGroupBar:OnNewBindings(bindings)
	if not env:IsActive(self) then return end;
	for buttonID, set in pairs(bindings) do
		local button = self.buttons[buttonID];
		if button then
			button:SetBindings(set)
		end
	end
	self:RunAttribute(env.Attributes.OnPage, self:GetAttribute('actionpage'))
	self:RunDriver('modifier')
end

function CPGroupBar:OnDriverChanged()
	local driver = env.ConvertDriver(self.props.modifier);
	wipe(self.modifiers)
	for prefix, condition in env.MapDriver(driver) do
		self.modifiers[prefix] = condition or true;
	end
	self:RegisterModifierDriver(driver, [[
		self:SetAttribute('state', newstate)
		control:ChildUpdate('state', newstate)
		cursor::OwnerChanged(self:GetName())
	]])
end

function CPGroupBar:IsModifierActive(modifier)
	return not not self.modifiers[modifier];
end

function CPGroupBar:OnHints(state)
	for _, button in pairs(self.buttons) do
		button:ForceIgnoreParentAlpha(state)
	end
end

function CPGroupBar:OnAlphaEvent(event)
	local eventClosure = self.AlphaEvents[event];
	if eventClosure then
		local closure, state = unpack(eventClosure);
		for _, button in pairs(self.buttons) do
			button:UpdateAlpha(closure, state)
		end
	end
end

function CPGroupBar:OnVariableChanged()
	local disableDND       = env('disableDND')
	local showMainIcons    = env('showMainIcons')
	for _, button in pairs(self.buttons) do
		button:DisableDragNDrop(disableDND)
		button.Hotkey:SetShown(showMainIcons)
	end
end

function CPGroupBar:OnHotkeysChanged()
	local size, atlasSize = env('groupHotkeySize'), env('groupHotkeySize') * 0.6;
	local point, relPoint, x, y =
		env('groupHotkeyAnchor'),
		env('groupHotkeyRelAnchor'),
		env('groupHotkeyOffsetX'),
		env('groupHotkeyOffsetY');
	for _, button in pairs(self.buttons) do
		button.Hotkey:ClearAllPoints()
		button.Hotkey:SetPoint(point, button, relPoint, x, y)
		button.Hotkey:SetIconSize(size)
		button.Hotkey:SetAtlasSize(atlasSize)
		button.Hotkey:OnIconsChanged()
	end
end

function CPGroupBar:OnMasqueLoaded(msq)
	local groupID = ('%s: %s'):format(YELLOW_FONT_COLOR:WrapTextInColorCode(GROUP), self.id)
	self.msqGroup = msq:Group('ConsolePort', groupID)
	for _, button in pairs(self.buttons) do
		if not button.isForeverFaceButton then button:AddToMasque(self.msqGroup) end;
	end
end

---------------------------------------------------------------
-- Group bar factory
---------------------------------------------------------------
env:AddFactory(GROUP, function(id)
	local frame = CreateFrame('Frame', env.MakeID('ConsolePortGroup%s', id), env.Manager, 'CPGroupBar')
	frame.id = id;
	frame:OnLoad()
	return frame;
end, env.Interface.Group)

env:AddFactory(GROUP_BUTTON, function(id, buttonID, parent)
	local button = Mixin(env.LAB:CreateButton(buttonID, id, parent, env.Button:GetConfig()), Button)
	button.isForeverFaceButton = not not (ForeverBanks[parent.id] and ForeverFaceButtons[buttonID]);
	if button.isForeverFaceButton then env.LIB.SkinUtility.PreventSkinning(button) end;
	button.Hotkey = Mixin(CreateFrame('Frame', nil, button), env.ProxyHotkey)
	button.Hotkey.icon = button.Hotkey:CreateTexture(nil, 'OVERLAY', nil, 7)
	button.Hotkey.icon:SetAllPoints()
	button.Hotkey:OnLoad(buttonID, env('groupHotkeySize'), env('groupHotkeySize') * 0.6, {
		env('groupHotkeyAnchor'), button, env('groupHotkeyRelAnchor'),
		env('groupHotkeyOffsetX'), env('groupHotkeyOffsetY')
	});
	button:OnLoad()
	return button;
end)