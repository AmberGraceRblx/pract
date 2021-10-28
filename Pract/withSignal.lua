--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_SignalComponent = Symbols.ElementKinds.SignalComponent
local function withSignal(
	signal: RBXScriptSignal,
	signalComponentClosureCB: () -> Types.Component
): Types.Component
	local finalComponent = function(props: Types.PropsArgument)
		return {
			[Symbol_ElementKind] = Symbol_SignalComponent,
			signal = signal,
			makeClosure = signalComponentClosureCB,
			props = props,
		}
	end
	
	return finalComponent
end

return withSignal