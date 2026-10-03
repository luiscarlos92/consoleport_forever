local MAJOR, MINOR = "LibMountInfo-1.1", 3;
local LibMountInfo = LibStub:NewLibrary(MAJOR, MINOR);

if not LibMountInfo then
  return
end


-- API Cache
local C_MountJournal_GetCollectedFilterSetting = C_MountJournal.GetCollectedFilterSetting
local C_MountJournal_GetDisplayedMountInfo = C_MountJournal.GetDisplayedMountInfo
local C_MountJournal_GetMountIDs = C_MountJournal.GetMountIDs
local C_MountJournal_GetMountInfoByID = C_MountJournal.GetMountInfoByID
local C_MountJournal_GetNumDisplayedMounts = C_MountJournal.GetNumDisplayedMounts
local C_MountJournal_IsSourceChecked = C_MountJournal.IsSourceChecked
local C_MountJournal_IsTypeChecked = C_MountJournal.IsTypeChecked
local C_MountJournal_IsValidSourceFilter = C_MountJournal.IsValidSourceFilter
local C_MountJournal_IsValidTypeFilter = C_MountJournal.IsValidTypeFilter
local C_MountJournal_SetCollectedFilterSetting = C_MountJournal.SetCollectedFilterSetting
local C_MountJournal_SetDefaultFilters = C_MountJournal.SetDefaultFilters
local C_MountJournal_SetSourceFilter = C_MountJournal.SetSourceFilter
local C_MountJournal_SetTypeFilter = C_MountJournal.SetTypeFilter

local C_PetJournal_GetNumPetSources = C_PetJournal.GetNumPetSources

local Enum_MountTypeMeta_NumValues = Enum.MountTypeMeta.NumValues

local LE_MOUNT_JOURNAL_FILTER_COLLECTED     = LE_MOUNT_JOURNAL_FILTER_COLLECTED
local LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED = LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED
local LE_MOUNT_JOURNAL_FILTER_UNUSABLE      = LE_MOUNT_JOURNAL_FILTER_UNUSABLE

local IsMounted = IsMounted
local GetRealmName = GetRealmName
local UnitName = UnitName
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local pairs = pairs


-- Storage
LibMountInfo.flyingMounts = LibMountInfo.flyingMounts or {}
LibMountInfo.lastMount = LibMountInfo.lastMount or {}  -- { flying = mountID, notFlying = mountID, last = mostRecentMountID (either flying or non-flying) }
LibMountInfo.callbacks = LibMountInfo.callbacks or {}  -- { onMountChanged = {}, onFlyingMountsUpdated = {} }
LibMountInfo.ignoredMounts = LibMountInfo.ignoredMounts or {}  -- Set of mountIDs to ignore for "last mount" tracking
LibMountInfo.trackingPaused = false  -- When true, last mount tracking is suspended

-- Per-character persistent storage (to be set by addons that have saved variables)
-- Expected format: savedVarTable[realmName][playerName] = mountID
LibMountInfo.persistentStorage = nil
LibMountInfo.currentRealm = nil
LibMountInfo.currentPlayer = nil


-- Helper function to store current mount journal filters
local function StoreCurrentFilters()
  local collectedFilters = {}
  collectedFilters[LE_MOUNT_JOURNAL_FILTER_COLLECTED] = C_MountJournal_GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED)
  collectedFilters[LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED] = C_MountJournal_GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED)
  collectedFilters[LE_MOUNT_JOURNAL_FILTER_UNUSABLE] = C_MountJournal_GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE)

  local typeFilters = {}
  for filterIndex = 1, Enum_MountTypeMeta_NumValues do
    if C_MountJournal_IsValidTypeFilter(filterIndex) then
      typeFilters[filterIndex] = C_MountJournal_IsTypeChecked(filterIndex)
    end
  end

  local sourceFilters = {}
  for filterIndex = 1, C_PetJournal_GetNumPetSources() do
    if C_MountJournal_IsValidSourceFilter(filterIndex) then
      sourceFilters[filterIndex] = C_MountJournal_IsSourceChecked(filterIndex)
    end
  end

  return collectedFilters, typeFilters, sourceFilters
end


-- Helper function to restore mount journal filters
local function RestoreFilters(collectedFilters, typeFilters, sourceFilters)
  if collectedFilters[LE_MOUNT_JOURNAL_FILTER_COLLECTED] ~= C_MountJournal_GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED) then
    C_MountJournal_SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, collectedFilters[LE_MOUNT_JOURNAL_FILTER_COLLECTED])
  end
  if collectedFilters[LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED] ~= C_MountJournal_GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED) then
    C_MountJournal_SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, collectedFilters[LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED])
  end
  if collectedFilters[LE_MOUNT_JOURNAL_FILTER_UNUSABLE] ~= C_MountJournal_GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE) then
    C_MountJournal_SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, collectedFilters[LE_MOUNT_JOURNAL_FILTER_UNUSABLE])
  end

  for filterIndex = 1, Enum_MountTypeMeta_NumValues do
    if C_MountJournal_IsValidTypeFilter(filterIndex) and typeFilters[filterIndex] ~= C_MountJournal_IsTypeChecked(filterIndex) then
      C_MountJournal_SetTypeFilter(filterIndex, typeFilters[filterIndex])
    end
  end

  for filterIndex = 1, C_PetJournal_GetNumPetSources() do
    if C_MountJournal_IsValidSourceFilter(filterIndex) and sourceFilters[filterIndex] ~= C_MountJournal_IsSourceChecked(filterIndex) then
      C_MountJournal_SetSourceFilter(filterIndex, sourceFilters[filterIndex])
    end
  end
end


-- Build the list of flying mounts
function LibMountInfo:UpdateFlyingMounts()
  -- Store current filters
  local collectedFilters, typeFilters, sourceFilters = StoreCurrentFilters()

  -- Set filters to show only flying mounts
  C_MountJournal_SetDefaultFilters()
  C_MountJournal_SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, true)  -- Include unusable
  C_MountJournal_SetTypeFilter(1, false)   -- No Ground
  C_MountJournal_SetTypeFilter(3, false)   -- No Aquatic
  -- Filter index 5 is "Ride Along", which is automatically flying, so we can ignore it

  -- Fill list of flying mount IDs
  LibMountInfo.flyingMounts = {}
  for displayIndex = 1, C_MountJournal_GetNumDisplayedMounts() do
    local mountId = select(12, C_MountJournal_GetDisplayedMountInfo(displayIndex))
    LibMountInfo.flyingMounts[mountId] = true
  end

  -- Restore original filters
  RestoreFilters(collectedFilters, typeFilters, sourceFilters)

  -- Fire callbacks
  if LibMountInfo.callbacks.onFlyingMountsUpdated then
    for _, callback in pairs(LibMountInfo.callbacks.onFlyingMountsUpdated) do
      callback()
    end
  end
end


-- Get the currently active mount ID (if mounted)
-- Returns mountID, isFlying
function LibMountInfo:GetCurrentMount()
  if not IsMounted() then
    return nil, false
  end

  -- Don't update lastMount if player is dead
  local playerIsDead = UnitIsDeadOrGhost("player")

  -- Check last flying mount first for efficiency
  if LibMountInfo.lastMount.flying then
    if LibMountInfo.flyingMounts[LibMountInfo.lastMount.flying] ~= true then
      -- Sanity check failed: cached "flying" mount is not actually a flying mount. Clear the bad cache entry.
      LibMountInfo.lastMount.flying = nil
    else
      local _, _, _, active = C_MountJournal_GetMountInfoByID(LibMountInfo.lastMount.flying)
      if active then
        -- Update 'last' field when using cached flying mount (unless tracking is paused or mount is ignored or player is dead)
        local mountID = LibMountInfo.lastMount.flying
        if not LibMountInfo.ignoredMounts[mountID] and not LibMountInfo.trackingPaused and not playerIsDead then
          LibMountInfo.lastMount.last = mountID
          if LibMountInfo.persistentStorage and LibMountInfo.currentRealm and LibMountInfo.currentPlayer then
            local storage = LibMountInfo.persistentStorage[LibMountInfo.currentRealm][LibMountInfo.currentPlayer]
            if type(storage) == "table" then
              storage.last = mountID
            end
          end
        end
        return mountID, true
      end
    end
  end

  -- Check last non-flying mount
  if LibMountInfo.lastMount.notFlying then
    if LibMountInfo.flyingMounts[LibMountInfo.lastMount.notFlying] == true then
      -- Sanity check failed: cached "notFlying" mount is actually a flying mount. Clear the bad cache entry.
      LibMountInfo.lastMount.notFlying = nil
    else
      local _, _, _, active = C_MountJournal_GetMountInfoByID(LibMountInfo.lastMount.notFlying)
      if active then
        -- Update 'last' field when using cached non-flying mount (unless tracking is paused or mount is ignored or player is dead)
        local mountID = LibMountInfo.lastMount.notFlying
        if not LibMountInfo.ignoredMounts[mountID] and not LibMountInfo.trackingPaused and not playerIsDead then
          LibMountInfo.lastMount.last = mountID
          if LibMountInfo.persistentStorage and LibMountInfo.currentRealm and LibMountInfo.currentPlayer then
            local storage = LibMountInfo.persistentStorage[LibMountInfo.currentRealm][LibMountInfo.currentPlayer]
            if type(storage) == "table" then
              storage.last = mountID
            end
          end
        end
        return mountID, false
      end
    end
  end

  -- Must search for the active mount
  for _, mountID in pairs(C_MountJournal_GetMountIDs()) do
    local _, _, _, active = C_MountJournal_GetMountInfoByID(mountID)
    if active then
      -- print("Current Mount:", mountID)
    
      local isFlying = LibMountInfo.flyingMounts[mountID] == true
      
      -- Check if this mount should be ignored (utility mounts like Yak, Brutosaur, etc.)
      -- Also check if tracking is paused (e.g., during race starting countdown)
      -- Also check if player is dead
      local shouldIgnore = LibMountInfo.ignoredMounts[mountID] == true or LibMountInfo.trackingPaused or playerIsDead
      
      -- Cache the result (but don't update persistent storage if ignored)
      if isFlying then
        if not shouldIgnore then
          LibMountInfo.lastMount.flying = mountID
          LibMountInfo.lastMount.last = mountID
          
          -- Also store in persistent storage if available
          if LibMountInfo.persistentStorage and LibMountInfo.currentRealm and LibMountInfo.currentPlayer then
            local storage = LibMountInfo.persistentStorage[LibMountInfo.currentRealm][LibMountInfo.currentPlayer]
            if type(storage) == "table" then
              storage.flying = mountID
              storage.last = mountID
            end
          end
        end
      else
        if not shouldIgnore then
          LibMountInfo.lastMount.notFlying = mountID
          LibMountInfo.lastMount.last = mountID
          
          -- Also store in persistent storage if available
          if LibMountInfo.persistentStorage and LibMountInfo.currentRealm and LibMountInfo.currentPlayer then
            local storage = LibMountInfo.persistentStorage[LibMountInfo.currentRealm][LibMountInfo.currentPlayer]
            if type(storage) == "table" then
              storage.notFlying = mountID
              storage.last = mountID
            end
          end
        end
      end
      
      return mountID, isFlying
    end
  end

  return nil, false
end


-- Set up persistent storage for cross-session mount tracking
-- savedVarTable: A saved variable table with structure [realmName][playerName] = { flying = mountID, notFlying = mountID, last = mostRecentMountID }
-- The 'last' field stores whichever mount (flying or non-flying) was used most recently
function LibMountInfo:SetPersistentStorage(savedVarTable)
  LibMountInfo.persistentStorage = savedVarTable
  
  if not LibMountInfo.currentRealm or not LibMountInfo.currentPlayer then
    return
  end
  
  -- Initialize structure if needed
  if savedVarTable then
    savedVarTable[LibMountInfo.currentRealm] = savedVarTable[LibMountInfo.currentRealm] or {}
    
    -- Support both old format (single mountID) and new format (table with flying/notFlying/last)
    local stored = savedVarTable[LibMountInfo.currentRealm][LibMountInfo.currentPlayer]
    
    if type(stored) == "number" then
      -- Old format: single mountID, assume it's a flying mount
      if LibMountInfo.flyingMounts[stored] then
        LibMountInfo.lastMount.flying = stored
        LibMountInfo.lastMount.last = stored
      end
      -- Migrate to new format
      savedVarTable[LibMountInfo.currentRealm][LibMountInfo.currentPlayer] = {
        flying = LibMountInfo.flyingMounts[stored] and stored or nil,
        last = stored
      }
    elseif type(stored) == "table" then
      -- New format: table with flying and notFlying
      if stored.flying and LibMountInfo.flyingMounts[stored.flying] then
        LibMountInfo.lastMount.flying = stored.flying
      end
      if stored.notFlying and LibMountInfo.flyingMounts[stored.notFlying] ~= true then
        LibMountInfo.lastMount.notFlying = stored.notFlying
      end
      if stored.last then
        LibMountInfo.lastMount.last = stored.last
      end
    else
      -- Initialize new format
      savedVarTable[LibMountInfo.currentRealm][LibMountInfo.currentPlayer] = {}
    end
  end
end


-- Get the last used flying mount ID (nil if none)
function LibMountInfo:GetLastFlyingMount()
  return LibMountInfo.lastMount.flying
end


-- Get the last used non-flying mount ID (nil if none)
function LibMountInfo:GetLastNonFlyingMount()
  return LibMountInfo.lastMount.notFlying
end


-- Get the most recently used mount ID (nil if none)
function LibMountInfo:GetLastMount()
  return LibMountInfo.lastMount.last
end


-- Check if a specific mount ID is a flying mount
function LibMountInfo:IsFlyingMount(mountID)
  return LibMountInfo.flyingMounts[mountID] == true
end


-- Check if the current mount can fly
function LibMountInfo:CurrentMountCanFly()
  local mountID, isFlying = self:GetCurrentMount()
  return isFlying
end


-- Check if currently using Skyriding (Dynamic Flight) vs Steady Flight
-- Returns: true if skyriding, false if steady flight or not mounted on flying mount
function LibMountInfo:IsSkyriding()
  if not IsMounted() then
    return false
  end
  
  local mountID, isFlying = self:GetCurrentMount()
  if not isFlying then
    return false
  end
  
  -- Check if mount has steady flight enabled (13th return value)
  local _, _, _, _, _, _, _, _, _, _, _, _, isSteadyFlight = C_MountJournal_GetMountInfoByID(mountID)
  
  -- If not steady flight, then it's skyriding (for flying mounts)
  return not isSteadyFlight
end


-- Set which mounts should be ignored for "last mount" tracking
-- mountIDs: comma-separated string of mount IDs (e.g., "460, 284") or table of mount IDs
-- Use this to ignore utility mounts like Yak (122708) or Brutosaur (1173851)
function LibMountInfo:SetIgnoredMounts(mountIDs)
  LibMountInfo.ignoredMounts = {}
  
  if type(mountIDs) == "string" then
    -- Parse comma-separated string
    for idStr in string.gmatch(mountIDs, "%d+") do
      local id = tonumber(idStr)
      if id then
        LibMountInfo.ignoredMounts[id] = true
      end
    end
  elseif type(mountIDs) == "table" then
    -- Direct table of IDs
    for _, id in pairs(mountIDs) do
      if type(id) == "number" then
        LibMountInfo.ignoredMounts[id] = true
      end
    end
  end
end


-- Get the current list of ignored mount IDs as a table
function LibMountInfo:GetIgnoredMounts()
  local result = {}
  for mountID, _ in pairs(LibMountInfo.ignoredMounts) do
    table.insert(result, mountID)
  end
  return result
end


-- Pause last mount tracking
-- Use this when you don't want automatic mount changes (e.g., race starting mounts) to be recorded
function LibMountInfo:PauseTracking()
  LibMountInfo.trackingPaused = true
end


-- Resume last mount tracking
function LibMountInfo:ResumeTracking()
  LibMountInfo.trackingPaused = false
end


-- Check if tracking is currently paused
function LibMountInfo:IsTrackingPaused()
  return LibMountInfo.trackingPaused
end


-- Register a callback for when the mount changes
-- callbackType: "onMountChanged" or "onFlyingMountsUpdated"
-- callback: function to call
-- identifier: unique string to identify this callback (for unregistering)
function LibMountInfo:RegisterCallback(callbackType, identifier, callback)
  if not LibMountInfo.callbacks[callbackType] then
    LibMountInfo.callbacks[callbackType] = {}
  end
  LibMountInfo.callbacks[callbackType][identifier] = callback
end


-- Unregister a callback
function LibMountInfo:UnregisterCallback(callbackType, identifier)
  if LibMountInfo.callbacks[callbackType] then
    LibMountInfo.callbacks[callbackType][identifier] = nil
  end
end


-- Initialize the library
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
initFrame:RegisterEvent("NEW_MOUNT_ADDED")
initFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    LibMountInfo.currentRealm = GetRealmName()
    LibMountInfo.currentPlayer = UnitName("player")
    LibMountInfo:UpdateFlyingMounts()
    
    -- If persistent storage was set before login, initialize it now
    if LibMountInfo.persistentStorage then
      LibMountInfo:SetPersistentStorage(LibMountInfo.persistentStorage)
    end
  elseif event == "NEW_MOUNT_ADDED" then
    -- Update flying mount list when a new mount is learned
    LibMountInfo:UpdateFlyingMounts()
  elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
    -- Update current mount tracking
    local mountID, isFlying = LibMountInfo:GetCurrentMount()
    
    -- Fire callbacks
    if LibMountInfo.callbacks.onMountChanged then
      for _, callback in pairs(LibMountInfo.callbacks.onMountChanged) do
        callback(mountID, isFlying)
      end
    end
  end
end)


-- Expose library version
LibMountInfo.version = MINOR
