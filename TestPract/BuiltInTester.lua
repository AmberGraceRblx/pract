--!strict
--[[
    This unit tester is designed to be standalone; the unit testing system is agnostic such that it
    could ostensibly be used with Test-EZ or DataBrain's TestSuite library.
]]

local Types = require(script.Parent.Types)

local BuiltInTester: Types.UnitTester = function(
    modules: {ModuleScript},
    practLibraryLocation: ModuleScript,
    output: Types.UnitTestOutput
): boolean
    local t1 = os.clock()
    local successCount, failureCount, errorCount = 0, 0, 0

    local ASSERT_PREFIX = "@@TEXT_PRACT_BUILTIN_ASSERT"

    local asserts: Types.UnitTestAsserts; do
        local function assertFailed(...: string)
            local output = table.concat({...}, ' ')
            error(ASSERT_PREFIX .. output, 3)
        end
        local function assertSuccess()
            successCount = successCount + 1
        end
        local function formatKey(k: any)
            if type(k) == "string" then
                return k
            else
                return '[' .. tostring(k) .. ']'
            end
        end
        local function formatValue(v: any)
            if type(v) == "string" then
                if v:find("'") then
                    if v:find('"') then
                        return '[[' .. v .. ']]'
                    else
                        return '"' .. v .. '"'
                    end
                else
                    return "'" .. v .. "'"
                end
            else
                return tostring(v)
            end
        end
        local MAX_DIFF_DEPTH = 4
        local function deepCompare(expected: any, actual: any)
            if expected == actual then
                return true
            elseif typeof(expected) == typeof(actual)
            and typeof(expected) == "table" then
                for k,v in pairs(expected) do
                    if not deepCompare(v, actual[k]) then return false end
                end
                for k,v in pairs(actual) do
                    if not deepCompare(v, expected[k]) then return false end
                end
                
                return true
            else
                return false
            end
        end
        local function deepDiff(expected: any, actual: any, _depth: number?): string
            local depth: number = _depth or 0
            local indentation = string.rep("  ", depth)
            if typeof(actual) == "table" then
                if typeof(expected) == "table" then
                    local diff = '(table) { *'
                    for k,v in pairs(actual) do
                        if not deepCompare(v, expected[k]) then
                            diff = diff
                                .. '\n' .. indentation .. formatKey(k) .. ' = '
                                .. deepDiff(expected[k], v)
                                .. ','
                        end
                    end
                    for k,v in pairs(expected) do
                        if actual[k] == nil then
                            diff = diff
                                .. '\n' .. indentation .. formatKey(k) .. ' = '
                                .. deepDiff(v, nil)
                                .. ','
                        end
                    end
                    diff = diff .. '\n' .. indentation .. '}'
                    return diff
                else
                    return '(table *) { . . . }'
                end
            else
                if typeof(actual) == typeof(expected) then
                    return '(' .. typeof(actual) .. ') ' .. formatValue(actual) .. " *"
                else
                    return '(' .. typeof(actual) .. ' *) ' .. formatValue(actual)
                end
            end
        end
        local function deepInspect(obj: any, _depth: number?): string
            local depth: number = _depth or 0
            local indentation = string.rep("  ", depth)
            if type(obj) == "table" then
                local inspected = '{'
                for k,v in pairs(obj) do
                    inspected = inspected
                        .. '\n'.. indentation .. formatKey(k)
                        .. ' = ' .. deepInspect(v, depth + 1) .. ','
                end
                inspected = inspected
                    .. '\n' .. indentation .. '}'
                
                return inspected
            else
                return formatValue(obj)
            end
        end

        asserts = {
            equal = function(expected, actual)
                if expected ~= actual then
                    assertFailed(
                        'Expected objects to be equal.\n'
                        .. "Passed in:"
                        .. '\n' .. '(' .. typeof(actual) .. ') ' .. formatValue(actual)
                        .. '\n' .. "Expected:"
                        .. '\n' .. '(' .. typeof(expected) .. ') ' .. formatValue(expected)
                    )
                end
                assertSuccess()
            end,
            not_equal = function(expected, actual)
                if expected == actual then
                    assertFailed(
                        'Expected objects to NOT be equal.\n'
                        .. "Passed In / Expected:"
                        .. '\n' .. '(' .. typeof(expected) .. ') ' .. formatValue(expected)
                    )
                end
                assertSuccess()
            end,
            deep_equal = function(expected, actual)
                if not deepCompare(expected, actual) then
                    assertFailed(
                        "Expected objects to be deep equal.\n"
                        .. "Passed in:"
                        .. '\n' .. deepDiff(expected, actual)
                        .. '\n' .. "Expected:"
                        .. '\n' .. '(' .. typeof(expected) .. ') ' .. deepInspect(expected)
                    )
                end
                assertSuccess()
            end,
            not_deep_equal = function(expected, actual)
                if deepCompare(expected, actual) then
                    assertFailed(
                        "Expected objects to NOT be deep equal.\n"
                        .. "Passed In / Expected:"
                        .. '\n' .. '(' .. typeof(expected) .. ') ' .. deepInspect(expected)
                    )
                end
                assertSuccess()
            end,
            truthy = function(actual)
                if actual then
                    assertSuccess()
                else
                    assertFailed(
                        "Expected object to be truthy.\n"
                        .. "Passed in:"
                        .. '\n' .. '(' .. typeof(actual) .. ') ' .. formatValue(actual)
                    )
                end
            end,
            falsy = function(actual)
                if actual then
                    assertFailed(
                        "Expected object to be falsy.\n"
                        .. "Passed in:"
                        .. '\n' .. '(' .. typeof(actual) .. ') ' .. formatValue(actual)
                    )
                else
                    assertSuccess()
                end
            end,
            errors = function(callback: () -> ())
                if pcall(callback) then
                    assertFailed('Expected callback to produce error')
                else
                    assertSuccess()
                end
            end,
        }
    end

    local clonedLibrary = practLibraryLocation:Clone()
    local function makeDescribe(moduleContext: string): Types.Describe
        local function describe(unitName: string, withIt)
            local function it(behavior: string, withAsserts)
                local behaviorLineStr = debug.info(2, 'l')
                local errWithTraceback: any
                local success = xpcall(
                    function()
                        withAsserts(asserts)
                    end, function(err)
                        errWithTraceback = tostring(err)
                    end
                )
                
                if success then
                    successCount = successCount + 1
                else
                    local lineNumber: string, err: string = errWithTraceback:sub(
                        moduleContext:len() + 2
                    ):match("([0-9]+): (.*)")
                    
                    lineNumber = lineNumber or "?"
                    err = err or errWithTraceback
                    
                    local isAssertFailure = false
                    if err:sub(1, ASSERT_PREFIX:len()) == ASSERT_PREFIX then
                        isAssertFailure = true
                        err = err:sub(ASSERT_PREFIX:len() + 1)
                    end
                    
                    if isAssertFailure then
                        output.warn("Failure -> " .. moduleContext .. " @ " .. behaviorLineStr)
                        failureCount = failureCount + 1
                    else
                        output.warn("Error -> " .. moduleContext .. " @ " .. behaviorLineStr)
                        errorCount = errorCount + 1
                    end
                    output.warn(unitName .. " " .. behavior)
                    output.print(moduleContext .. ":" .. lineNumber .. ": " .. err)
                        --traceback:match("[^\n]*") .. ": ".. err)
                end
            end
            withIt(it)
        end
        return describe
    end

    for i = 1, #modules do
        local module = modules[i]
        local spec
        local success, err: any = pcall(function()
            spec = (require :: any)(module)
            spec(practLibraryLocation, makeDescribe(module:GetFullName()))
        end)
        if not success then
            output.print(
                'Error when processing spec module '
                .. module:GetFullName() .. ": "
                .. err
            )
            errorCount = errorCount + 1
        end
    end

    clonedLibrary:Destroy()

    local t2 = os.clock()

    output.print(string.format(
        '%d successes / %d failures / %d errors; completed in %f seconds',
        successCount,
        failureCount,
        errorCount,
        t2 - t1
    ))

    if (failureCount > 0) or (errorCount > 0) then
        return false
    else
        return true
    end
end

return BuiltInTester