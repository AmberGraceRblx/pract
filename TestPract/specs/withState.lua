--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local withState: any = require(practModule.withState)
    local Symbols: any = require(practModule.Symbols)

    describe('withState', function(it)
        it('should wrap a component', function(expect)
            local wrappedClosureCreator = function() end
            local finalComponent = withState(wrappedClosureCreator)
            
            expect.truthy(finalComponent)
        end)
        it('should return a component that returns a unique element', function(expect)
            local wrappedClosureCreator = function() end
            local finalComponent = withState(wrappedClosureCreator)
            local props = {}
            local element = finalComponent(props)
            
            expect.equal(Symbols.ElementKinds.StateComponent, element[Symbols.ElementKind])
            expect.equal(props, element.props)
            expect.equal(wrappedClosureCreator, element.makeStateClosure)
            expect.equal(false, element.deferred)
        end)
    end)
end

return spec