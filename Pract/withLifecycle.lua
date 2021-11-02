--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_LifecycleComponent = Symbols.ElementKinds.LifecycleComponent
local function withLifecycle(
	makeClosureCallback: (forceUpdate: () -> ()) -> Types.Lifecycle
): Types.Component
	local finalComponent = function(props: Types.PropsArgument)
		local element = {
			[Symbol_ElementKind] = Symbol_LifecycleComponent,
			makeLifecycleClosure = makeClosureCallback,	-- This should be able to be changed without
														-- causing a remount, since we want to be
														-- able to chain scoped higher-order
														-- component wrappers.
			props = props,
		}
		table.freeze(element)
		return element
	end
	
	return finalComponent
end

return withLifecycle