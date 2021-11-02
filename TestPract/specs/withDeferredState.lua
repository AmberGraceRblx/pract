--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local withDeferredState: any = require(practModule.withDeferredState)
    local Symbols: any = require(practModule.Symbols)

    describe('withDeferredState', function(it)
        it('should wrap a component', function(expect)
            local wrappedClosureCreator = function() end
            local finalComponent = withDeferredState(wrappedClosureCreator)
            
            expect.truthy(finalComponent)
        end)
        it('should return a component that returns a unique element', function(expect)
            local wrappedClosureCreator = function() end
            local finalComponent = withDeferredState(wrappedClosureCreator)
            local props = {}
            local element = finalComponent(props)
            
            expect.equal(Symbols.ElementKinds.StateComponent, element[Symbols.ElementKind])
            expect.equal(props, element.props)
            expect.equal(wrappedClosureCreator, element.makeStateClosure)
            expect.equal(true, element.deferred)
        end)
    end)
end

return spec