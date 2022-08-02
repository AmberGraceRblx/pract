--!strict
--[[
    Context consumer hook, equivalent to React.useConsumer
]]

local Types = require(script.Parent.Types)
local PractGlobalSystems = require(script.Parent.PractGlobalSystems)

local function useConsumer(context: Types.PublicContextObject): any
    return PractGlobalSystems._reconcilerHookCallbacks.useConsumer(context)
end
return useConsumer