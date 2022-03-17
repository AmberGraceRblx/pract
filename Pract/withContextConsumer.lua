--!strict
--[[
	Deprecated
]]

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_ContextConsumer = Symbols.ElementKinds.ContextConsumer
--[[
	Deprecated
]]
local function withContextConsumer(
	makeClosureCallback: (
		consume: (key: any) -> any
	) -> Types.Component
): Types.Component
	local finalComponent = function(props: Types.PropsArgument): Types.Element
		local element = {
			[Symbol_ElementKind] = Symbol_ContextConsumer,
			makeClosure = makeClosureCallback,
			props = props
		}
		table.freeze(element)
		return element
	end
	
	return finalComponent
end

return withContextConsumer