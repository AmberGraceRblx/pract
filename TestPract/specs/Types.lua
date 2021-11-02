--!strict

local Types = require(script.Parent.Parent.Types)

local spec: Types.Spec = function(practModule, describe)
    local Pract_Types: any = require(practModule.Types)

    describe('Types', function(it)
        it('Should be nil at runtime', function(expect)
            expect.equal(nil, Pract_Types)
        end)
        it('CI should fail with a failing unit test', function(expect)
            expect.equal('This should fail!', Pract_Types)
        end)
    end)
end

return spec