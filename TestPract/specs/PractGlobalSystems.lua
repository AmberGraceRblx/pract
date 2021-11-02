--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local PractGlobalSystems: any = require(practModule.PractGlobalSystems)

    describe('PractGlobalSystems', function(it)
        it('initializes by requiring the Pract module and stopping it', function(asserts)
            -- Global systems should run as a side effect of requiring Pract
            require(practModule)
            PractGlobalSystems.Stop()
        end)

        local customHeartbeatEvent = Instance.new('BindableEvent')
        it('runs with a custom HeartbeatSignal', function(asserts)
            PractGlobalSystems.HeartbeatFrameCount = 0
            PractGlobalSystems.HeartbeatSignal = customHeartbeatEvent.Event
            PractGlobalSystems.Run()

            asserts.equal(0, PractGlobalSystems.HeartbeatFrameCount)
        end)

        it('upticks HeartbeatFrameCount when the HeartbeatSignal fires', function(asserts)
            customHeartbeatEvent:Fire()
            asserts.equal(1, PractGlobalSystems.HeartbeatFrameCount)
            customHeartbeatEvent:Fire()
            asserts.equal(2, PractGlobalSystems.HeartbeatFrameCount)
        end)

        it('only upticks HeartbeatFrameCount while running', function(asserts)
            PractGlobalSystems.Stop()
            asserts.equal(2, PractGlobalSystems.HeartbeatFrameCount)
            customHeartbeatEvent:Fire()
            asserts.equal(2, PractGlobalSystems.HeartbeatFrameCount)
        end)
    end)
end

return spec