--!strict
local PractTest = require(game.ReplicatedStorage.TestPract)

local passed = PractTest.Test(
    game.ReplicatedStorage.Pract,
    PractTest.BuiltInTester,
    nil
)

if not passed then
    error('Tests have failed!', 0)
end