--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local combine: any = require(practModule.combine)
    local index: any = require(practModule.index)
    local Symbols: any = require(practModule.Symbols)

    describe('combine', function(it)
        it('Should accept no children', function(expect)
            local element = combine()
            expect.equal(Symbols.ElementKinds.SiblingCluster, element[Symbols.ElementKind])
            expect.deep_equal({}, element.elements)
        end)
        it('Should accept children', function(expect)
            local sub_elements = {index{}, index{foo = index{}}}
            local element = combine(unpack(sub_elements))
            expect.equal(Symbols.ElementKinds.SiblingCluster, element[Symbols.ElementKind])
            expect.deep_equal(sub_elements, element.elements)
        end)
    end)
end

return spec