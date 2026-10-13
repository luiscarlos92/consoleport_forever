local _, Addon = ...
local Diagnostics = {limit=80, entries={}, features={}}
Addon.Diagnostics = Diagnostics
local function Public(value) return not (issecretvalue and issecretvalue(value)) end
local PERF_SCOPES={['skin.full']=true,['skin.button']=true,['skin.visual']=true,
    ['diagnostics.full']=true,['diagnostics.section']=true,['runtime.full']=true,
    ['runtime.modes']=true,['runtime.rings']=true,['runtime.context']=true,['runtime.cinematic']=true}
function Diagnostics:Persist(section,id)
    -- Bounded last-session evidence for read-only WTF audits. This is runtime
    -- bookkeeping, never proof that a controller or protected action passed.
    if not Addon.record or not Addon.Core then return end
    if self.blockedOwner and self.blockedOwner~=Addon.record then self.blocked=nil self.blockedOwner=nil end
    local saved=Addon.record.lastRuntimeDiagnostics
    if section and self.persistOwner==Addon.record and saved
        and saved.codeVersion==Addon.VERSION and saved.configRevision==Addon.CONFIG_REVISION then
        local start=self:BeginPerformance('diagnostics.section')
        if section=='features' and id then saved.features[id]=Addon.Core.Copy(self.features[id])
        else saved[section]=Addon.Core.Copy(self[section] or {}) end
        self:EndPerformance('diagnostics.section',start)
        return
    end
    local start=self:BeginPerformance('diagnostics.full')
    Addon.record.lastRuntimeDiagnostics = {
        codeVersion=Addon.VERSION, configRevision=Addon.CONFIG_REVISION,
        features=Addon.Core.Copy(self.features), entries=Addon.Core.Copy(self.entries),
        visuals=Addon.Core.Copy(self.visuals or {}),
        ping=Addon.Core.Copy(self.ping or {}),
        circle=Addon.Core.Copy(self.circle or {}),
        blocked=Addon.Core.Copy(self.blocked or {}),
    }
    self.persistOwner=Addon.record
    self:EndPerformance('diagnostics.full',start)
end
-- Observe all blamed addons: the reported name is an execution attribution,
-- not proof of the original writer. Inspect security labels without reading
-- action/cooldown values, replacing handlers, or changing game logging CVars.
function Diagnostics:RecordBlocked(api,event,blamed,func)
    local function scalar(value)
        if api.issecretvalue and api.issecretvalue(value) then return end
        if type(value)=='string' then return value:sub(1,240) end
    end
    blamed,func=scalar(blamed) or 'unknown',scalar(func) or 'unknown'
    if self.blockedOwner and self.blockedOwner~=Addon.record then self.blocked=nil end
    self.blockedOwner=Addon.record
    self.blocked=self.blocked or {total=0,rows={}}
    local log=self.blocked
    log.total=log.total+1
    local row
    for _,entry in ipairs(log.rows) do
        if entry.event==event and entry.addon==blamed and entry.func==func then row=entry break end
    end
    if not row then
        row={event=event,addon=blamed,func=func,count=0}
        if #log.rows>=16 then table.remove(log.rows,1) end
        log.rows[#log.rows+1]=row
        self:Log('blocked',event..': '..blamed..': '..func)
    end
    row.count=row.count+1
    local ok,time=pcall(api.GetTime or function() end)
    if ok and not (api.issecretvalue and api.issecretvalue(time)) and type(time)=='number'
        and time==time and time>=0 and time<math.huge then row.time=time end
    local name=func:match('^([%w_]+):')
    local object=name and api[name]
    if object and type(api.issecurevariable)=='function' then
        row.object=name row.fields={}
        for _,field in ipairs({'action','eventsRegistered','popupDirection','needsUpdate','OnEvent','UpdateAction'}) do
            local checked,secure,writer=pcall(api.issecurevariable,object,field)
            if checked and not (api.issecretvalue and api.issecretvalue(secure)) and type(secure)=='boolean' then
                row.fields[field]={secure=secure,writer=scalar(writer)}
            end
        end
    end
    self:Persist('blocked')
end
function Diagnostics:Log(kind, message)
    self.entries[#self.entries+1] = {kind=kind, message=tostring(message)}
    if #self.entries > self.limit then table.remove(self.entries,1) end
    self:Persist('entries')
end
function Diagnostics:SetFeature(id, status, reason)
    local previous=self.features[id]
    local saved=Addon.record and Addon.record.lastRuntimeDiagnostics
    if previous and Public(status) and Public(reason) and Public(previous.status) and Public(previous.reason)
        and previous.status==status and previous.reason==reason and self.persistOwner==Addon.record
        and saved and saved.codeVersion==Addon.VERSION and saved.configRevision==Addon.CONFIG_REVISION then return end
    self.features[id] = {status=status, reason=reason}
    self:Persist('features',id)
end

-- Opt-in inclusive callback timing: fixed labels, aggregates only, no events,
-- spell payloads, protected writes, timer workers or automatic console output.
function Diagnostics:SetPerformance(enabled)
    if enabled and type(debugprofilestop)~='function' then return false,'profiling clock unavailable' end
    self.performance=self.performance or {scopes={}}
    self.performance.enabled=enabled==true
    return true
end
function Diagnostics:ResetPerformance()
    self.performance={enabled=self.performance and self.performance.enabled or false,scopes={}}
end
function Diagnostics:BeginPerformance(label)
    if not self.performance or not self.performance.enabled or not PERF_SCOPES[label] then return end
    local ok,value=pcall(debugprofilestop)
    if ok and Public(value) and type(value)=='number' and value==value and value>=0 and value<math.huge then return value end
end
function Diagnostics:EndPerformance(label,start)
    if start==nil then return end
    local finish=self:BeginPerformance(label)
    if finish==nil or finish<start then return end
    local elapsed=finish-start
    local row=self.performance.scopes[label]
    if not row then row={count=0,totalMs=0,peakMs=0,over10Ms=0,over50Ms=0,over100Ms=0} self.performance.scopes[label]=row end
    row.count=row.count+1 row.totalMs=row.totalMs+elapsed row.peakMs=math.max(row.peakMs,elapsed)
    if elapsed>10 then row.over10Ms=row.over10Ms+1 end
    if elapsed>50 then row.over50Ms=row.over50Ms+1 end
    if elapsed>100 then row.over100Ms=row.over100Ms+1 end
end
function Diagnostics:FinishMeasured(label,start,...)
    self:EndPerformance(label,start)
    return ...
end
function Diagnostics:Measure(label,callback,...)
    if not self.performance or not self.performance.enabled then return callback(...) end
    return self:FinishMeasured(label,self:BeginPerformance(label),callback(...))
end
function Diagnostics:PerformanceSummary()
    local scopes=self.performance and self.performance.scopes or {}
    if Addon.record then
        Addon.record.lastPerformanceEvidence={codeVersion=Addon.VERSION,configRevision=Addon.CONFIG_REVISION,
            inclusive=true,scopes=Addon.Core.Copy(scopes)}
    end
    local lines={}
    for label,row in pairs(scopes) do
        lines[#lines+1]=string.format('%s: %d calls, %.3f ms total, %.3f ms average, %.3f ms peak; >10/50/100: %d/%d/%d',
            label,row.count,row.totalMs,row.totalMs/row.count,row.peakMs,row.over10Ms,row.over50Ms,row.over100Ms)
    end
    table.sort(lines)
    return #lines>0 and table.concat(lines,'\n') or 'No profiling samples. /cpf perf on enables optional callback timing.'
end
function Diagnostics:Summary()
    local lines={}
    for id,feature in pairs(self.features) do lines[#lines+1] = id .. ": " .. feature.status .. (feature.reason and " ("..feature.reason..")" or "") end
    table.sort(lines)
    return table.concat(lines,"\n")
end
