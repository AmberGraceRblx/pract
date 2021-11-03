--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local Symbol_ElementKind = Symbols.ElementKind
local Symbol_Children = Symbols.Children
local Symbol_CreateInstance = Symbols.ElementKinds.CreateInstance
local Symbol_RenderComponent = Symbols.ElementKinds.RenderComponent

local handleByType = {} :: {
	[string]: (classSpecifier: any, props: Types.PropsArgument) -> Types.Element
}

handleByType['string'] = function(className: string, props)
	return {
		[Symbol_ElementKind] = Symbol_CreateInstance,
		className = className,
		props = props,
	}
end

handleByType['function'] = function(component: Types.Component, props)
	return {
		[Symbol_ElementKind] = Symbol_RenderComponent,
		component = component,
		props = props,
	}
end

setmetatable(handleByType, {__index = function(_, argumentType: string)
	error(
		("invalid argument #1 to Pract.create (string or Pract.Component expected, got %s)")
			:format(argumentType)
	)
end})

local function create(
	classNameOrComponent: string | Types.Component,
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
	
	local element = handleByType[typeof(classNameOrComponent)](
		classNameOrComponent,
		props :: Types.PropsArgument
	)
	table.freeze(element)
	return element
end

return create