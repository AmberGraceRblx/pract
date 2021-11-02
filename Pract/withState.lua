--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_StateComponent = Symbols.ElementKinds.StateComponent
local function withState(
	makeClosureCallback: (
		getState: () -> any,
		setState: (any) -> (),
		subscribeState: (() -> ()) -> (() -> ())
	) -> Types.Component
): Types.Component
	local finalComponent = function(props: Types.PropsArgument)
		local element = {
			[Symbol_ElementKind] = Symbol_StateComponent,
			makeStateClosure = makeClosureCallback,	-- This should be able to be changed without
												-- causing a remount, since we want to be
												-- able to chain scoped higher-order
												-- component wrappers.
			props = props,
			deferred = false,
		}
		table.freeze(element)
		return element
	end
	
	return finalComponent
end

return withState