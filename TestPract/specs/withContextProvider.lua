--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local withContextProvider = (require :: any)(practModule.withContextProvider)
    local Symbols = (require :: any)(practModule.Symbols)

    describe('withContextProvider', function(it)
        it('should wrap a component', function(expect)
            local wrappedClosureCreator = function() end
            local finalComponent = withContextProvider(wrappedClosureCreator)
            
            expect.truthy(finalComponent)
        end)
        it('should return a component that returns a unique element', function(expect)
            local wrappedClosureCreator = function() end
            local finalComponent = withContextProvider(wrappedClosureCreator)
            local props = {}
            local element = finalComponent(props)
            
            expect.equal(Symbols.ElementKinds.ContextProvider, element[Symbols.ElementKind])
            expect.equal(props, element.props)
            expect.equal(wrappedClosureCreator, element.makeClosure)
        end)
    end)
end

return spec