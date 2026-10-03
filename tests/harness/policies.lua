local P, M, O, C = Addon.BindingPolicy, Addon.ModePolicy, Addon.Ownership, Addon.Core
local keys={"PAD1","PAD2","PAD3","PAD4","PADDUP","PADDDOWN","PADDLEFT","PADDRIGHT"}
local mods={"","SHIFT-","CTRL-","CTRL-SHIFT-"}
local bindings={}
for _,mod in ipairs(mods) do for _,key in ipairs(keys) do bindings[mod..key]=mod..key end end
bindings["SHIFT-PADLSTICK"]="CLICK LM_B1:LeftButton"
bindings["CTRL-PADLSTICK"]="CLICK LM_B2:LeftButton"
bindings["SHIFT-PADRSTICK"]="EXTRAACTIONBUTTON1"
local scopes=P.Split(bindings)
local function count(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
assert(count(scopes.shared)==4 and count(scopes.character)==28 and count(scopes.retained)==3)
assert(C.Equal(P.Compose(scopes.shared,scopes.character,scopes.retained),bindings))
local ordinary={Base={{kind="click",id="jump"}},L2={{kind="action",slot=1}},R2={{kind="action",slot=61}},L2R2={{kind="action",slot=73}}}
local cells={}
for i=1,12 do cells[i]={kind="action",slot=120+i} end
for _,family in ipairs({"vehicle","override","temporary","skyriding","possess"}) do
    local map,pending=M.Resolve(ordinary,{family=family,cells=cells,exitOutside=true,form="cat"})
    assert(C.Equal(map.Base,ordinary.Base) and C.Equal(map.L2,ordinary.L2) and C.Equal(map.R2,ordinary.R2))
    assert(#map.L2R2==8 and map.L2R2[1].slot==121 and #pending==2)
    local restored=M.Resolve(ordinary,{family="form",form="cat"})
    assert(C.Equal(restored,ordinary))
end
for _,family in ipairs({"form","stance","stealth","mounted","flying","soar","ordinary"}) do
    assert(C.Equal(M.Resolve(ordinary,{family=family}),ordinary))
end
local stack=O.New()
stack:Push("gameplay","gameplay")
assert(stack:Begin("PAD1").id=="gameplay")
stack:Push("popup","popup")
assert(stack:Finish("PAD1").id=="gameplay") -- original down/up owner retained
assert(stack:Begin("PAD2").id=="popup")
stack:Remove("popup")
stack:Push("popup","popup") -- same frame id, new generation
assert(not stack:Finish("PAD2"))
assert(stack:Begin("PAD3"))
assert(not stack:Begin("PAD3"))
stack:Disconnect()
assert(not stack:Finish("PAD3"))
-- Deterministic owner-stack sequences must never redirect an old release.
math.randomseed(31)
for i=1,100 do
    local id="window"..math.random(1,5)
    local owner=stack:Push(id,"window")
    assert(stack:Begin("PAD4")==owner)
    if i%2==0 then stack:Remove(id) end
    local released=stack:Finish("PAD4")
    assert(released==nil or released.generation==owner.generation)
end
TEST_SUCCESS=true
