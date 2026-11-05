local _, Addon = ...
Addon.name = "ForeverConfig_Extended"
Addon.version = "0.1.0"
Addon.active = WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT

function Addon:GetAddon(name)
    if type(LibStub) ~= "table" and type(LibStub) ~= "function" then return end
    local ace = LibStub("AceAddon-3.0", true)
    if ace and type(ace.GetAddon) == "function" then return ace:GetAddon(name, true) end
end

function Addon:Database()
    if type(ForeverConfigExtendedDB) ~= "table" then ForeverConfigExtendedDB = {} end
    local db = ForeverConfigExtendedDB
    if type(db.migrations) ~= "table" then db.migrations = {} end
    db.version = self.version
    return db
end

function Addon:PublicCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if not ok or (issecretvalue and issecretvalue(value)) then return end
    if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then return value end
end

function Addon:Snapshot(phase)
    if not self.active then return end
    local db = self:Database()
    local dc = self:GetAddon("DynamicCam")
    local plater = _G.Plater
    local bb = self:GetAddon("BetterBags")
    local backpack = bb and bb.Bags and bb.Bags.Backpack
    local situations = dc and dc.db and dc.db.profile and dc.db.profile.situations
    local enabled, errors = 0, 0
    if type(situations) == "table" then
        for _, situation in pairs(situations) do
            if type(situation) == "table" then
                if situation.enabled then enabled = enabled + 1 end
                if situation.errorEncountered then errors = errors + 1 end
            end
        end
    end
    local status = {
        phase = phase or "runtime",
        at = self:PublicCall(GetTime),
        uiScale = self:PublicCall(GetCVar, "uiScale"),
        useUiScale = self:PublicCall(GetCVar, "useUiScale"),
        whisperMode = self:PublicCall(GetCVar, "whisperMode"),
        nativeModifierToggle = self:PublicCall(GetCVar, "GamepadHudModifierUsesToggle"),
        uiEffectiveScale = UIParent and self:PublicCall(UIParent.GetEffectiveScale, UIParent),
        platerProfile = plater and plater.db and self:PublicCall(plater.db.GetCurrentProfile, plater.db),
        platerScale = plater and plater.db and plater.db.profile and plater.db.profile.ui_parent_scale_tune,
        dynamicCamProfile = dc and dc.db and self:PublicCall(dc.db.GetCurrentProfile, dc.db),
        dynamicCamEnabled = dc and self:PublicCall(dc.IsEnabled, dc),
        dynamicCamEvaluated = dc and dc.enteredSituationAtLogin == true or false,
        dynamicCamSituation = dc and dc.currentSituationID,
        dynamicCamSituations = enabled,
        dynamicCamErrors = errors,
        cameraZoom = self:PublicCall(GetCameraZoom),
        cameraShoulder = self:PublicCall(GetCVar, "test_cameraOverShoulder"),
        betterBagsLoaded = bb ~= nil,
        betterBagsEnabled = bb and self:PublicCall(bb.IsEnabled, bb),
        betterBagsForever = bb and bb.isForever == true or false,
        betterBagsBackpack = backpack ~= nil,
        betterBagsButtons = bb and type(bb._buttons) == "table" or false,
        betterBagsShown = backpack and self:PublicCall(backpack.IsShown, backpack),
        betterBagsBridge = self.bagState and self.bagState.installed or false,
        betterBagsBridgeActions = self.bagState and self.bagState.actions or 0,
    }
    db.addons = {}
    if C_AddOns then
        for _, name in ipairs({"Auctionator", "BetterBags", "BetterBags_Forever", "BtWQuests",
            "DynamicCam", "Immersion", "Immersion_ExtraFade", "ImmersionExtended_Forever",
            "Leatrix_Maps", "Leatrix_Plus", "Leatrix_Sounds", "LiteMount", "Masque", "Pawn", "Plater",
            "Polestar", "Sparkles_Forever"}) do
            db.addons[name] = {
                loaded = self:PublicCall(C_AddOns.IsAddOnLoaded, name),
                version = self:PublicCall(C_AddOns.GetAddOnMetadata, name, "Version"),
            }
        end
    end
    if phase == "logout" then db.logoutStatus = status else db.status = status end
    return status
end

function Addon:PrintStatus()
    local s = self:Snapshot()
    if not s then return end
    print("Forever Config Extended " .. self.version)
    print("Plater: " .. tostring(s.platerProfile) .. ", scale " .. tostring(s.platerScale)
        .. "; UI effective scale " .. tostring(s.uiEffectiveScale))
    print("DynamicCam: " .. tostring(s.dynamicCamProfile) .. ", enabled " .. tostring(s.dynamicCamEnabled)
        .. ", evaluated " .. tostring(s.dynamicCamEvaluated) .. ", situation " .. tostring(s.dynamicCamSituation)
        .. ", enabled situations " .. s.dynamicCamSituations .. ", errors " .. s.dynamicCamErrors)
    print("BetterBags: enabled " .. tostring(s.betterBagsEnabled) .. ", backpack " .. tostring(s.betterBagsBackpack)
        .. ", buttons " .. tostring(s.betterBagsButtons) .. ", shown " .. tostring(s.betterBagsShown)
        .. ", bridge " .. tostring(s.betterBagsBridge) .. ", bridge actions " .. s.betterBagsBridgeActions)
end
