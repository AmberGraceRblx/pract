--!strict
--[[
    State hook, equivalent to React.useState
]]

local PractGlobalSystems = require(script.Parent.PractGlobalSystems)

local function useState<T--[[=any]]>(initialState: T | () -> T): (T, (newState: T) -> ())
    return PractGlobalSystems._reconcilerHookCallbacks.useState(initialState)
end
return useState