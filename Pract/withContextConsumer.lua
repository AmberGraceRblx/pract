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
		local element = {
			[Symbol_ElementKind] = Symbol_ContextConsumer,
			makeClosure = consumerComponentClosureCB,
			props = props
		}
		table.freeze(element)
		return element
	end
	
	return finalComponent
end

return withContextConsumer