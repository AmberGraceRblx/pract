--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_SignalComponent = Symbols.ElementKinds.SignalComponent
local function withSignal(
	signal: RBXScriptSignal,
	wrappedComponent: Types.Component
): Types.Component
	local finalComponent = function(props: Types.PropsArgument)
		local element = {
			[Symbol_ElementKind] = Symbol_SignalComponent,
			signal = signal,
			render = wrappedComponent,
			props = props,
		}
		table.freeze(element)
		return element
	end
	
	return finalComponent
end

return withSignal