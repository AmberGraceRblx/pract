--!strict
--[[
    Creates a unique context object that can be provided and consumed
(used primarily to match React's hooks and deprecate withContextProvider/
withContextConsumer HOFs)

    Wraps the legacy provider/consumer system in order to preserve
compatibility between deprecated HOFs and the new hooks-based system.
]]

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)
local createSymbol = require(script.Parent.createSymbol)

type Props = {
    value: any,
    child: Types.Element,
}

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_ContextProvider = Symbols.ElementKinds.ContextProvider
local Symbol_Children = Symbols.Children
local function createContext(debugName: string?)
    local symbol = createSymbol(debugName or "Context")

    local function makeClosure(
		provide: (key: any, object: any) -> (() -> ())
    ): Types.ComponentTyped<Props>
        local lastValue = nil

        provide(symbol, {
            getValue = function()
                return lastValue
            end
        })

        return function(props)
            lastValue = props.value
            return props.child
        end
    end

    local context: any = {
        Provider = function(props: Props)
            local element = {
                [Symbol_ElementKind] = Symbol_ContextProvider,
                makeClosure = makeClosure,
                props = props
            }
            table.freeze(element)
            return element
        end,
        _symbol = symbol,
    }
    return context :: Types.PublicContextObject
end

return createContext