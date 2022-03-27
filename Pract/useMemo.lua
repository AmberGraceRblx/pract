--!strict
--[[
    Memoization hook, equivalent to React.useMemo
]]

local PractGlobalSystems = require(script.Parent.PractGlobalSystems)

local function useMemo<T--[[=any]]>(create: () -> T, deps: {any}?): T
    return PractGlobalSystems._reconcilerHookCallbacks.useMemo(create, deps)
end
return useMemo