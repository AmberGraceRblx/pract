--!strict

-- A symbol is a userdata object that is used internally as unique object reference for indexing
-- a table.

local Types = require(script.Parent.Types)

local function createSymbol(name: string, proxy: any?): Types.Symbol
	local symbol, mt
	if proxy then
		mt = {}
		symbol = setmetatable(proxy, mt)
	else
		symbol = newproxy(true)
		mt = getmetatable(symbol :: any)
	end
	
	local wrappedName = '@@' .. name
	mt.__tostring = function() return wrappedName end
	
	return symbol
end

return createSymbol