--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_Children = Symbols.Children
local Symbol_Decorate = Symbols.ElementKinds.Decorate
local function decorate(
	props: Types.PropsArgument?,
	children: Types.ChildrenArgument?
): Types.Element
	if props == nil then
		props = {}
	end
	
	;(props :: any)[Symbol_Children] = children
	
	return {
		[Symbol_ElementKind] = Symbol_Decorate,
		props = props,
	}
end

return decorate