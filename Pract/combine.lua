--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_SiblingCluster = Symbols.ElementKinds.SiblingCluster
local function combine(...: Types.Element): Types.Element
	local element = {
		[Symbol_ElementKind] = Symbol_SiblingCluster,
		elements = {...},
	}
	table.freeze(element)
	return element
end

return combine