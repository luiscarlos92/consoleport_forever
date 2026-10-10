local Ping=Addon.PingTargeting
local function click(key,down)
    hardware=true trusted=true
    local physical=key:match('([^%-]+)$')
    mapped.buttons[physical=='PAD2' and 2 or 10]=down
    local action=GetBindingAction(key,true)
    local target,button=action:match('^CLICK ([^:]+):(.+)$')
    if target then local frame=assert(frames[target]) fire(frame,'PreClick',button,down) fire(frame,'OnClick',button,down,true,true) fire(frame,'PostClick',button,down) end
    trusted=false hardware=false
end
local function vector(index)
    local angle=((index or 1)-1)*2*math.pi/6
    mapped.sticks[2]={x=index and math.sin(angle) or 0,y=index and math.cos(angle) or 0,len=index and 1 or 0}
end
local ready,reason=Ping:Refresh(_G,true,bridge)
assert(ready,reason)
assert(Ping.ring==ConsolePortUtilityToggle and Ping.frame.template=='SecureActionButtonTemplate,SecureHandlerStateTemplate','separate renderer used')
assert(ring.Shared.ForeverPings and not ring.Data.ForeverPings and ConsolePortRingsShared==ring.Shared,'native account Shared container missing')
assert(env:IsSharedSet('ForeverPings') and #ring.Shared.ForeverPings==6,'account ring not available through native settings')
assert(ring.Data==personalBefore and ring.Data.PaladinAuras==auraBefore and ring.Shared.UserShared==sharedBefore,'other rings changed')
for i=1,6 do
    local button=ring.widgets[i]
    assert(button.initialized and button.preventSkinning and button.dragDisabled and button.nativeSkinCalls,'native skin/initializer missing')
    assert(button.states.ForeverPings[2].text==PING_TYPE_ATTACK or button.states.ForeverPings[2].text==({'Attack','Warning','OnMyWay','Assist','NonThreat','Threat'})[i],'native action text missing')
end
vector(nil)
click('PADRSTICK',true)
assert(#sent==1 and sent[1].point,'press did not send immediately')
assert(not sent[1].nativeRingShown,'immediate ping sent after camera capture')
assert(ring.alpha==0,'tap displayed selector')
assert(cvars.GamePadCursorCentering=='0' and not Ping.frame.cpfCenterBefore,'press did not restore cursor centering')
assert(hitTests[1].x==500 and hitTests[1].y==360 and hitTests[1].forcePoint,'point ping used parked UI receiver')
click('PADRSTICK',false)
assert(#sent==1 and not ring:IsShown(),'neutral tap release retained ring or sent extra ping')
local count=#sent
for _,inCombat in ipairs({false,true}) do
    combat=inCombat
    trusted=true Ping.frame:SetAttribute('state-cpf-combat',inCombat and 'combat' or 'peace') trusted=false
    for i=1,6 do
        vector(nil) click('PADRSTICK',true)
        assert(#sent==count+1,'press did not send immediately') count=#sent
        assert(ring.alpha==0,'tap displayed selector')
        clock=clock+.16 fire(ring,'OnUpdate',.16)
        assert(ring.alpha==1 and dispatcher.focusFrame==ring,'hold did not reveal actual native ring')
        vector(i) ring:OnInput(mapped.sticks[2].x,mapped.sticks[2].y,1)
        assert(ring.widgets[i].highlighted and ring.widgets[i]:GetActiveText()==({'Attack','Warning','OnMyWay','Assist','NonThreat','Threat'})[i],'native focus/text failed')
        assert(ring.widgets[i].icon.atlas=='Ping_Marker_Icon_'..({'Attack','Warning','OnMyWay','Assist','NonThreat','Threat'})[i],'native icon adapter failed')
        click('PADRSTICK',false)
        assert(#sent==count+1 and sent[#sent].type==i-1,'native selected release did not dispatch') count=#sent
        assert(not ring:IsShown() and ring.alpha==1 and cvars.GamePadCursorCentering=='0','native release retained ring/cursor lease')
    end
end
combat=false trusted=true Ping.frame:SetAttribute('state-cpf-combat','peace') trusted=false
vector(nil) units.softenemy='enemy-guid' click('PADRSTICK',true)
assert(sent[#sent].guid=='enemy-guid','press lost aimed softenemy') count=#sent
click('PADRSTICK',false) assert(#sent==count,'aimed tap duplicate') units.softenemy=nil
-- Preserve native sticky selection rather than replacing its release behavior.
nativeSettings.ringStickySelect=true ring:OnStickySelectChanged()
vector(2) click('PADRSTICK',true) clock=clock+.16 fire(ring,'OnUpdate',.16) click('PADRSTICK',false)
assert(ring.Shared.ForeverPings[0].sticky==2,'native sticky default not preserved')
vector(nil) click('PADRSTICK',true) count=#sent click('PADRSTICK',false)
assert(#sent==count+1 and sent[#sent].type==1,'native sticky release behavior changed')
nativeSettings.ringStickySelect=false ring:OnStickySelectChanged()
-- Standard native cancellation: neutral release. No custom PAD2 cancel claim.
vector(nil) click('PADRSTICK',true) count=#sent
assert(not GetBindingAction('PAD2',true):find('ConsolePortForeverPing',1,true),'custom cancel installed')
click('PADRSTICK',false) assert(#sent==count,'native neutral cancel sent selection')
-- Mandatory hold opener uses native hold mode without changing global toggle.
nativeSettings.ringPressAndHold=false ring:OnPressAndHoldChanged()
vector(nil) click('PADRSTICK',true) clock=clock+.16 fire(ring,'OnUpdate',.16)
assert(ring:IsShown() and ring.alpha==1 and ring:GetAttribute('pressAndHold')==false,'hold opener changed global native preference or failed to open')
count=#sent click('PADRSTICK',false) assert(#sent==count and not ring:IsShown(),'native hold context did not clear')
nativeSettings.ringPressAndHold=true ring:OnPressAndHoldChanged()
-- Native modal/owner/state cancellation never dispatches a stale selection.
for _,name in ipairs({'Raid','TargetRing'}) do
    vector(nil) click('PADRSTICK',true) count=#sent
    trusted=true nativeOwners[name]:Show() nativeOwners[name]:Hide() trusted=false
    click('PADRSTICK',false) assert(#sent==count and not ring:IsShown(),'native owner handoff committed selection')
end
vector(nil) click('PADRSTICK',true) count=#sent
trusted=true db.Layers:SetAttribute('prefix','CTRL-') trusted=false
click('PADRSTICK',false) assert(#sent==count and not ring:IsShown(),'prefix crossing committed selection')
trusted=true db.Layers:SetAttribute('prefix','') trusted=false
combat=true trusted=true Ping.frame:SetAttribute('state-cpf-combat','combat') trusted=false
vector(nil) click('PADRSTICK',true) count=#sent local previous=mapped mapped=nil
fire(ring,'OnUpdate',.01)
assert(not dispatcher.focusFrame and not dispatcher.stickEnabled,'disconnect retained camera')
assert(ring:IsShown(),'public watchdog changed protected visibility')
mapped={name='different-device',buttons={[10]=false},sticks=previous.sticks}
click('PADRSTICK',false) assert(#sent==count and not ring:IsShown(),'disconnect committed selection')
mapped=previous combat=false trusted=true Ping.frame:SetAttribute('state-cpf-combat','peace') trusted=false
-- Another set opened on this SAME native header must supersede the ping set.
vector(nil) click('PADRSTICK',true) count=#sent
hardware=true trusted=true ring:RunAttribute('Main','PaladinAuras',true) trusted=false hardware=false
assert(ring:GetAttribute('state')=='PaladinAuras' and not Ping.frame:GetAttribute('cpf-trigger') and ring.alpha==1,'ping context hijacked aura opener')
local uv=ring.widgets[1].icon.uv
assert(uv and uv[1]==0 and uv[2]==1 and uv[3]==0 and uv[4]==1,'ping atlas UVs leaked into aura icon')
click('PADRSTICK',false) assert(#sent==count,'old ping release committed aura selection')
hardware=true trusted=true ring:RunAttribute('Disable') trusted=false hardware=false
-- Other ring openers retain alpha, native input and personal data.
hardware=true trusted=true ring:RunAttribute('Main','PaladinAuras',true) trusted=false hardware=false
assert(ring.alpha==1 and not ring.cpfVisibleAt,'ordinary ring acquired ping delay')
hardware=true trusted=true ring:RunAttribute('Disable') trusted=false hardware=false
-- Shared edits/order survive refresh and character changes; no seeding on login.
local set=ring.Shared.ForeverPings
set[1],set[2]=set[2],set[1] table.remove(set,6)
assert(Ping:Refresh(_G,true,bridge),'native account creation rejected')
assert(ring.Shared.ForeverPings==set and #set==5 and set[1].cpfPing==2,'account edits overwritten')
Addon.guid='DemonHunter' assert(Ping:Refresh(_G,true,bridge))
assert(ring.Shared.ForeverPings==set and ring.Data.PaladinAuras==auraBefore,'character switch replaced shared ring')
ring.Data.ForeverPings={[0]={}}
ready,reason=Ping:Refresh(_G,true,bridge)
assert(not ready and reason:find('belongs to another ring',1,true),'personal collision accepted')
assert(GetBindingAction('PADRSTICK',true)=='TOGGLEPINGLISTENER','collision retained ping override')
ring.Data.ForeverPings=nil
assert(Ping:Refresh(_G,true,bridge))
assert(Ping:Refresh(_G,false,bridge))
assert(ring.Shared.ForeverPings==set and GetBindingAction('PADRSTICK',true)=='TOGGLEPINGLISTENER','disable deleted native account ring')
assert(uiChecks==0,'world ping crossed UI blocker')
TEST_SUCCESS=true
