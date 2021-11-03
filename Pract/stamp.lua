--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_Children = Symbols.Children
local Symbol_Stamp = Symbols.ElementKinds.Stamp
local function stamp(
	template: Instance,
	props: Types.PropsArgument?,
	children: Types.ChildrenArgument?
): Types.Element
	local props: Types.PropsArgument = props or {}
	
	if children ~= nil then
		(props :: any)[Symbol_Children] = children
	end
	if not table.isfrozen(props :: Types.PropsArgument) then
		table.freeze(props :: Types.PropsArgument)
	end
	
	local element = {
		[Symbol_ElementKind] = Symbol_Stamp,
		template = template,
		props = props,
	}
	table.freeze(element)
	return element
end

return stamp