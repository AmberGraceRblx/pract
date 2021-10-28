--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_LifecycleComponent = Symbols.ElementKinds.LifecycleComponent
local function withLifecycle(
	lifecycleClosureCB: (forceUpdate: () -> ()) -> Types.Lifecycle
): Types.Component
	local finalComponent = function(props: Types.PropsArgument)
		return {
			[Symbol_ElementKind] = Symbol_LifecycleComponent,
			makeLifecycleClosure = lifecycleClosureCB,	-- This should be able to be changed without
														-- causing a remount, since we want to be
														-- able to chain scoped higher-order
														-- component wrappers.
			props = props,
		}
	end
	
	return finalComponent
end

return withLifecycle