--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_Portal = Symbols.ElementKinds.Portal
local function portal(hostParent: Instance, children: Types.ChildrenArgument?): Types.Element
	return {
		[Symbol_ElementKind] = Symbol_Portal,
		hostParent = hostParent,
		children = children,
	}
end

return portal