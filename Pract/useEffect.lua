--!strict
--[[
    "Effect" hook, similar to React.useEffect
    Additionally passes in a "queueUpdate" callback which acts
    similarly to the now-deprecated "forceUpdate" passed through
    Pract.withLifecycle
]]

local PractGlobalSystems = require(script.Parent.PractGlobalSystems)

local function useEffect<T--[[=any]]>(
    effect: ((queueUpdate: () -> ()) -> ()) | ((queueUpdate: () -> ()) -> (() -> ())),
    deps: {any}?
): ()
    return PractGlobalSystems._reconcilerHookCallbacks.useEffect(effect, deps)
end
return useEffect