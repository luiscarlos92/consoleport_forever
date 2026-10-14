local Flag=Addon.SharedUtilityFlagPrototype
local account={databaseVersion=3,shared={archive={revision=8,entries={{kind='spell',id=101}}}},
    characters={A={rings={sets={[1]={{type='spell',spell=101}}}}}}}
local before=Addon.Core.Copy(account)
local starts=0
local function factory() starts=starts+1 return {running=true} end
assert(not Flag.TryStart(account,false,factory) and account.sharedUtilityEnabled==nil and starts==0,'ineligible startup enabled feature')
assert(Flag.TryStart(account,true,factory).running and starts==1,'first eligible use did not enable feature')
assert(account.sharedUtilityEnabled==true,'first-use flag not persisted')
assert(Flag.Command(account,'off'),'standalone off command rejected')
assert(not Flag.TryStart(account,true,factory) and starts==1,'disabled startup initialized feature')
assert(not Flag.FirstEligibleUse(account),'first-use check erased explicit disable')
local ok,enabled=Flag.Command(account,'status')
assert(ok and not enabled,'disabled status incorrect')
local snapshot=Addon.Core.Copy(account)
assert(not Flag.Command(account,'invalid') and Addon.Core.Equal(account,snapshot),'invalid flag command mutated account')
assert(Flag.Command(account,'on'),'explicit enable rejected')
local broken={sharedUtilityEnabled=true,shared={archive={version=999,entries='corrupt'}}}
local failures=0
for i=1,100 do
    assert(not Flag.TryStart(broken,true,function() failures=failures+1 error('feature constructor failure') end),'constructor failure escaped isolation')
end
assert(failures==1,'failed feature initialization retried on every event')
assert(Flag.Command(broken,'off') and not Flag.Enabled(broken),'broken constructor disabled escape hatch')
assert(Flag.Command(account,'off') and not Flag.Enabled(account),'constructor failure disabled escape hatch')
-- A failed/corrupt feature archive cannot prevent the independent disable path.
account.shared.archive={version=999,entries='corrupt feature data'}
assert(Flag.Command(account,'off') and not Flag.TryStart(account,true,factory),'corrupt archive blocked disable')
assert(Addon.Core.Equal(account.characters,before.characters),'flag changed GUID rings')
account.shared.archive=before.shared.archive
assert(Addon.Core.Equal(account.shared,before.shared),'flag changed shared archive')
PERSISTED_FLAG_SAMPLE=account
TEST_SUCCESS=true
