--!strict
--[[
    Creates a unique hook object that acts similarly to Pract.withLifecycle,
using a similar closure structure that can be called as a hook rather than
having to wrap a component.

    This is intended to replace/simplify any remaining withLifecycle use cases
after other built-in hooks are considered.
]]

local PractGlobalSystems = require(script.Parent.PractGlobalSystems)
local Types = require(script.Parent.Types)

local function createHook<T>(
	lifecycleClosureCB: (
		queueUpdate: () -> ()
	) -> Types.CustomHookLifecycle<T>
): T
    -- Using "any" type annotations for now, since defaults type arguments are
    -- not supported in function generics for some reason.
	return function(...: any): ...any
        -- Luau doesn't like exporting this type for some reason, so we typecast
        -- it to itself
        return (
            (
                PractGlobalSystems._reconcilerHookCallbacks.customHook
                :: any
            ) :: Types.HookReconciler
        )(
            lifecycleClosureCB :: any,
            ...
        )
    end :: any
end

return createHook