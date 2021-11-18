--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local index = (require :: any)(practModule.index)
    local Symbols = (require :: any)(practModule.Symbols)

    describe('index', function(it)
        it('Should accept no children', function(expect)
            local element = index()
            expect.equal(Symbols.ElementKinds.Index, element[Symbols.ElementKind])
            expect.equal(nil, element.children)
        end)
        it('Should accept children', function(expect)
            local element = index({})
            expect.equal(Symbols.ElementKinds.Index, element[Symbols.ElementKind])
            expect.deep_equal({}, element.children)
        end)
    end)
end

return spec