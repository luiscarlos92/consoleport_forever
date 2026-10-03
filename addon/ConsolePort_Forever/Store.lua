local _, Addon = ...
local Core, Store = Addon.Core, {VERSION = 3}
Addon.Store = Store

function Store.EnsureSchema(db, guid, legacyCharacter)
    if type(db) ~= "table" then return nil, "invalid account store" end
    local version = db.databaseVersion or db.schema or db.installedSchema or 0
    if type(version) ~= "number" or version > Store.VERSION then return nil, "unsupported database schema" end
    if version < Store.VERSION then
        local previous = Core.Copy(db)
        db.legacy = db.legacy or {}
        db.legacy.schemaMigration = db.legacy.schemaMigration or {from = version, account = previous}
        -- A flat per-character file is physically shared. Its installation marker
        -- cannot identify its owner, even if the current login has a GUID.
        if legacyCharacter then
            db.legacy.ambiguousCharacter = db.legacy.ambiguousCharacter or Core.Copy(legacyCharacter)
        end
        db.databaseVersion = Store.VERSION
    end
    db.shared = db.shared or {revision = 0, geometry = {}, faceBindings = {}, utilityPolicy = {}, integrationPolicy = {}}
    db.characters, db.managedFields = db.characters or {}, db.managedFields or {}
    db.transactions, db.backups = db.transactions or {}, db.backups or {}
    db.nextTransactionID = db.nextTransactionID or 0
    return db
end

function Store.GetCharacter(db, guid, identity)
    if type(guid) ~= "string" or guid == "" then return nil, "player GUID unavailable" end
    local record = db.characters[guid]
    if not record then
        record = {identity = {}, requiredRevision = 0, appliedRevision = 0,
                  controllerBindings = {}, rings = {}, fieldBaselines = {},
                  integrationStatus = {}, pendingChanges = {}, transactionIDs = {}}
        db.characters[guid] = record
    end
    if identity then record.identity = Core.Copy(identity) end
    return record
end

-- Adapters project only their owned fields and must retain table identities.
-- A late login must never capture the previous character's projected view.
function Store.CaptureOwnedEdits(db, guid, adapter)
    if db.lastProjectedGUID ~= guid then return false, "projection belongs to another character" end
    local record = db.characters[guid]
    if not record then return false, "unknown character" end
    local ok, view = pcall(adapter.capture, adapter)
    if not ok or type(view) ~= "table" then return false, "owned view capture failed" end
    record.projectedView = Core.Copy(view)
    return true
end
function Store.Hydrate(db, guid, adapter, defaults)
    local record, reason = Store.GetCharacter(db, guid)
    if not record then return false, reason end
    local view = Core.Copy(record.projectedView or defaults or {})
    local ok, result = pcall(adapter.project, adapter, view)
    if not ok or result ~= true then return false, "owned view projection failed" end
    db.lastProjectedGUID = guid
    record.projectionIdentity = guid
    return true
end
