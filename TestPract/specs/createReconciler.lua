--!strict
-- Unit tests are needed in this module more than any other.

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local PractGlobalSystems = (require :: any)(practModule.PractGlobalSystems)
    local Symbols = (require :: any)(practModule.Symbols)
    local createReconciler = (require :: any)(practModule.createReconciler)
    local Pract = (require :: any)(practModule)

    local customHeartbeat = Instance.new('BindableEvent')

    local reconciler
    describe('createReconciler', function(it)
        it('should generate a closure-based reconciler object', function(expect)
            reconciler = createReconciler()
            expect.truthy(reconciler)
            expect.truthy(reconciler.createHost)
        end)
        it('should set up a controlled global system environment', function(expect)
            PractGlobalSystems.Stop()
            PractGlobalSystems.HeartbeatFrameCount = 0
            PractGlobalSystems.HeartbeatSignal = customHeartbeat.Event
            PractGlobalSystems.Run()
            expect.equal(0, PractGlobalSystems.HeartbeatFrameCount)
        end)
    end)

    local defaultHost
    describe('createHost', function(it)
        it('creates a host with no instance, no key, and empty providers', function(expect)
            local defaultProviders = {}
            defaultHost = reconciler.createHost(nil, nil, defaultProviders)
            expect.equal(nil, defaultHost.instance)
            expect.equal(nil, defaultHost.childKey)
            expect.equal(defaultProviders, defaultHost.providers)
            expect.deep_equal({providers = defaultProviders}, defaultHost)
        end)
    end)

    local mountedTrees = {}
    describe('mountVirtualTree', function(it)
        it('mounts a virtual tree with a default host context', function(expect)
            local element = Pract.create('Frame')
            local tree = reconciler.mountVirtualTree(element)
            table.insert(mountedTrees, tree)
            expect.truthy(tree)
            expect.equal(true, tree._mounted)
            expect.equal(true, tree[Symbols.IsPractTree])

            local rootNode = tree._rootNode
            expect.truthy(rootNode)
            expect.deep_equal(defaultHost, rootNode._hostContext)
            expect.equal(element, rootNode._currentElement)
        end)
    end)

    describe('unmountVirtualTree', function(it)
        it('unmounts each virtual tree from previous tests', function(expect)
            for i = 1, #mountedTrees do
                reconciler.unmountVirtualTree(mountedTrees[i])
                expect.equal(false, mountedTrees[i]._mounted)
            end
        end)
    end)
end

return spec