--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_Index = Symbols.ElementKinds.Index
local function index(children: Types.ChildrenArgument?): Types.Element
	return {
		[Symbol_ElementKind] = Symbol_Index,
		children = children,
	}
end

return index