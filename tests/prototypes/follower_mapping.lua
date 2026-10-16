-- Offline experiment only. Never loaded by the addon TOC.
-- Keep native saved identity AND LAB spell feedback; alter only compiled DATA.
local _,Addon=...
local Mapping={}
Addon.FollowerMappingPrototype=Mapping
function Mapping.New(env,api)
    if api.blocked() then return nil,'blocked' end
    local frame=env.Frame
    local beforeMap,beforeAdd=env.GetKindAndAction,frame.AddSecureAction
    local candidate={env=env,frame=frame,api=api,beforeMap=beforeMap,beforeAdd=beforeAdd}
    local setContext
    candidate.map=function(owner,info)
        local kind,action,extra=beforeMap(owner,info)
        if not candidate:Owns() or not api.ready() then return kind,action,extra end
        if (setContext==1 or setContext=='1') and type(info)=='table'
            and info.type=='spell' and info.spell==426756 and info.autoassigned==true then
            local _,_,route=beforeMap(owner,{type='custom',binding=api.binding})
            -- Native AddSecureAction separates LAB state from secure slot data.
            -- Do not convert the LAB widget to Custom (that loses spell feedback).
            return kind,action,route
        end
        return kind,action,extra
    end
    candidate.add=function(owner,set,index,info)
        local previous=setContext
        setContext=set
        local ok,result=pcall(beforeAdd,owner,set,index,info)
        setContext=previous
        if not ok then error(result) end
        return result
    end
    env.GetKindAndAction=candidate.map
    frame.AddSecureAction=candidate.add
    return setmetatable(candidate,{__index=Mapping})
end
function Mapping:Owns()
    return self.env.Frame==self.frame and self.env.GetKindAndAction==self.map
        and self.frame.AddSecureAction==self.add
end
function Mapping:Abort()
    if self.api.blocked() then return false end
    if self.env.GetKindAndAction==self.map then self.env.GetKindAndAction=self.beforeMap end
    if self.frame.AddSecureAction==self.add then self.frame.AddSecureAction=self.beforeAdd end
    return true
end
