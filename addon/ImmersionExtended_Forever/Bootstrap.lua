local _, NS = ...
local api = _G
local runtime = NS.New(api)
if not runtime or type(api.CreateFrame) ~= 'function' then return end
NS.runtime = runtime
runtime:Refresh()
local events = api.CreateFrame('Frame')
for _, event in ipairs({'ADDON_LOADED', 'PLAYER_LOGIN', 'PLAYER_ENTERING_WORLD',
    'PLAYER_REGEN_ENABLED', 'GET_ITEM_INFO_RECEIVED', 'ITEM_DATA_LOAD_RESULT',
    'PLAYER_EQUIPMENT_CHANGED', 'PLAYER_SPECIALIZATION_CHANGED'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent', function(_, event, ...)
    if event == 'ADDON_LOADED' or event == 'PLAYER_LOGIN' or event == 'PLAYER_ENTERING_WORLD'
        or event == 'PLAYER_REGEN_ENABLED' then runtime:Refresh()
    else runtime.rewards:Event(event, ...) end
end)
if api.SlashCmdList then
    api.SLASH_IMMERSIONEXTENDEDFOREVER1 = '/immersionextended'
    api.SlashCmdList.IMMERSIONEXTENDEDFOREVER = function()
        if api.DEFAULT_CHAT_FRAME then api.DEFAULT_CHAT_FRAME:AddMessage(runtime:Status()) end
    end
end
