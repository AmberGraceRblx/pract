--!strict
--[[
	Deprecated
]]

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_ContextProvider = Symbols.ElementKinds.ContextProvider
--[[
	Deprecated
]]
local function withContextProvider(
	makeClosureCallback: (
		provide: (key: any, object: any) -> (() -> ())
	) -> Types.Component
): Types.Component
	local finalComponent = function(props: Types.PropsArgument): Types.Element
		local element = {
			[Symbol_ElementKind] = Symbol_ContextProvider,
			makeClosure = makeClosureCallback,
			props = props
		}
		table.freeze(element)
		return element
	end
	
	return finalComponent
end

return withContextProvider