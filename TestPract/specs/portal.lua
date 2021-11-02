--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local portal: any = require(practModule.portal)
    local Symbols: any = require(practModule.Symbols)

    describe('portal', function(it)
        local HOST_INSTANCE = workspace
        it('Should create an element with empty props', function(expect)
            local element = portal(HOST_INSTANCE)
            expect.equal(Symbols.ElementKinds.Portal, element[Symbols.ElementKind])
            expect.equal(HOST_INSTANCE, element.hostParent)
            expect.equal(nil, element.children)
        end)
        it('Should accept children', function(expect)
            local element = portal(HOST_INSTANCE, {})
            expect.equal(Symbols.ElementKinds.Portal, element[Symbols.ElementKind])
            expect.equal(HOST_INSTANCE, element.hostParent)
            expect.deep_equal({}, element.children)
        end)
    end)
end

return spec