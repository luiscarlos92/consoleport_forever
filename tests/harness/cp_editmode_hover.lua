-- Execute the pinned native hover substitutions; native hover scripts fail
-- if called because they write the Edit Mode state this fix protects.
local Scripts={OnEnter={},OnLeave={}}
local function _(name,callback) assert(name=='Blizzard_EditMode') callback() end
EditModeSystemSelectionBaseMixin={OnEnter=function() error('unsafe native hover') end,
    OnLeave=function() error('unsafe native leave') end}
local button={}
local nativeEnter,nativeLeave=function() error('unsafe checkbox hover') end,function() error('unsafe checkbox leave') end
function button:GetScript(key) return key=='OnEnter' and nativeEnter or nativeLeave end
local checkbox={Button=button,Label={IsTruncated=function() return true end,GetText=function() return 'account option' end}}
local hidden=0 function checkbox:HideButtonTooltip() hidden=hidden+1 end
EditModeManagerFrame={AccountSettings={settingsCheckButtons={checkbox}},instructionsShown='preserved'}
local tooltip=0 GameTooltip={SetOwner=function() end,Show=function() tooltip=tooltip+1 end}
function GameTooltip_AddHighlightLine() end
--@NATIVE_EDITMODE_HOVERS
local highlighted,shownTooltip=false,0
local selection={instructionsShown=false,MouseOverHighlight={Show=function() highlighted=true end,Hide=function() highlighted=false end}}
function selection:CheckShowInstructionalTooltip() shownTooltip=shownTooltip+1 end
function selection:HideInstructionalTooltip() shownTooltip=shownTooltip-1 end
Scripts.OnEnter[EditModeSystemSelectionBaseMixin.OnEnter](selection)
assert(highlighted and shownTooltip==1 and selection.instructionsShown==false)
Scripts.OnLeave[EditModeSystemSelectionBaseMixin.OnLeave](selection)
assert(not highlighted and shownTooltip==0 and selection.instructionsShown==false)
Scripts.OnEnter[nativeEnter]() Scripts.OnLeave[nativeLeave]()
assert(tooltip==1 and hidden==1 and EditModeManagerFrame.instructionsShown=='preserved')
TEST_SUCCESS=true
