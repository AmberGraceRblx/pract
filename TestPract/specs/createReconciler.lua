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
            defaultHost = reconciler.createHost(nil, nil, defaultProviders, nil)
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

    describe("ElementKinds.SiblingCluster", function(it)
        it("errors if sibling decorate element is mounted with no host instance", function(expect)
            local tree
            expect.errors(function()
                tree = reconciler.mountVirtualTree(
                    Pract.combine(
                        Pract.decorate({})
                    )
                )
            end)
            if tree then
                reconciler.unmountVirtualTree(tree)
            end
        end)
        it("propogages stamped element instance to sibling decorate element", function(expect)
            local template = Instance.new("Folder")
            template:SetAttribute("IsOurTemplate", true)

            local tree = reconciler.mountVirtualTree(
                Pract.combine(
                    Pract.stamp(template),
                    Pract.decorate({
                        [Pract.Attributes] = {
                            WasDecorated = true,
                        }
                    })
                )
            )
            
            local rootNode: any = tree._rootNode
            expect.truthy(rootNode)

            local siblingClusterCache = rootNode._hostContext.siblingClusterCache
            expect.truthy(siblingClusterCache)

            local stampedInstance = siblingClusterCache.lastProvidedInstance
            expect.truthy(stampedInstance)

            expect.equal(true, stampedInstance:GetAttribute("IsOurTemplate"))
            expect.equal(true, stampedInstance:GetAttribute("WasDecorated"))
            
            reconciler.unmountVirtualTree(tree)
        end)
        it("Re-mounts elements dependent on instances created by prior siblings", function(expect)
            local template1 = Instance.new("Folder")
            template1:SetAttribute("IsTemplate1", true)
            local template2 = Instance.new("Folder")
            template2:SetAttribute("IsTemplate2", true)

            local tree = reconciler.mountVirtualTree(
                Pract.combine(
                    Pract.stamp(template1),
                    Pract.decorate({
                        [Pract.Attributes] = {
                            WasDecorated = true,
                        }
                    })
                )
            )
            
            local rootNode: any = tree._rootNode
            expect.truthy(rootNode)

            local siblingClusterCache = rootNode._hostContext.siblingClusterCache
            expect.truthy(siblingClusterCache)

            local stampedInstance1 = siblingClusterCache.lastProvidedInstance
            expect.truthy(stampedInstance1)

            expect.equal(true, stampedInstance1:GetAttribute("IsTemplate1"))
            expect.equal(nil, stampedInstance1:GetAttribute("IsTemplate2"))
            expect.equal(true, stampedInstance1:GetAttribute("WasDecorated"))

            reconciler.updateVirtualTree(
                tree,
                Pract.combine(
                    Pract.stamp(template2),
                    Pract.decorate({
                        [Pract.Attributes] = {
                            WasDecorated = true,
                        }
                    })
                )
            )
            
            local stampedInstance2 = siblingClusterCache.lastProvidedInstance
            expect.truthy(stampedInstance2)

            expect.equal(nil, stampedInstance2:GetAttribute("IsTemplate1"))
            expect.equal(true, stampedInstance2:GetAttribute("IsTemplate2"))
            expect.equal(true, stampedInstance2:GetAttribute("WasDecorated"))

            expect.equal(true, stampedInstance1:GetAttribute("IsTemplate1"))
            expect.equal(nil, stampedInstance1:GetAttribute("IsTemplate2"))
            expect.equal(nil, stampedInstance1:GetAttribute("WasDecorated"))
            
            reconciler.unmountVirtualTree(tree)
        end)
        it("Waits for child for decorate elements occurring earlier in cluster", function(expect)
            local template = Instance.new("Folder")
            template:SetAttribute("IsTemplate", true)
            local tree
            expect.errors(function()
                tree = reconciler.mountVirtualTree(
                    Pract.combine(
                        Pract.decorate({
                            [Pract.Attributes] = {
                                WasDecorated = true,
                            }
                        }),
                        Pract.stamp(template)
                    )
                )
            end)
            if tree then
                reconciler.unmountVirtualTree(tree)
            end

            local parentFolder = Instance.new("Folder")
            tree = reconciler.mountVirtualTree(
                Pract.combine(
                    Pract.decorate({
                        [Pract.Attributes] = {
                            WasDecorated = true,
                        }
                    }),
                    Pract.stamp(template)
                ),
                parentFolder,
                "ChildName"
            )
            local rootNode: any = tree._rootNode
            expect.truthy(rootNode)

            local mountedDecorateNode = rootNode._siblings[1]
            expect.truthy(mountedDecorateNode)

            local instance = parentFolder:FindFirstChild("ChildName")
            expect.truthy(instance)
            
            expect.equal(true, instance:GetAttribute("IsTemplate"))
            expect.equal(true, instance:GetAttribute("WasDecorated"))
        end)
    end)
end

return spec