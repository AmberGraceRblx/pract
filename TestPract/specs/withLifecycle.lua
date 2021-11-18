--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local withLifecycle = (require :: any)(practModule.withLifecycle)
    local Symbols = (require :: any)(practModule.Symbols)

    describe('withLifecycle', function(it)
        it('should wrap a component', function(expect)
            local wrappedClosureCreator = function() end
            local finalComponent = withLifecycle(wrappedClosureCreator)
            
            expect.truthy(finalComponent)
        end)
        it('should return a component that returns a unique element', function(expect)
            local wrappedClosureCreator = function() end
            local finalComponent = withLifecycle(wrappedClosureCreator)
            local props = {}
            local element = finalComponent(props)
            
            expect.equal(Symbols.ElementKinds.LifecycleComponent, element[Symbols.ElementKind])
            expect.equal(props, element.props)
            expect.equal(wrappedClosureCreator, element.makeLifecycleClosure)
        end)
    end)
end

return spec