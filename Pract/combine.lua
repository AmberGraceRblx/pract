--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_SiblingCluster = Symbols.ElementKinds.SiblingCluster
local function combine(...: Types.Element): Types.Element
	return {
		[Symbol_ElementKind] = Symbol_SiblingCluster,
		elements = {...},
	}
end

return combine