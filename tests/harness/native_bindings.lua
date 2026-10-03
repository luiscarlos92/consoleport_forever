local set,combat=0,false
local banks={[1]={SPACE="JUMP",["SHIFT-M"]="TOGGLEWORLDMAP",PAD1="JUMP"},
             [2]={K="OTHER",PAD1="OLD"}}
local saves=0
local api={AccountSet=1,CharacterSet=2,GetCurrentBindingSet=function() return set end,
    InCombatLockdown=function() return combat end,
    LoadBindings=function(v) set=v end,
    GetNumBindings=function() local n=0 for _ in pairs(banks[set] or {}) do n=n+1 end return n end,
    GetBinding=function(i) local n=0 for key,v in pairs(banks[set]) do n=n+1 if n==i then return v,"category",key end end end,
    GetBindingAction=function(k,effective) if effective and k=="PAD1" then return "POPUP_ACTION" end return banks[set][k] or "" end,
    SetBinding=function(k,v) assert(not combat) banks[set][k]=v return true end,
    SaveBindings=function(v) assert(v==2 and set==2) saves=saves+1 return true end}
local native=Addon.NativeBindings.New(api)
assert(not native:Ready() and not native:Capture())
set=1
local snapshot=assert(native:Capture())
assert(snapshot.saved.PAD1=="JUMP" and snapshot.effective.PAD1=="POPUP_ACTION")
assert(snapshot.keyboard.SPACE=="JUMP" and snapshot.keyboard.PAD1==nil)
combat=true
assert(not native:write({"PAD1"},"NEW"))
assert(not native:SelectCharacter(snapshot))
combat=false
assert(native:SelectCharacter(snapshot))
assert(banks[2].SPACE=="JUMP" and banks[2]["SHIFT-M"]=="TOGGLEWORLDMAP" and banks[2].K==nil)
assert(native:write({"PAD1"},"NEW") and banks[2].SPACE=="JUMP")
assert(native:SaveCharacter() and saves==1)
set=1
assert(not native:SaveCharacter() and saves==1)
set=2
api.SetBinding=function() return false end
assert(not native:write({"PAD1"},"FAILED") and banks[2].PAD1=="NEW")
api.SetBinding=function() error("native setter threw") end
assert(not pcall(native.write,native,{"PAD1"},"FAILED"))
TEST_SUCCESS=true
