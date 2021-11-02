--!strict
-- Unit tester for Pract, designed as a Roblox ModuleScript instance, to be run within Roblox Studio
-- Though this is not conducive to external tooling (as of yet), Pract is and will always be written
-- in Luau, and using Luau's type syntax.

local Types = require(script.Types)
local TestPract = {}

TestPract.BuiltInTester = require(script.BuiltInTester)

function TestPract.Test(
    practLibraryLocation: ModuleScript,
    _tester: Types.UnitTester?,
    _output: Types.UnitTestOutput?
): boolean
	local output: Types.UnitTestOutput = _output or {
        print = print :: any,
        warn = warn :: any,
        error = error :: any,
    }
    
    local copyTestPract = script:Clone()
    local tester: Types.UnitTester
    if _tester then
        tester = _tester
    else
        tester = require(copyTestPract.BuiltInTester)
    end

    local modules = copyTestPract.specs:GetChildren()
	
    local result = tester(modules, practLibraryLocation, output)

    copyTestPract:Destroy()
    return result
end

return TestPract