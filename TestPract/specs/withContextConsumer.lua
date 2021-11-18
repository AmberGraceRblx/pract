--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local withContextConsumer = (require :: any)(practModule.withContextConsumer)
    local Symbols = (require :: any)(practModule.Symbols)

    describe('withContextConsumer', function(it)
        it('should wrap a component', function(expect)
            local wrappedClosureCreator = function() end
            local finalComponent = withContextConsumer(wrappedClosureCreator)
            
            expect.truthy(finalComponent)
        end)
        it('should return a component that returns a unique element', function(expect)
            local wrappedClosureCreator = function() end
            local finalComponent = withContextConsumer(wrappedClosureCreator)
            local props = {}
            local element = finalComponent(props)
            
            expect.equal(Symbols.ElementKinds.ContextConsumer, element[Symbols.ElementKind])
            expect.equal(props, element.props)
            expect.equal(wrappedClosureCreator, element.makeClosure)
        end)
    end)
end

return spec