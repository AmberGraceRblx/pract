--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local decorate = (require :: any)(practModule.decorate)
    local Symbols = (require :: any)(practModule.Symbols)

    describe('decorate', function(it)
        it('Should create a Decorate element with empty props', function(expect)
            local element = decorate()
            expect.equal(Symbols.ElementKinds.Decorate, element[Symbols.ElementKind])
            expect.deep_equal({}, element.props)
        end)
        it('Should accept props', function(expect)
            local element = decorate({foo = 'Fighters'})
            expect.equal(Symbols.ElementKinds.Decorate, element[Symbols.ElementKind])
            expect.deep_equal({foo='Fighters'}, element.props)
        end)
        it('Should accept props and children', function(expect)
            local element = decorate({foo = 'Fighters'}, {})
            expect.equal(Symbols.ElementKinds.Decorate, element[Symbols.ElementKind])
            expect.deep_equal({foo='Fighters', [Symbols.Children] = {}}, element.props)
        end)
        it('Should accept children without props', function(expect)
            local element = decorate(nil, {})
            expect.equal(Symbols.ElementKinds.Decorate, element[Symbols.ElementKind])
            expect.deep_equal({[Symbols.Children] = {}}, element.props)
        end)
        it('Should accept read-only props with no children argument', function(expect)
            local props = {}
            table.freeze(props)
            local element = decorate(props)
            expect.equal(Symbols.ElementKinds.Decorate, element[Symbols.ElementKind])
            expect.equal(props, element.props)
        end)
    end)
end

return spec