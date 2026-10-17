-- Execute native RefreshConfig; camera/UI startup and scripts are recording
-- doubles. This does not simulate actual rendering, camera CVars or combat.
do
local started=true
local trace={}
local DynamicCam={currentSituationID='old',db={profile={situations={
    one={enabled=true,executeOnInit='preserve user script',errorEncountered=true,errorMessage='old'},
    two={enabled=false,executeOnInit='disabled user script',errorEncountered=true,errorMessage='old'}}}}}
function DynamicCam:Shutdown() trace[#trace+1]='shutdown' started=false end
function DynamicCam:Startup() trace[#trace+1]='startup' started=true end
function DynamicCam:RefreshAllCurveEditors() trace[#trace+1]='editors' end
function DynamicCam:RunScript(id,kind)
    assert(id=='one' and kind=='executeOnInit' and started,'native profile script dispatch changed')
    trace[#trace+1]='script'
end
DynamicCam.Options={ClearSelection=function() trace[#trace+1]='clear' end,
    SelectSituation=function() trace[#trace+1]='select' end}
--@NATIVE_DYNAMIC_REFRESH
DynamicCam:RefreshConfig()
assert(table.concat(trace,',')=='shutdown,clear,select,editors,startup,script','native profile refresh order changed')
assert(DynamicCam.currentSituationID==nil and DynamicCam.db.profile.situations.one.executeOnInit=='preserve user script')
assert(not DynamicCam.db.profile.situations.two.errorEncountered and not DynamicCam.db.profile.situations.two.errorMessage)
trace={} started=false DynamicCam.Options=nil
DynamicCam:RefreshConfig()
assert(table.concat(trace,',')=='editors,startup,script','native profile refresh without active UI changed')
end
TEST_SUCCESS=true
