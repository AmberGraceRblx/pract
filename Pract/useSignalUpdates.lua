--!strict
--[[
    RBXScriptSignal hook that wraps useEffect internally; replacement for
    Pract.withSignal
]]

local useEffect = require(script.Parent.useEffect)

local function useSignalUpdates(signal: RBXScriptSignal): ()
    return useEffect(function(queueUpdate)
        local conn = signal:Connect(queueUpdate)
        return function()
            conn:Disconnect()
        end
    end, {signal})
end
return useSignalUpdates