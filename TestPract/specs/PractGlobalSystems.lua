--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local PractGlobalSystems = (require :: any)(practModule.PractGlobalSystems)

    describe('PractGlobalSystems', function(it)
        it('initializes by requiring the Pract module and stopping it', function(asserts)
            -- Global systems should run as a side effect of requiring Pract
            (require :: any)(practModule)
            PractGlobalSystems.Stop()
        end)

        local customHeartbeatEvent = Instance.new('BindableEvent')
        it('runs with a custom HeartbeatSignal', function(expect)
            PractGlobalSystems.HeartbeatFrameCount = 0
            PractGlobalSystems.HeartbeatSignal = customHeartbeatEvent.Event
            PractGlobalSystems.Run()

            expect.equal(0, PractGlobalSystems.HeartbeatFrameCount)
        end)

        it('upticks HeartbeatFrameCount when the HeartbeatSignal fires', function(expect)
            customHeartbeatEvent:Fire()
            expect.equal(1, PractGlobalSystems.HeartbeatFrameCount)
            customHeartbeatEvent:Fire()
            expect.equal(2, PractGlobalSystems.HeartbeatFrameCount)
        end)

        it('only upticks HeartbeatFrameCount while running', function(expect)
            PractGlobalSystems.Stop()
            expect.equal(2, PractGlobalSystems.HeartbeatFrameCount)
            customHeartbeatEvent:Fire()
            expect.equal(2, PractGlobalSystems.HeartbeatFrameCount)
        end)
    end)
end

return spec