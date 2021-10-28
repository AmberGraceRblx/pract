--!strict
--[[
	Runs system singletons and holds state singletons for optimizing Pract
]]

local RunService = game:GetService('RunService')
local PractGlobalSystems = {}

PractGlobalSystems.HeartbeatFrameCount = 0
PractGlobalSystems.ON_CHILD_TIMEOUT_INTERVAL = 30
PractGlobalSystems.ON_CHILD_TIMEOUT_RETRIES = 2

local whileRunningConns = {} :: {RBXScriptConnection}
local running = false
function PractGlobalSystems.Run()
	if running then return end
	running = true
	
	table.insert(
		whileRunningConns,
		RunService.Heartbeat:Connect(function()
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