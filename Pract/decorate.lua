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
	
	if children ~= nil then
		(props :: any)[Symbol_Children] = children
	end

	if not table.isfrozen(props :: Types.PropsArgument) then
		table.freeze(props :: Types.PropsArgument)
	end
	
	local element = {
		[Symbol_ElementKind] = Symbol_Decorate,
		props = props,
	}
	table.freeze(element)
	return element
end

return decorate