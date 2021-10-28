--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_ContextConsumer = Symbols.ElementKinds.ContextConsumer
local function withContextConsumer(
	consumerComponentClosureCB: (
		consume: (string) -> any
	) -> Types.Component
): Types.Component
	local finalComponent = function(props: Types.PropsArgument): Types.Element
		return {
			[Symbol_ElementKind] = Symbol_ContextConsumer,
			makeClosure = consumerComponentClosureCB,
			props = props
		}
	end
	
	return finalComponent
end

return withContextConsumer