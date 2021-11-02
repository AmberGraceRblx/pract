--!strict
-- Unit tester for Pract, with a standalone unit tester; ostensibly could support other unit test
-- libraries for tooling, such as Test-EZ, but the BuiltInTester suffices for testing the Pract
-- library on its own. Pract's current CI uses run-in-roblox to run unit tests in Luau from
-- Roblox Studio itself.

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