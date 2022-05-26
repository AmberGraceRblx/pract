--!strict
--[[
	Runs system singletons and holds state singletons for optimizing Pract
]]

local Types = require(script.Parent.Types)
local RunService = game:GetService('RunService')
local PractGlobalSystems = {}

PractGlobalSystems.HeartbeatFrameCount = 0
PractGlobalSystems.ON_CHILD_TIMEOUT_INTERVAL = 10
PractGlobalSystems.HeartbeatSignal = RunService.Heartbeat
PractGlobalSystems._reconcilerHookCallbacks = (setmetatable(
	{},
	{
		__index = function(...)
			error("Invalid hook call. Hooks can only be called inside of the body of a function component. ")
		end
	}
) :: any) :: {
	useState: (initialState: any | () -> ()) -> (
		any,
		(nextState: any) -> ()
	),
	useMemo: (create: () -> any, deps: {any}?) -> any,
	useEffect: (create: ((queueUpdate: () -> ()) -> (() -> ())) | ((queueUpdate: () -> ()) -> ()), deps: {any}?) -> (),
	useConsumer: (context: Types.PublicContextObject) -> any,
	customHook: Types.HookReconciler,
}

local whileRunningConns = {} :: {RBXScriptConnection}
local running = false
function PractGlobalSystems.Run()
	if running then return end
	running = true
	
	table.insert(
		whileRunningConns,
		PractGlobalSystems.HeartbeatSignal:Connect(function()
			PractGlobalSystems.HeartbeatFrameCount = PractGlobalSystems.HeartbeatFrameCount + 1
		end)
	)
end

function PractGlobalSystems.Stop()
	if not running then return end
	running = false
	
	for i = 1, #whileRunningConns do
		whileRunningConns[i]:Disconnect()
	end
	whileRunningConns = {}
end

return PractGlobalSystems